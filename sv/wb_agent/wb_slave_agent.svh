/****************************************************************************
 * wb_slave_agent.svh
 ****************************************************************************/

/**
 * Class: wb_slave_agent
 * 
 * TODO: Add class documentation
 */
class wb_slave_agent extends uvm_agent;
	`uvm_component_utils (wb_slave_agent)
	
	wb_slave_driver									m_driver;
	uvm_sequencer #(wb_slave_req, wb_slave_rsp)		m_seqr;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction


	/**
	 * Function: build_phase
	 *
	 * Override from class 
	 */
	virtual function void build_phase(input uvm_phase phase);
		m_driver = wb_slave_driver::type_id::create("m_driver", this);
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


