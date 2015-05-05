/****************************************************************************
 * wb_dma_handshake_ev.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 *
 * The handshake event is posted by a handshake driver after it has 
 * requested a restart or skip operation. This event is used by the 
 * scoreboard to track handshake activity and adjust its expectations.
 ****************************************************************************/
`ifndef INCLUDED_WB_DMA_HANDSHAKE_EV_SVH
`define INCLUDED_WB_DMA_HANDSHAKE_EV_SVH

typedef enum {
	Restart,
	ForceNext
} handshake_ev_t;
	
class wb_dma_handshake_ev extends uvm_sequence_item;
	
	// The channel on which this event occurs
	int					channel_id;
	
	// The descriptor index within the descriptor chain
	int					descriptor_index;
	
	// The words already transferred before this event occurred
	int					words_transferred;
	
	// Type of this handshake event
	handshake_ev_t		ev_type;
	
	
//	`uvm_object_utils_begin(wb_dma_handshake_ev)
//		`uvm_field_int(channel_id, uvm_ALL_ON)
//		`uvm_field_int(words_transferred, uvm_ALL_ON)
//		`uvm_field_enum(handshake_ev_t, ev_type, uvm_ALL_ON)
//	`uvm_object_utils_end
	
	function new(string name="wb_dma_handshake_ev");
		super.new(name);
	endfunction 
	
endclass 

`endif /* INCLUDED_WB_DMA_HANDSHAKE_EV_SVH */
