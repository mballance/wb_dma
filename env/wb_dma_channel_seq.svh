/****************************************************************************
 * wb_dma_channel_seq.svh
 *
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * Generates DMA descriptors for one DMA channel 
 ****************************************************************************/
 
class wb_dma_channel_seq extends uvm_sequence #(wb_dma_descriptor);
	`uvm_object_utils(wb_dma_channel_seq)
	
	int						m_channel_id;
	bit						m_ok_to_run;
	
	function new(string name="wb_dma_channel_seq");
		super.new(name);
		set_response_queue_error_report_disabled(1);
		set_response_queue_depth(0);
	endfunction 
	
	function void init(
		int				channel_id);
		m_channel_id = channel_id;
	endfunction
	
	virtual task set_ok_to_run();
		m_ok_to_run = 1;
	endtask  
	
    /**
     * Wait for notification that it's okay to run. This allows the 
     * sequences to be blocked until the software has configured the
     * interrupts
     */
    virtual task wait_ok_to_run();
		wait(m_ok_to_run == 1);
    endtask 
	
	
	task body();
		wb_dma_descriptor desc = wb_dma_descriptor::type_id::create("desc");
		
		desc.channel = m_channel_id;
		
		forever begin
			// Wait until ok to run
			wait_ok_to_run();
			
			assert(desc.randomize());
			
			start_item(desc);
			finish_item(desc);
		end
		
	endtask 
	
endclass


