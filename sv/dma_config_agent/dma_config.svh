/****************************************************************************
 * dma_config.svh
 ****************************************************************************/

/**
 * Class: dma_config
 * 
 * TODO: Add class documentation
 */
class dma_config extends uvm_sequence_item;
	`uvm_object_utils(dma_config)
	
	// Configuration fields
	
	// Arbitation
	
	// Interrupts
	rand bit[31:0]					INT_MSK_A;
	rand bit[31:0]					INT_MSK_B;
	
	rand bit[31:0]					INT_SRC_A;
	rand bit[31:0]					INT_SRC_B;

	// Priorities for all the channels
	rand bit[2:0]					ch_priority[31];

	function new(string name="dma_config");
		super.new(name);
	endfunction

	

endclass


