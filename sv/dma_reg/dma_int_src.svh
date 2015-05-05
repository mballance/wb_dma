/****************************************************************************
 * dma_int_src.svh
 ****************************************************************************/

/**
 * Class: dma_int_src
 * 
 * TODO: Add class documentation
 */
class dma_int_src extends uvm_reg;
	`uvm_object_utils(dma_int_src)
	
	rand uvm_reg_field			SRC;

	function new(string name="dma_int_src");
		super.new(name, 1, UVM_NO_COVERAGE);
	endfunction

	function void build();
		SRC = uvm_reg_field::type_id::create("SRC");
	endfunction

endclass


