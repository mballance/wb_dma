/****************************************************************************
 * dma_channel_sz.svh
 ****************************************************************************/

/**
 * Class: dma_channel_sz
 * 
 * TODO: Add class documentation
 */
class dma_channel_sz extends uvm_reg;
	`uvm_object_utils(dma_channel_sz)
	rand uvm_reg_field				CHK_SZ;
	rand uvm_reg_field				TOT_SZ;

	function new(string name="dma_channel_sz");
		super.new(name, 32, UVM_NO_COVERAGE);
	endfunction
	
	function void build();
		CHK_SZ = uvm_reg_field::type_id::create("CHK_SZ");
		CHK_SZ.configure(this, 9, 16, "RW", 0, 0, 1, 1, 0); 
		
		TOT_SZ = uvm_reg_field::type_id::create("TOT_SZ");
		TOT_SZ.configure(this, 12, 0, "RW", 0, 0, 1, 1, 0); 
	endfunction

endclass


