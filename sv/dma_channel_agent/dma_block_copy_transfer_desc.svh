/****************************************************************************
 * dma_block_copy_transfer_desc.svh
 ****************************************************************************/

/**
 * Class: dma_block_copy_transfer_desc
 * 
 * TODO: Add class documentation
 */
class dma_block_copy_transfer_desc extends dma_channel_transfer_desc;
	`uvm_object_utils(dma_block_copy_transfer_desc)

	function new(string name="dma_block_copy_transfer_desc");
		super.new(name);
	endfunction
	
	constraint block_copy_c {
		src_addr_mask_bits == 4;
		dst_addr_mask_bits == 4;
		tot_sz <= 256;
		use_ed == 0;
		mode == ModeNormal;
	}

endclass


