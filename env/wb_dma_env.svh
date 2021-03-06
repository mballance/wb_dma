/****************************************************************************
 * wb_dma_env.svh
 *
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 *
 * Base DMA Testbench Environment.
 ****************************************************************************/

class wb_dma_env extends uvm_env;
	
	`uvm_component_utils(wb_dma_env)
	
	wb_master_agent										m0_agent;
	wb_master_agent										m1_agent;

	wb_slave_agent										s0_agent;
	wb_slave_agent										s1_agent;
	
	dma_reg_block										m_dma_regs;
	
	dma_reg_agent										m_reg_agent;
	dma_reg2rw_adapter									m_reg_adapter;
	
	wb_dma_handshake_driver								handshake_drivers[];
	dma_channel_agent									channel_agents[];
	
	memory_mgr											mem_mgr;
	timer												m_timer;
	
	wb_dma_irq_monitor									m_irq_monitor;
	
	wb_dma_scoreboard									m_scoreboard;
	
	int													m_num_channels;


	function new(string name, uvm_component parent=null);
		super.new(name, parent);
		
		set_report_max_quit_count(4);
	endfunction 
	
	function void build_phase(uvm_phase phase);
		string 	inst_name;
		int		tmp_i;
		
		// Get the 'num_channels' config entry, which was set by the
		// top-level testbench module
		assert(get_config_int("num_channels", m_num_channels));
		
		mem_mgr = new("mem_mgr", this);
		// Make the memory manager available to all
		uvm_config_db #(memory_mgr)::set(this, "*", "memory_mgr", mem_mgr);
		
		m_timer = timer::type_id::create("m_timer", this);
		uvm_config_db #(timer)::set(this, "*", "timer", m_timer);

		m0_agent = wb_master_agent::type_id::create("m0_agent", this);
		
		m1_agent = wb_master_agent::type_id::create("m1_agent", this);
	
		s0_agent = wb_slave_agent::type_id::create("s0_agent", this);
		
		s1_agent = wb_slave_agent::type_id::create("s1_agent", this);
		
		m_dma_regs = dma_reg_block::type_id::create("m_dma_regs");
		m_dma_regs.build('hb000_0000);  // register base
		uvm_config_db #(dma_reg_block)::set(this, "*", "dma_regs", m_dma_regs);
		
		m_reg_agent = dma_reg_agent::type_id::create("m_reg_agent", this);
		m_reg_adapter = dma_reg2rw_adapter::type_id::create("m_reg_adapter");
		
		handshake_drivers = new[m_num_channels];
		
		for (int i=0; i<m_num_channels; i++) begin
			$sformat(inst_name, "handshake_driver_%0d", i);
			handshake_drivers[i] = new(inst_name, this);
		end
		
		channel_agents = new [m_num_channels];
		
		for (int i=0; i<m_num_channels; i++) begin
			$sformat(inst_name, "channel_agent_%0d", i);
			set_config_int({inst_name, ".*"}, "channel_id", i);
			channel_agents[i] = dma_channel_agent::type_id::create(inst_name, this);
		end
		
		m_irq_monitor = wb_dma_irq_monitor::type_id::create("m_irq_monitor", this);
		
		m_scoreboard = new("scoreboard", this);
		
	endfunction
	
	function void connect_phase(uvm_phase phase);
		string verbosity_file, line, path, verbosity_s, tmp_s;
		uvm_verbosity verbosity;
		uvm_component comp;
		int fd;
		
		uvm_report_info(get_name(), $psprintf("full name of scoreboard is: %0s", m_scoreboard.get_full_name()));
		
		// If the log verbosity file is specified, read in and configure
		// regions. This allows us to change the logging verbosity for
		// a testbench region without recompiling anything
		if ($value$plusargs("LOG_VERBOSITY_FILE=%s", verbosity_file)) begin
			fd = $fopen(verbosity_file, "r");
			
			while ($fgets(line, fd) > 0) begin
				for (int i=0; i<line.len(); i++) begin
					if (line[i] == "#") begin
						if (i > 0) begin
							line = line.substr(0, i-1);
						end else begin
							line = "";
						end 
					end
				end
				
				 
				if ($sscanf(line, "%s%s", path, verbosity_s) > 0) begin
					verbosity = UVM_MEDIUM;
					
					verbosity = verbosity.first();
					
					for (int i=1; i<verbosity.num(); i++) begin
						if (verbosity_s == verbosity.name()) begin
							break;
						end
						verbosity = verbosity.next();
					end
					
					uvm_report_info(get_name(), $psprintf("path=%0s verbosity=%0s", path, verbosity.name()));
					
					if (path == "GLOBAL") begin
						uvm_top.set_report_verbosity_level_hier(verbosity);
					end else begin
						if ((comp = uvm_top.find(path)) == null) begin
							uvm_report_error(get_name(), $psprintf("Failed to find component %0s", path));
						end else begin
							comp.set_report_verbosity_level(verbosity);
						end
					end 
				end 
			end 
			
			$fclose(fd);
		end 
		
		// Connect the drivers for the various descriptor channels
		for (int i=0; i<m_num_channels; i++) begin
			handshake_drivers[i].init(i);

			handshake_drivers[i].handshake_analysis_port.connect(
				m_scoreboard.handshake_ev_analysis_export.exp);
		end
		
		mem_mgr.init(m0_agent.m_seqr, m1_agent.m_seqr);
		
		// Connect the scoreboard to memory traffic
		mem_mgr.mem_analysis_port.connect(m_scoreboard.mem_analysis_export.exp);
		
		m_scoreboard.init(mem_mgr);
		
		foreach (channel_agents[i]) begin
			channel_agents[i].m_driver.dma_desc_analysis_port.connect(
				m_scoreboard.descriptor_analysis_export.exp);
			m_scoreboard.descriptor_complete_ap.connect(
					channel_agents[i].m_driver.dma_transfer_complete_exp);
		end
					
		
		// Connect the register model
		m_reg_agent.m_wb_seqr = m0_agent.m_seqr;
		m_dma_regs.default_map.set_sequencer(m_reg_agent.m_seqr, m_reg_adapter);
		m_dma_regs.default_map.set_auto_predict(1);
		m_dma_regs.reset();
		
	endfunction
	
	task run();
		string inst_name;
		wb_dma_channel_seq	channel_seq;
		wb_dma_slave_seq  	s_s0, s_s1;
		
		// Run sequences on the slave sequences to channel 
		// memory accesses back to the memory manager
		s_s0 = wb_dma_slave_seq::type_id::create("s_s0");
		s_s0.init(0, mem_mgr);
		
		s_s1 = wb_dma_slave_seq::type_id::create("s_s1");
		s_s1.init(1, mem_mgr);
		
		fork
			s_s0.start(s0_agent.m_seqr);
			s_s1.start(s1_agent.m_seqr);
		join_none
		#0;
	endtask
	
endclass 



