/****************************************************************************
 * wb_master_rw_seq.svh
 ****************************************************************************/

/**
 * Class: wb_master_rw_seq
 * 
 * TODO: Add class documentation
 */
class wb_master_rw_seq extends uvm_sequence #(wb_master_req, wb_master_rsp);
	`uvm_object_utils(wb_master_rw_seq)
	
	wb_master_req							req;
	wb_master_rsp							rsp;

	function new(string name="wb_master_rw_seq");
		super.new(name);
		req = wb_master_req::type_id::create();
		rsp = wb_master_rsp::type_id::create();
	endfunction

	function void set_rd32(bit[31:0] addr);
		req.rnw = 1;
		req.addr = addr;
		req.n_bytes = 4;
	endfunction
	
	function void set_wr32(bit[31:0] addr, bit[31:0] data);
		req.rnw = 0;
		req.addr = addr;
		req.n_bytes = 4;
		req.data[0] = data;
	endfunction
	
	task body();
		start_item(req);
		finish_item(req);
		get_response(rsp);
	endtask

endclass


