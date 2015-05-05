/****************************************************************************
 * dma_csr.svh
 ****************************************************************************/

/**
 * Class: dma_csr
 * 
 * TODO: Add class documentation
 */
class dma_csr extends uvm_reg;
	`uvm_object_utils(dma_csr)
	
	rand uvm_reg_field			PAUSE;

	function new(string name="dma_csr");
		super.new(name, 1, UVM_NO_COVERAGE);
	endfunction

	function void build();
		PAUSE = uvm_reg_field::type_id::create("PAUSE");
		PAUSE.configure(this, 1, 0, "RW", 0, 0, 1, 0, 0);
		
	endfunction

endclass


