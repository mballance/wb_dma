/****************************************************************************
 * wb_dma_slave_seq.svh
 *  
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 *
 * Sequence that interacts with the Wishbone Slave Driver (mirror for the
 * master interface). Receives memory requests from the master interfaces
 * on the DMA engine and sends these requests to the memory manager.
 ****************************************************************************/

class wb_dma_slave_seq extends uvm_sequence #(wb_slave_req, wb_slave_rsp);
	`uvm_object_utils(wb_dma_slave_seq)
	
	int							m_ifc_id;
	memory_mgr			m_mem_mgr;
	
	function void init(int ifc_id, memory_mgr mem_mgr);
		m_ifc_id  = ifc_id;
		m_mem_mgr = mem_mgr;
	endfunction 
		
	task body();
		wb_slave_req req;
		wb_slave_rsp rsp;
		
		req = wb_slave_req::type_id::create("req");
		rsp = wb_slave_rsp::type_id::create("rsp");
		
		// dummy request
		wait_for_grant();
		send_request(req);
		
		forever begin
			get_response(rsp);
			
			m_mem_mgr.bus_access(
				m_ifc_id,
				rsp.addr,
				(rsp.rnw)?0:1,
				rsp.data);
			
			if (rsp.rnw) begin
				req.data = rsp.data;
			end
			
			// Send the actual response
			wait_for_grant();
			send_request(req);
		end
	endtask 
endclass 