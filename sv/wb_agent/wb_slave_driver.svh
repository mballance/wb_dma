/****************************************************************************
 * wb_slave_driver.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * uvm Driver for a Wishbone Slave interface
 ****************************************************************************/

class wb_slave_driver extends uvm_driver #(wb_slave_req, wb_slave_rsp);
	`uvm_component_utils(wb_slave_driver)
	
	virtual wb_if						m_if;
	
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	 
	function void connect_phase(uvm_phase phase);
		uvm_object cfg_o;
		wb_if_config_wrapper #(virtual wb_if) cfg;
		
		if (!get_config_object("slave_if", cfg_o, 0)) begin
			uvm_report_error("WB_SLAVE", "Failed to get slave_if");
			$stop;
		end 
		
		if (!$cast(cfg, cfg_o)) begin
			uvm_report_error("WB_SLAVE", "Failed to cast slave_if");
			$stop;
		end 
		
		m_if = cfg.m_if;
	endfunction
	
	task run_phase(uvm_phase phase);
		wb_slave_req req = null;
		wb_slave_rsp rsp = null;
		
		req = wb_slave_req::type_id::create("req");
		rsp = wb_slave_rsp::type_id::create("rsp");
		
		// Ensure reset
		m_if.dat_o = 32'h0000_0000;
		m_if.ack = 0;
		m_if.err = 0;
		m_if.rty = 0;
		
		while (!m_if.rst) begin
			@(posedge m_if.clk);
		end 
		
		while (m_if.rst) begin
			@(posedge m_if.clk);
		end
		
		// Get a null request to get the ball rolling
		seq_item_port.get(req); 
		
		forever begin
			@(posedge m_if.clk);
			
			// Wait for a request
			while (!(m_if.stb == 1 && m_if.cyc == 1)) begin
				@(posedge m_if.clk);
			end
			
			rsp.addr = m_if.adr;
			
			if (m_if.we) begin
				rsp.data = m_if.dat_i;
				rsp.rnw  = 0;
			end else begin
				rsp.rnw  = 1;
			end
			
			rsp.set_id_info(req);
			
			seq_item_port.put(rsp);
			
			// Get the testbench response
			// uvm_report_info("WB_SLV", $psprintf("[%0t] receive response", $time));
			seq_item_port.get(req);
			
			if (m_if.we != 1) begin
				m_if.dat_o = req.data;
			end
			
			m_if.ack = 1;
			
			@(posedge m_if.clk);
			
			m_if.ack = 0;
		end
	endtask 
	 
endclass 

