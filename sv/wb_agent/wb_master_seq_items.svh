/****************************************************************************
 * wb_master_seq_items.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * Sequence items for use with the Wishbone Master driver
 ****************************************************************************/

class wb_master_req extends uvm_sequence_item;
	`uvm_object_utils(wb_master_req)

	rand bit [31:0]			addr;
	rand bit [31:0]			data[];
	rand bit				rnw;
	// Can be 1..3 or a multiple of 4
	rand bit [4:0]			n_bytes;
	
//	`uvm_object_utils_begin(wb_master_req)
//		`uvm_field_int(addr, uvm_ALL_ON)
//		`uvm_field_array_int(data, uvm_ALL_ON)
//		`uvm_field_int(rnw, uvm_ALL_ON)
//		`uvm_field_int(n_bytes, uvm_ALL_ON)
//	`uvm_object_utils_end

	
	function new(string name="wb_master_seq");
		super.new(name);
		
		data = new[4];
	endfunction 
	
endclass

class wb_master_rsp extends uvm_sequence_item;
	`uvm_object_utils(wb_master_rsp)

	bit [31:0]				data[4];
	int						n_bytes;
	
	
endclass 

	