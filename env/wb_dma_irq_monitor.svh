/****************************************************************************
 * wb_dma_irq_monitor.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * Monitor for the IRQ interface. Sends interrupt events to the testbench
 * as the interrupt state changes
 ****************************************************************************/
`ifndef INCLUDED_WB_DMA_IRQ_MONITOR_SVH
`define INCLUDED_WB_DMA_IRQ_MONITOR_SVH

class wb_dma_irq_monitor extends uvm_component;
	uvm_analysis_port #(wb_dma_irq_ev)				irq_analysis_port;
	
	virtual wb_dma_irq_if							m_if;
	
	function new(string name, uvm_component parent);
		super.new(name, parent);
		
		irq_analysis_port = new("irq_analysis_port", this);
	endfunction
	
	function void connect();
		uvm_object cfg_o;
		wb_if_config_wrapper #(virtual wb_dma_irq_if) cfg;
		
		if (!get_config_object("irq_if", cfg_o, 0)) begin
			uvm_report_error("IRQ_MON", "Failed to get irq_if cfg");
			$stop;
		end 
		
		if (!$cast(cfg, cfg_o)) begin
			uvm_report_error("IRQ_MON", "Failed to cast irq_if");
			$stop;
		end
		
		m_if = cfg.m_if;
	endfunction 
	
	task run();
		wb_dma_irq_ev irq_ev = new("irq_ev");
		bit send = 0;
		
		irq_ev.inta = 0;
		irq_ev.intb = 0;
		
		forever begin
			@(posedge m_if.clk);
			
			send = (irq_ev.inta != m_if.inta || irq_ev.intb != m_if.intb);
		
			irq_ev.inta = m_if.inta;
			irq_ev.intb = m_if.intb;
			
			if (send) begin
				irq_analysis_port.write(irq_ev);
			end 
					 
		end 
	endtask 
	
	
	
endclass 

`endif /* INCLUDED_WB_DMA_IRQ_MONITOR_SVH */

