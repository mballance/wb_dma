/****************************************************************************
 * wb_dma_descriptor.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 *
 * Describes a DMA descriptor to be executed by a channel on the DMA engine
 ****************************************************************************/
`ifndef INCLUDED_WB_DMA_DESCRIPTOR_SVH
`define INCLUDED_WB_DMA_DESCRIPTOR_SVH


typedef enum {
	// Transfers are carried out without hardware handshaking
	ModeNormal 		= 0,
	
	// Transfers are controlled by hardware handshake signals
	ModeHandshake 	= 1
} mode_t; 


// Forward declaration for linked-list descriptor item 
typedef class wb_dma_ll_desc;




class wb_dma_descriptor extends uvm_sequence_item;
	
	// Increment source
	rand bit					inc_src;
	
	// Increment destination
	rand bit					inc_dst;

	// Source selection
	rand bit					src_sel;
	
	// Destination selection
	rand bit					dst_sel;
	
	// Address wrapping for src/dst
	rand bit [2:0]				src_addr_mask_bits;
	rand bit [2:0]				dst_addr_mask_bits;
	
	// Total transfer size in words
	rand bit [11:0]				tot_sz;

	// Chunk transfer size in words.
	rand bit [8:0]				chk_sz;
	
	constraint addr_inc_mask_c {
		src_addr_mask_bits inside {[4:6]};
		dst_addr_mask_bits inside {[4:6]};

		// We don't setup an address mask for non-incrementing addr
		(inc_src == 0) -> src_addr_mask_bits == 4;
		(inc_dst == 0) -> dst_addr_mask_bits == 4;
		
		// Apply weights to focus generation on the bins		
		chk_sz dist {[0:3] := 4, [4:507] :/ 8, [508:511] := 4};
		tot_sz dist {[1:4] := 4, [5:4091] :/ 8, [4092:4095] := 4};
	}	

	
	// Indicates the priority (0 is lowest)
	rand bit [2:0]				chn_priority;
	
	// Mode -- handshake or normal
	rand mode_t					mode;

	// Use external descriptor linked list
	rand bit					use_ed;

	// List of external descriptors
	rand wb_dma_ll_desc			ll_desc[];
	
	// stop enable
	rand bit					stop_enable;
	
	
	
	// Enable channel interrupt after each CHK_SZ has been transferred
	rand bit					ine_chk_done;
	
	// Enable channel interrupt when channel is done
	rand bit					ine_done;
	
	// Enable channel interrupt on error
	rand bit					ine_err;


	/****************************************************************
	 * Testbench Fields
	 * 
	 * Most of these fields are filled in by the descriptor driver
	 ****************************************************************/
	
	// Channel on which this descriptor will execute
	int							channel;
	
	// Address of the external descriptor block
	bit [31:0]					ed_addr;
	
	// These are filled in by the descriptor driver
	bit [31:0]					src_addr;
	bit [31:0]					dest_addr;

	
	constraint basics {
		
		if (use_ed == 0) {
			ll_desc.size() == 0;
		} else {
			// Do not exercise address mask in
			// external-descriptor mode
			src_addr_mask_bits == 4;
            dst_addr_mask_bits == 4;

			// Restrict the descriptor chain to 8
			ll_desc.size() inside {[1:8]};
		}	
		
		ine_chk_done 	== 0;
		ine_err			== 1;
		ine_done		== 1;
	}
	
	function new(string name="wb_dma_descriptor");
		super.new(name);
		
		// Initialize for the single-descriptor case
//		ll_desc    		= null;
		ine_chk_done 	= 0;
		ine_err 		= 1;
		ine_done 		= 1;
	endfunction 
	
