/****************************************************************************
 * dma_channel_agent.svh
 ****************************************************************************/

/**
 * Class: dma_channel_agent
 * 
 * TODO: Add class documentation
 */
class dma_channel_agent extends uvm_agent;
	`uvm_component_utils(dma_channel_agent)

	dma_channel_driver						m_driver;
	uvm_sequencer #(dma_channel_transfer_desc)		m_seqr;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	

	/**
	 * Function: build_phase
	 *
	 * Override from class 
	 */
	virtual function void build_phase(input uvm_phase phase);
		m_driver = dma_channel_driver::type_id::create("m_driver", this);
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


