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
	
	/**
	 * Task: run_phase
	 *
	 * Override from class 
	 */
	virtual task run_phase(input uvm_phase phase);
		// First, configure the DMA
		phase.raise_objection(this, "Configuring DMA");
		configure_dma();
		phase.drop_objection(this, "Configuring DMA");
		
		// Next, run test activity
		phase.raise_objection(this, "Running Scenario");
		run_scenario(phase);
		phase.drop_objection(this, "Running Scenario");
		
	endtask
	
	virtual task run_scenario(uvm_phase phase);
		$display("Error: No test scenario specified");
	endtask


	virtual task configure_dma();
		dma_config_seq cfg = dma_config_seq::type_id::create("cfg");
		cfg.dma_regs = null; // TODO: need to connect up registers
		
		cfg.start(null);
	endtask



endclass


