/****************************************************************************
 * wb_dma_infact_env.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * Environment that instantiates the inFact descriptor generator sequence 
 * instead of the random descriptor generator sequence
 ****************************************************************************/
`ifndef INCLUDED_WB_DMA_INFACT_ENV_SVH
`define INCLUDED_WB_DMA_INFACT_ENV_SVH

class wb_dma_infact_env extends wb_dma_env;
	`uvm_component_utils(wb_dma_infact_env)
	
	function new(string name, uvm_component parent=null);
		super.new(name, parent);
		
		// Cause the inFact sequence to be created
		set_type_override("wb_dma_channel_seq", "infact_channel_desc_seq", 1);
	endfunction 
	
endclass 

`endif /* INCLUDED_WB_DMA_INFACT_ENV_SVH */

