/****************************************************************************
 * dma_config_seq.svh
 ****************************************************************************/

/**
 * Class: dma_config_seq
 * 
 * TODO: Add class documentation
 */
class dma_config_seq extends uvm_sequence;
	`uvm_object_utils(dma_config_seq)
	
	// Configuration fields
	
	// Arbitation
	
	// Interrupts
	rand bit[31:0]					INT_MSK_A;
	rand bit[31:0]					INT_MSK_B;
	
	rand bit[31:0]					INT_SRC_A;
	rand bit[31:0]					INT_SRC_B;

	// Priorities for all the channels
	rand bit[2:0]					ch_priority[31];
	
	dma_reg_block					dma_regs;

	function new(string name="dma_config");
		super.new(name);
	endfunction
	
	virtual task select_config();
		assert(this.randomize());
	endtask

	/**
	 * Task: body
	 *
	 * Override from class 
	 */
	virtual task body();
		// Configure the DMA engine
		select_config();
		
		// Write registers

	endtask
	

endclass


