/****************************************************************************
 * dma_channel_addr.svh
 ****************************************************************************/

/**
 * Class: dma_channel_addr
 * 
 * TODO: Add class documentation
 */
class dma_channel_addr extends uvm_reg;
	`uvm_object_utils(dma_channel_addr)
	
	rand uvm_reg_field				ADDR;

	function new(string name="dma_channel_addr");
		super.new(name, 32, UVM_NO_COVERAGE);
	endfunction

	function void build();
		ADDR = uvm_reg_field::type_id::create("ADDR");
		ADDR.configure(this, 30, 2, "RW", 0, 'h3fff_ffff, 1, 1, 0);
	endfunction
	

endclass