//	`uvm_object_utils_begin(wb_dma_descriptor)
//		`uvm_field_int(channel, uvm_ALL_ON)
//		`uvm_field_int(ine_chk_done, uvm_ALL_ON)
//		`uvm_field_int(ine_done, uvm_ALL_ON)
//		`uvm_field_int(ine_err, uvm_ALL_ON)
//		`uvm_field_int(chn_priority, uvm_ALL_ON)
//		`uvm_field_enum(mode_t, mode, uvm_ALL_ON)
//		`uvm_field_int(chk_sz, uvm_ALL_ON)
//		`uvm_field_int(src_addr_mask_bits, uvm_ALL_ON)
//		`uvm_field_int(dst_addr_mask_bits, uvm_ALL_ON)
//		`uvm_field_int(use_ed, uvm_ALL_ON)
//		`uvm_field_int(ed_addr, uvm_ALL_ON)
//		
//		`uvm_field_int(inc_src, uvm_ALL_ON)
//		`uvm_field_int(inc_dst, uvm_ALL_ON)
//		`uvm_field_int(src_sel, uvm_ALL_ON)
//		`uvm_field_int(dst_sel, uvm_ALL_ON)
//		`uvm_field_int(tot_sz, uvm_ALL_ON)
//		`uvm_field_int(src_addr, uvm_ALL_ON)
//		`uvm_field_int(dest_addr, uvm_ALL_ON)
//		`uvm_field_array_object(ll_desc, uvm_ALL_ON)
//	`uvm_object_utils_end

	function void post_randomize();
		// Fill in the remaining descriptors
		if (use_ed) begin
			for (int i=0; i<ll_desc.size(); i++) begin
				ll_desc[i] = new;
				ll_desc[i].chk_sz = chk_sz;
				
				if (mode == ModeHandshake) begin
					if (i+1 >= ll_desc.size()) begin
						assert(ll_desc[i].randomize() with {
							ll_desc[i].force_next == ForceNext_Off;
							ll_desc[i].ars == 0;
						});
					end else begin
						assert(ll_desc[i].randomize());
					end
				end else begin
					// In normal mode, it is impossible to restart or skip
					// a descriptor
					assert(ll_desc[i].randomize() with {
						ll_desc[i].ars 			== 0;
						ll_desc[i].force_next 	== ForceNext_Off;
					});
				end 
			end
		end
	endfunction 
endclass


typedef enum {
	// Don't force next descriptor
	ForceNext_Off,
	// Force next descriptor when the next transfer starts
	ForceNext_Now,
	// Force next descriptor after this transfer
	ForceNext_Next
} force_next_t;	

/**
 * wb_dma_ll_desc
 * 
 * This describes one descriptor from a linked-list of external descriptors
 */
class wb_dma_ll_desc extends uvm_sequence_item;
	
	// Increment source
	rand bit					inc_src;
	
	// Increment destination
	rand bit					inc_dst;

	// Source selection
	rand bit					src_sel;
	
	// Destination selection
	rand bit					dst_sel;
	
	// chk_sz reflected from parent descriptor
	bit [8:0]					chk_sz;
	
	// Total transfer size in words
	rand bit [11:0]				tot_sz;
	
	// Determines whether or not the handshake
	// driver will attempt to skip this descriptor 
	rand force_next_t			force_next;
	
	// Determines whether or not the handshake
	// driver will restart this descriptor
	rand bit					ars;
	
	// These are filled in by the descriptor driver
	bit [31:0]					src_addr;
	bit [31:0]					dest_addr;
	
	constraint c {
		// Distribute tot_sz to focus on the coverage bins
		tot_sz dist {[1:4] := 4, [5:4091] :/ 8, [4092:4095] := 4};
		
		// Distribute ars and force_next to minimize the number of restarted
		// and skipped descriptors
		ars dist {0 := 10, 1 := 1};
		force_next dist {ForceNext_Off := 20, ForceNext_Now := 1, ForceNext_Next := 1};
		
		// Don't allow restarted or skipped descriptors if the
		// chunk size is greater than the total size
		if (chk_sz == 0 || chk_sz > tot_sz) {
			ars == 0;
			force_next == ForceNext_Off;
		}
	}	
	
//	`uvm_object_utils_begin(wb_dma_ll_desc)
//		`uvm_field_int(inc_src, uvm_ALL_ON)
//		`uvm_field_int(inc_dst, uvm_ALL_ON)
//		`uvm_field_int(src_sel, uvm_ALL_ON)
//		`uvm_field_int(dst_sel, uvm_ALL_ON)
//		`uvm_field_int(tot_sz, uvm_ALL_ON)
//		`uvm_field_enum(force_next_t, force_next, uvm_ALL_ON)
//		`uvm_field_int(ars, uvm_ALL_ON)
//		`uvm_field_int(src_addr, uvm_ALL_ON)
//		`uvm_field_int(dest_addr, uvm_ALL_ON)
//	`uvm_object_utils_end
	
	function new(string name="wb_dma_ll_desc");
		super.new(name);
	endfunction 
	
endclass


`endif /* INCLUDED_WB_DMA_DESCRIPTOR_SVH */
 
