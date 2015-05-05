/****************************************************************************
 * wb_dma_timer.svh
 *
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * Provides timer services to the testbench
 ****************************************************************************/

class wb_dma_timer extends uvm_component;
	`uvm_component_utils(wb_dma_timer)
	
	virtual wb_if						m_if;
	
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction 
	
	function void connect();
		uvm_object cfg_o;
		wb_if_config_wrapper #(virtual wb_if) cfg;
		
		if (!get_config_object("timer_if", cfg_o, 0)) begin
			uvm_report_error("TIMER", "Failed to get timer_if cfg");
			$stop;
		end 
		
		if (!$cast(cfg, cfg_o)) begin
			uvm_report_error("TIMER", "Failed to cast wb_if");
			$stop;
		end
		
		m_if = cfg.m_if;
	endfunction 
	
	task wait_clks(int clks);
		repeat (clks) begin
			@(posedge m_if.clk);
		end 
	endtask 
	
endclass 
