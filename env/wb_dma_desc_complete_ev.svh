/****************************************************************************
 * wb_dma_desc_complete_ev.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 *
 * Event that notifies clients that a DMA descriptor has completed.
 ****************************************************************************/
`ifndef INCLUDED_WB_DMA_DESC_COMPLETE_EV_SVH
`define INCLUDED_WB_DMA_DESC_COMPLETE_EV_SVH

class wb_dma_desc_complete_ev extends uvm_sequence_item;
	
	int							channel;
	
	`uvm_object_utils(wb_dma_desc_complete_ev)
	
	function new(string name="wb_dma_desc_complete_ev");
		super.new(name);
	endfunction 
	
endclass

`endif /* INCLUDED_WB_DMA_DESC_COMPLETE_EV_SVH */
 
 