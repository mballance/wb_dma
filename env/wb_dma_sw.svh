/****************************************************************************
 * wb_dma_sw.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * Block emulates the task a CPU would perform in managing interrupts and
 * descriptors 
 ****************************************************************************/

`wb_dma_analysis_closure_imp_t(dma_descriptor_analysis_export_t,
	wb_dma_descriptor, wb_dma_sw, descriptor_start)
`wb_dma_analysis_closure_imp_t(irq_analysis_export_t,
	wb_dma_irq_ev, wb_dma_sw, irq_event)

typedef class wb_dma_env;
	
class wb_dma_sw extends uvm_component;

	dma_descriptor_analysis_export_t				dma_descriptor_analysis_export;
	irq_analysis_export_t							irq_analysis_export;
			
	uvm_analysis_port #(wb_dma_desc_complete_ev)	desc_complete_analysis_port;
	uvm_analysis_export #(wb_dma_descriptor)		dma_desc_analysis_port;

	// local fields
	uvm_sequencer #(wb_dma_descriptor)				descriptor_sequencers[];
	wb_dma_descriptor_driver						descriptor_drivers[];
	
	wb_dma_memory_mgr								m_mem_mgr;
	wb_dma_timer									m_timer;
	int												m_num_channels;
	wb_dma_channel_seq								m_channel_seq[];
	
	wb_dma_irq_ev									m_irq_state;
	wb_dma_irq_ev									m_irq_state_r;
	event											m_irq_event;
	bit												m_irq_active;
	
	wb_dma_descriptor								m_active_descriptors[$];
	wb_dma_desc_complete_ev							m_complete_ev;
	
	
	function new(string name, uvm_component parent);
		super.new(name, parent);
		
		desc_complete_analysis_port = new("desc_complete_analysis_port", this);
		dma_desc_analysis_port = new("dma_desc_analysis_port", this);
		dma_descriptor_analysis_export =
			new("dma_descriptor_analysis_export", this);
		irq_analysis_export = new("irq_analysis_export", this);
		m_irq_state = new("irq_state");
		m_irq_state_r = new("irq_state_r");
		
		m_complete_ev = wb_dma_desc_complete_ev::type_id::create("ev");
	endfunction
	
	function void build();
		string 	inst_name;
		
		assert(get_config_int("num_channels", m_num_channels));
		
		descriptor_sequencers = new[m_num_channels];
		descriptor_drivers = new[m_num_channels];
		
		for (int i=0; i<m_num_channels; i++) begin
			$sformat(inst_name, "descriptor_sequencer_%0d", i);
			descriptor_sequencers[i] = new(inst_name, this);
			
			$sformat(inst_name, "descriptor_driver_%0d", i);
			descriptor_drivers[i] = new(inst_name, this);
		end 
	endfunction
	
	function void connect();
		// Connect the drivers for the various descriptor channels
		for (int i=0; i<m_num_channels; i++) begin
			descriptor_drivers[i].dma_desc_analysis_port.connect(dma_desc_analysis_port);
				
			descriptor_drivers[i].seq_item_port.connect(
				descriptor_sequencers[i].seq_item_export);
				
			descriptor_drivers[i].dma_desc_analysis_port.connect(
				dma_descriptor_analysis_export.exp);
				
			desc_complete_analysis_port.connect(
				descriptor_drivers[i].descriptor_complete_analysis_export.exp);
		end
	endfunction 
	
	function void init(wb_dma_memory_mgr mem_mgr, wb_dma_timer timer);
		m_mem_mgr = mem_mgr;
		m_timer   = timer;
		
		for (int i=0; i<m_num_channels; i++) begin
			descriptor_drivers[i].init(i, m_mem_mgr, m_timer);
		end
	endfunction 
	
	/**
	 * descriptor_start()
	 * 
	 * Called when a descriptor starts
	 */
	function void descriptor_start(wb_dma_descriptor descriptor);
		wb_dma_descriptor descriptor_c = wb_dma_descriptor'(descriptor.clone());
		
		m_active_descriptors.push_back(descriptor_c);
	endfunction 
	
	/**
	 * irq_event()
	 * 
	 * Called when an IRQ event occurs
	 */
	 function void irq_event(wb_dma_irq_ev irq);
	 	m_irq_state.copy(irq);
	 	-> m_irq_event;
	 endfunction 
	
	
	/****************************************************************
	 * run()
	 * 
	 * Main run loop.
	 * - Setup interrupts
	 * - Launch descriptor sequences
	 * - Wait for interrupts to signal that descriptors are complete
	 ****************************************************************/
	task run();
		CH_CSR_t      		ch_csr;
		bit [31:0]    		tmp;
		wb_dma_descriptor	desc;
		int					i;	
		
		create_descriptor_sequences();
		
		// The first thing to do is enable all interrupts
		
		// Mask for INT_A
		tmp = 'hAAAA_AAAA;
		m_mem_mgr.access(`REG_BASE + 4, 1, tmp);
		
		// Mask for INT_B 
		tmp = 'h5555_5555;
		m_mem_mgr.access(`REG_BASE + 8, 1, tmp);
		
		// Notify the descriptor sequences that they can 
		// begin executing
		for (int i=0; i<m_num_channels; i++) begin
			m_channel_seq[i].set_ok_to_run();
		end 
		
		forever begin
			process p_wait, p_wd;
			bit		timeout = 0;
			fork
				begin
					p_wait = process::self();
					@(m_irq_event);
				end
				begin
					p_wd = process::self();
					m_timer.wait_clks(1000000);
					timeout = 1;
				end 
			join_any
			
			// Clean up after the 
			if (timeout) begin
				uvm_report_error(m_name, $psprintf("Timeout waiting for one of %0d descriptors", 
					m_active_descriptors.size()));
				for (int i=0; i<m_active_descriptors.size(); i++) begin
					m_active_descriptors[i].print();
				end 
				p_wait.kill();
			end else begin
				p_wd.kill();
			end 
					
			m_irq_state_r.copy(m_irq_state);
			
			// debounce the interrupt lines
			m_timer.wait_clks(5);
			if (m_irq_state.inta == m_irq_state_r.inta &&
				m_irq_state.intb == m_irq_state_r.intb &&
				(m_irq_state.inta || m_irq_state.intb)) begin

				for (i=0; i<100; i++) begin
					if (m_irq_state.inta || m_irq_state.intb) begin
						isr(m_irq_state);
					end else begin
						break;
					end 
				end
				
				if (i == 100) begin
					uvm_report_error(m_name, $psprintf("An IRQ is stuck-on: inta=%0d intb=%0d", 
						m_irq_state.inta, m_irq_state.intb));
				end 
			end 
		end 
	endtask
	
	task create_descriptor_sequences();
		wb_dma_channel_seq 	channel_seq;
		string				inst_name;
		uvm_component 		parent_c = get_parent();
		wb_dma_env    		env;
		
		assert($cast(env, parent_c));
		
		m_channel_seq = new[m_num_channels];

		// Start DMA descriptor sequences on each DMA Descriptor driver
		for (int i=0; i<m_num_channels; i++) begin
			$sformat(inst_name, "dma_channel_%0d", i);
			
			channel_seq = wb_dma_channel_seq::type_id::create(inst_name);

			// pass the channel id in
			channel_seq.init(i);
			
			m_channel_seq[i] = channel_seq;
			
			fork
				channel_seq.start(descriptor_sequencers[i]);
			join_none
			#0;
		end
		
	endtask 
	
	// Task to handle an ISR
	task isr(wb_dma_irq_ev irq);
		CH_CSR_t      		ch_csr;
		bit [31:0]    		tmp;
		wb_dma_descriptor	desc;		
		
		uvm_report_info("DMA_SW", $psprintf("ISR inta=%0d intb=%0d", irq.inta, irq.intb));
		
		for (int i=0; i<m_active_descriptors.size(); i++) begin
			desc = m_active_descriptors[i];
			
			m_mem_mgr.access(`CH_REG_BASE(`REG_BASE, desc.channel), 0, ch_csr);
			
			if (ch_csr.i_ch_done) begin
				uvm_report_info("DMA_SW", 
					$psprintf("channel %0d is done - CSR='h%08h ; done=%0d err=%0d busy=%0d", 
						desc.channel, ch_csr, ch_csr.done, ch_csr.err, ch_csr.busy));
				if (ch_csr.err) begin
					uvm_report_info("DMA_SW",
						$psprintf("channel %0d received error", desc.channel));
				end
				
				if (ch_csr.busy) begin
					uvm_report_warning("DMA_SW",
						$psprintf("channel %0d is still busy", desc.channel));
				end 
				
				// Read-back from the channel again
				ch_csr.ch_en = 0;
				m_mem_mgr.access(`CH_REG_BASE(`REG_BASE, desc.channel), 0, ch_csr);
				
				uvm_report_info("DMA_SW", $psprintf("After completion CSR='h%08h ; done=%0d err=%0d busy=%0d", 
						ch_csr, ch_csr.done, ch_csr.err, ch_csr.busy));

				m_active_descriptors.delete(i);
				
				// Post the descriptor-complete event to clients
				m_complete_ev.channel = desc.channel;
				desc_complete_analysis_port.write(m_complete_ev);		
				
			end
		end 
	endtask
	
	
endclass 
