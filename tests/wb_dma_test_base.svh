/****************************************************************************
 * wb_dma_test_base.svh
 ****************************************************************************/

/**
 * Class: wb_dma_test_base
 * 
 * TODO: Add class documentation
 */
class wb_dma_test_base extends uvm_test;
	`uvm_component_utils(wb_dma_test_base)
	
	wb_dma_env						m_env;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction


	/**
	 * Function: build_phase
	 *
	 * Override from class 
	 */
	virtual function void build_phase(input uvm_phase phase);
		m_env = wb_dma_env::type_id::create("m_env", this);

	endfunction

	/**
	 * Function: connect_phase
	 *
	 * Override from class 
	 */
	virtual function void connect_phase(input uvm_phase phase);

	endfunction



endclass


