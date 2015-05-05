/****************************************************************************
 * dma_int_msk.svh
 ****************************************************************************/

/**
 * Class: dma_int_msk
 * 
 * TODO: Add class documentation
 */
class dma_int_msk extends uvm_reg;
	`uvm_object_utils(dma_int_msk)
	
	rand uvm_reg_field				MASK;

	function new(string name="dma_int_msk");
		super.new(name, 1, UVM_NO_COVERAGE);
	endfunction

	function void build();
		MASK = uvm_reg_field::type_id::create("MASK");
		MASK.configure(this, 31, 0, "RW", 0, 0, 1, 0, 0);
	endfunction

endclass


