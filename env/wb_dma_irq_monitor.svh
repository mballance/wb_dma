/****************************************************************************
 * wb_dma_irq_monitor.svh
 * 
 *   Licensed under the Apache License, Version 2.0 (the
 *   "License"); you may not use this file except in
 *   compliance with the License.  You may obtain a copy of
 *   the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in
 *   writing, software distributed under the License is
 *   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 *   CONDITIONS OF ANY KIND, either express or implied.  See
 *   the License for the specific language governing
 *   permissions and limitations under the License.
 ****************************************************************************/

class wb_dma_irq_monitor extends uvm_component;
	`uvm_component_utils(wb_dma_irq_monitor)
	
	uvm_analysis_port #(wb_dma_irq_ev)				irq_analysis_port;
	
	virtual wb_dma_irq_if							m_if;
	
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	


	/**
	 * Function: build_phase
	 *
	 * Override from class 
	 */
	virtual function void build_phase(input uvm_phase phase);
		irq_analysis_port = new("irq_analysis_port", this);
	endfunction

	
	function void connect_phase(uvm_phase phase);
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
	
	task run_phase(uvm_phase phase);
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


