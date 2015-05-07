/****************************************************************************
 * dma_reg_agent.svh
 ****************************************************************************/

/**
 * Class: dma_reg_agent
 * 
 * TODO: Add class documentation
 */
class dma_reg_agent extends uvm_agent;
	`uvm_component_utils(dma_reg_agent)
	
	uvm_sequencer #(dma_reg_rw)						m_seqr;
	dma_reg_driver									m_driver;
	uvm_sequencer #(wb_master_req, wb_master_rsp)	m_wb_seqr;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	


	/**
	 * Function: build_phase
	 *
	 * Override from class 
	 */
	virtual function void build_phase(input uvm_phase phase);
		m_seqr = new("m_seqr", this);
		m_driver = dma_reg_driver::type_id::create("m_driver", this);
	endfunction

	/**
	 * Function: connect_phase
	 *
	 * Override from class 
	 */
	virtual function void connect_phase(input uvm_phase phase);
		m_driver.seq_item_port.connect(m_seqr.seq_item_export);
	endfunction

	


endclass


