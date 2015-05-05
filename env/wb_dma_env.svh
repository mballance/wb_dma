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
	
	wb_dma_handshake_driver								handshake_drivers[];
	
	wb_dma_memory_mgr									mem_mgr;
	wb_dma_timer										m_timer;
	
	wb_dma_sw											m_sw;
	
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
		
		m_timer = new("timer", this);

		m0_agent = wb_master_agent::type_id::create("m0_agent", this);
		
		m1_agent = wb_master_agent::type_id::create("m1_agent", this);
	
		s0_agent = wb_slave_agent::type_id::create("s0_agent", this);
		
		s1_agent = wb_slave_agent::type_id::create("s1_agent", this);
		
		handshake_drivers = new[m_num_channels];
		
		for (int i=0; i<m_num_channels; i++) begin
			$sformat(inst_name, "handshake_driver_%0d", i);
			handshake_drivers[i] = new(inst_name, this);
		end 
		
		mem_mgr = new("mem_mgr", this);
		
		m_sw = new("sw", this);
		
		m_irq_monitor = new("irq_monitor", this);
		
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

			m_sw.dma_desc_analysis_port.connect(		
				handshake_drivers[i].descriptor_analysis_export);
			handshake_drivers[i].handshake_analysis_port.connect(
				m_scoreboard.handshake_ev_analysis_export.exp);
		end
		
		mem_mgr.init(m0_agent.m_seqr, m1_agent.m_seqr);
		
		m_sw.init(mem_mgr, m_timer);
		
		m_irq_monitor.irq_analysis_port.connect(
			m_sw.irq_analysis_export.exp);
			
		// Connect the scoreboard to memory traffic
		mem_mgr.mem_analysis_port.connect(m_scoreboard.mem_analysis_export.exp);
		
		m_sw.dma_desc_analysis_port.connect(
			m_scoreboard.descriptor_analysis_export.exp);
		
		m_sw.desc_complete_analysis_port.connect(
			m_scoreboard.descriptor_complete_analysis_export.exp);
			
		m_scoreboard.init(mem_mgr);
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



