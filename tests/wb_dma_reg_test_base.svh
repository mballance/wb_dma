/****************************************************************************
 * wb_dma_reg_test_base.svh
 ****************************************************************************/

/**
 * Class: wb_dma_reg_test_base
 * 
 * TODO: Add class documentation
 */
class wb_dma_reg_test_base extends wb_dma_test_base;
	`uvm_component_utils(wb_dma_reg_test_base)

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	
	/**
	 * Task: configure_dma
	 *
	 * Override from class 
	 */
	virtual task configure_dma();
		// Don't write configuration registers, since this is a 
		// register test
	endtask

	/**
	 * Task: run_scenario
	 *
	 * Override from class 
	 */
	virtual task run_scenario(uvm_phase phase);
		dma_reg_seq_base reg_seq;
		
		reg_seq = dma_reg_seq_base::type_id::create("reg_seq");
		reg_seq.m_dma_regs = m_env.m_dma_regs;
		
		reg_seq.start(null);
	endtask

	


endclass


