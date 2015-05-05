/****************************************************************************
 * wb_master_agent.svh
 ****************************************************************************/

/**
 * Class: wb_master_agent
 * 
 * TODO: Add class documentation
 */
class wb_master_agent extends uvm_agent;
	`uvm_component_utils (wb_master_agent)

	uvm_sequencer #(wb_master_req, wb_master_rsp)	m_seqr;
	wb_master_driver								m_driver;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction


	/**
	 * Function: build_phase
	 *
	 * Override from class 
	 */
	function void build_phase(input uvm_phase phase);
		m_driver = wb_master_driver::type_id::create("m_driver", this);
		m_seqr = new("m_seqr", this);
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


