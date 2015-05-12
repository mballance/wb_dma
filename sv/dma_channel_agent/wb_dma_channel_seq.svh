/****************************************************************************
 * wb_dma_channel_seq.svh
 *
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * Generates DMA descriptors for one DMA channel 
 ****************************************************************************/
 
class wb_dma_channel_seq extends uvm_sequence #(dma_channel_transfer_desc);
	`uvm_object_utils(wb_dma_channel_seq)
	dma_channel_transfer_desc 		desc;
	
	function new(string name="wb_dma_channel_seq");
		super.new(name);
		set_response_queue_error_report_disabled(1);
		set_response_queue_depth(0);
	endfunction 
	
	task body();
		int max=10;
		
		for (int i=1; i<=max; i++) begin
		if (desc == null) begin
			desc = dma_channel_transfer_desc::type_id::create("desc");
		end
		assert(desc.randomize());
	
		$display("--> %0s %0d/%0d", get_name(), i, max);
		start_item(desc);
		finish_item(desc);
		$display("<-- %0s %0d/%0d", get_name(), i, max);
		end
	endtask 
	
endclass


