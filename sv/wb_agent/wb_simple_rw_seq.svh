/****************************************************************************
 * wb_simple_rw_seq.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 *
 * Sequence that performs a read or write access via the Wishbone driver
 ****************************************************************************/
`ifndef INCLUDED_WB_SIMPLE_RW_SEQ_SVH
`define INCLUDED_WB_SIMPLE_RW_SEQ_SVH

class wb_simple_rw_seq extends uvm_sequence #(wb_master_req, wb_master_rsp);
	`uvm_object_utils(wb_simple_rw_seq)
	
	bit [31:0]						addr;
	bit [31:0]						data[];
	bit								rnw;
	bit [3:0]						n_bytes;
	
	wb_master_req req;
	wb_master_rsp rsp; 
	
	function new(string name="wb_simple_rw_seq");
		super.new(name);
		
		data = new[4];
		req = wb_master_req::type_id::create("req");
		rsp = wb_master_rsp::type_id::create("rsp");
	endfunction 
	
	task body();
		req.addr    = addr;
		req.rnw     = rnw;
		req.n_bytes = n_bytes;
		req.data    = data;
		
		start_item(req);
		finish_item(req);
		
		get_response(rsp);
		data = rsp.data;
	endtask 
	
endclass 

`endif /* INCLUDED_WB_SIMPLE_RW_SEQ_SVH */
