/****************************************************************************
 * wb_dma_irq_ev.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * Message that indicates interrupt activation 
 ****************************************************************************/
`ifndef INCLUDED_WB_DMA_IRQ_EV_SVH
`define INCLUDED_WB_DMA_IRQ_EV_SVH

class wb_dma_irq_ev extends uvm_sequence_item;
	bit						inta;
	bit						intb;
	
//	`uvm_object_utils_begin(wb_dma_irq_ev)
//		`uvm_field_int(inta, uvm_ALL_ON)
//		`uvm_field_int(intb, uvm_ALL_ON)
//	`uvm_object_utils_end

	function new(string name="wb_dma_irq_ev");
		super.new(name);
	endfunction
	
endclass 

`endif /* INCLUDED_WB_DMA_IRQ_EV_SVH */
