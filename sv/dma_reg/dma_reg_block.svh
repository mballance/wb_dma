/****************************************************************************
 * dma_reg_block.svh
 ****************************************************************************/

/**
 * Class: dma_reg_block
 * 
 * TODO: Add class documentation
 */
class dma_reg_block extends uvm_reg_block;
	`uvm_object_utils(dma_reg_block)
	
	rand dma_csr				CSR;
	rand dma_int_msk			INT_MSK_A;
	rand dma_int_msk			INT_MSK_B;
	rand dma_int_src			INT_SRC_A;
	rand dma_int_src			INT_SRC_B;

	function new(string name="dma_reg_block");
		super.new(name, UVM_NO_COVERAGE);
	endfunction


endclass


