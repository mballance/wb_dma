/****************************************************************************
 * dma_reg_seq_base.svh
 ****************************************************************************/

/**
 * Class: dma_reg_seq_base
 * 
 * TODO: Add class documentation
 */
class dma_reg_seq_base extends uvm_sequence;
	`uvm_object_utils(dma_reg_seq_base)
	
	dma_reg_block			m_dma_regs;

	function new(string name="dma_reg_seq_base");
		super.new(name);
	endfunction


	/**
	 * Task: body
	 *
	 * Override from class 
	 */
	virtual task body();
		$display("Error: dma_reg_seq_base::body() not implemented");
	endtask

endclass


