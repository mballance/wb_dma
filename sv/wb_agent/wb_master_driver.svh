/****************************************************************************
 * wb_master_driver.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * uvm Driver for a Wishbone Master interface
 ****************************************************************************/
`ifndef INCLUDED_WB_MASTER_DRIVER_SVH
`define INCLUDED_WB_MASTER_DRIVER_SVH

class wb_master_driver extends uvm_driver #(wb_master_req, wb_master_rsp);
	`uvm_component_utils (wb_master_driver)
	
	virtual wb_if						m_if;
	
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	
	function void connect();
		uvm_object cfg_o;
		wb_if_config_wrapper #(virtual wb_if) cfg;
		
		if (!get_config_object("master_if", cfg_o, 0)) begin
			uvm_report_error("WB_MASTER", "Failed to get master_if cfg");
			$stop;
		end 
		
		if (!$cast(cfg, cfg_o)) begin
			uvm_report_error("WB_MASTER", "Failed to cast master_if");
			$stop;
		end
		
		m_if = cfg.m_if;
	endfunction 



	/**
	 * Task: run_phase
	 *
	 * Override from class 
	 */
	virtual task run_phase(input uvm_phase phase);
		wb_master_req req = null;
		wb_master_rsp rsp = null;
		int timeout;
		
		// Ensure reset
		m_if.adr = 32'h0000_0000;
		m_if.dat_o = 32'h0000_0000;
		m_if.cyc = 0;
		m_if.stb = 0;
		m_if.sel = 0;
		m_if.we  = 0;
		
		while (!m_if.rst) begin
			@(posedge m_if.clk);
		end 
		
		while (m_if.rst) begin
			@(posedge m_if.clk);
		end 

		rsp = wb_master_rsp::type_id::create("rsp");
		
		forever begin
			seq_item_port.get(req);
			
			rsp.n_bytes = req.n_bytes;
			rsp.set_id_info(req);
			
			/*
			uvm_report_info("WB_DRV", 
				$psprintf("[%0t] get request", $time));
			uvm_report_info("WB_DRV",
				$psprintf("    n_bytes=%0d", req.n_bytes));
				 */
			
			@(posedge m_if.clk);
			
			for (int i=0; i<req.n_bytes; i+=4) begin
				m_if.adr = (req.addr + i);
				
				// For write...
				if (!req.rnw) begin
					if (req.n_bytes < 4) begin
						$display("[TODO] handle small access");
						$stop;
					end else begin
						m_if.dat_o = req.data[i / 4];
					end
					 
					m_if.we  = 1;
				end else begin
					m_if.we = 0;
				end
				
				m_if.cyc = 1;
				m_if.stb = 1;
				
				if (req.n_bytes < 4) begin
					$display("[TODO] handle small access");
					$stop;
				end else begin
					m_if.sel = 'hf;
				end 
				
				@(posedge m_if.clk);
				timeout = 0;
				while (m_if.ack != 1 && m_if.err != 1 && (timeout++ < 64)) begin
					@(posedge m_if.clk);
				end 
				
				if (timeout >= 64) begin
					uvm_report_error("WB DRV", "Bus access timed out");
				end 
				
				if (req.rnw) begin
					rsp.data[i / 4] = m_if.dat_i;
				end

				// Small delay
				@(posedge m_if.post_clk);
				m_if.cyc = 0;
				m_if.stb = 0;
				m_if.we  = 1'h0;
				m_if.sel = 4'h0;
			end
				
			/*
			uvm_report_info("WB_DRV", 
				$psprintf("[%t] send response", $time));
				 */
			
			seq_item_port.put(rsp);
		end 
		
	endtask 
	
	
endclass 

`endif /* INCLUDED_WB_MASTER_DRIVER_SVH */
