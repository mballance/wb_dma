/****************************************************************************
 * dma_channel_amask.svh
 ****************************************************************************/

/**
 * Class: dma_channel_amask
 * 
 * TODO: Add class documentation
 */
class dma_channel_amask extends uvm_reg;
	`uvm_object_utils(dma_channel_amask)
	
	uvm_reg_field				MASK;

	function new(string name="dma_channel_amask");
		super.new(name, 32, UVM_NO_COVERAGE);
	endfunction
	
	function void build();
		MASK = uvm_reg_field::type_id::create("MASK");
		MASK.configure(this, 28, 4, "RW", 0, 0, 1, 1, 0);
	endfunction

endclass


