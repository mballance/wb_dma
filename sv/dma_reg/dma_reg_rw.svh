/****************************************************************************
 * dma_reg_rw.svh
 ****************************************************************************/

/**
 * Class: dma_reg_rw
 * 
 * TODO: Add class documentation
 */
class dma_reg_rw extends uvm_sequence_item;
	`uvm_object_utils(dma_reg_rw)
	
	rand bit				is_write;
	rand bit[31:0]			addr;
	rand bit[31:0]			data;

	function new(string name="dma_reg_rw");
		super.new(name);
	endfunction


endclass


