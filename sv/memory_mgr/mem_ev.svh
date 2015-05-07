/****************************************************************************
 * mem_ev.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * mem_ev describes a memory access. The memory manager produces
 * memory events based on DMA master interface activity to memory. The
 * scoreboard uses these events to check correct DMA operation
 ****************************************************************************/

class mem_ev extends uvm_sequence_item;
	`uvm_object_utils(mem_ev)
	
	int							ifc;
	bit [31:0]					addr;
	bit [31:0]					data;
	bit 						we;
	
//	`uvm_object_utils_begin(mem_ev)
//		`uvm_field_int(addr, uvm_ALL_ON)
//		`uvm_field_int(data, uvm_ALL_ON)
//		`uvm_field_int(we, uvm_ALL_ON)
//	`uvm_object_utils_end
	
endclass

