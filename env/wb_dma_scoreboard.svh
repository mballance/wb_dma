/****************************************************************************
 * wb_dma_scoreboard.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 *
 * Scoreboard for the DMA testbench. Tracks memory activity from the DMA
 * engine to determine whether transfers are correctly carried out
 ****************************************************************************/
`ifndef INCLUDED_WB_DMA_SCOREBOARD_SVH
`define INCLUDED_WB_DMA_SCOREBOARD_SVH


`wb_dma_analysis_closure_imp_t(mem_analysis_export_t, 
	wb_dma_mem_ev, wb_dma_scoreboard, write_mem_ev)
`wb_dma_analysis_closure_imp_t(descriptor_analysis_export_t, 
	wb_dma_descriptor, wb_dma_scoreboard, write_descriptor_start)
`wb_dma_analysis_closure_imp_t(descriptor_complete_analysis_export_t,
	wb_dma_desc_complete_ev, wb_dma_scoreboard, write_descriptor_complete)

`wb_dma_analysis_closure_imp_t(handshake_ev_analysis_export_t,
	wb_dma_handshake_ev, wb_dma_scoreboard, write_handshake_ev)

/**
 * Information on each descriptor that the scoreboard is monitoring
 * 
 */
class wb_dma_descriptor_sb_info;
	wb_dma_descriptor						desc;
	// Flag that tracks whether the previous access was a write
	// Asserting that the R/W order always holds is useful in
	// early detection of an incorrect operation
	bit										last_acc_write;
	
	// When performing an external-descriptor transfer, tracks
	// the current low-level descriptor
	int										ll_desc_idx;
	int										ll_desc_reads;
	int										ll_desc_writes;
	
	int										exp_access_cnt;
	bit [31:0]								next_read_address;
	bit [31:0]								next_write_address;
	int										num_reads;
	int										num_writes;
	bit										complete;
	bit										pass;
	
	function new();
		pass = 1;
	endfunction 
endclass


class wb_dma_scoreboard extends uvm_component;
	mem_analysis_export_t					mem_analysis_export;
	descriptor_analysis_export_t			descriptor_analysis_export;
	descriptor_complete_analysis_export_t	descriptor_complete_analysis_export;
	handshake_ev_analysis_export_t			handshake_ev_analysis_export;
	
	wb_dma_memory_mgr						m_mem_mgr;
	wb_dma_descriptor_sb_info				m_active_descriptors[$];
	
	// List of descriptors that must be completed in order to stop
	wb_dma_descriptor_sb_info				m_stop_barrier[$];
	string									m_name = "SCOREBD";
	
	int										m_total_descriptors;
	
	// Tracking
	int										m_last_write_ch_id = -1;
	
	function new(string name, uvm_component parent);
		super.new(name, parent);
		mem_analysis_export = new("mem_analysis_export", this);
		descriptor_analysis_export = new("descriptor_analysis_export", this);
		descriptor_complete_analysis_export = new("descriptor_complete_analysis_export", this);
		handshake_ev_analysis_export = new("handshake_ev_analysis_export", this);
		
		// Enable stop processing, so the scoreboard can control completion
		enable_stop_interrupt = 1;
	
	endfunction
	
	function void init(wb_dma_memory_mgr			mem_mgr);
		m_mem_mgr = mem_mgr;
	endfunction 
	
	/****************************************************************
	 * write_mem_ev()
	 * 
	 * Called when the memory manager posts a memory-access event
	 ****************************************************************/
	function void write_mem_ev(wb_dma_mem_ev ev);
		bit							descriptor_access = 0;
		bit [31:0]					src_addr, dst_addr;
		bit							src_sel;
		wb_dma_descriptor_sb_info 	target = null;
		int							target_ll_desc_idx;
		string mem_info;
		

		if ((target = is_descriptor_access(ev)) != null) begin
			uvm_report_info(m_name, $psprintf(
				"Target is DMA descriptor for channel %0d", 
				target.desc.channel), UVM_FULL);
		end else if ((target = is_src_dst_access(ev, target_ll_desc_idx)) != null) begin
			uvm_report_info(m_name, $psprintf("memory %0s to %0h (%0d)", 
				(ev.we)?"write":"read", ev.addr, (ev.we)?target.num_writes:target.num_reads), UVM_FULL);
			if (target.desc.use_ed) begin
				check_ed_access(ev, target, target_ll_desc_idx);
			end else begin
				check_non_ed_access(ev, target);
			end 

			if (ev.we == target.last_acc_write) begin
				uvm_report_error(m_name, 
					$psprintf("Received %0s for channel %0d descriptor. Expect %0s",
						(ev.we)?"Write":"Read", target.desc.channel, 
					(target.last_acc_write)?"Read":"Write"));
				target.pass = 0;
			end
		
			if (target.last_acc_write == 0) begin
				target.last_acc_write = 1;
			end else begin
				target.last_acc_write = 0;
			end
			
			// Check that the DMA arbiter is scheduling accesses correctly
			check_priorities(target);
		end else begin
			uvm_report_error(m_name, $psprintf("Memory %0s to %0h did not match any DMA descriptor",
				(ev.we)?"write":"read", ev.addr));
			if (m_mem_mgr.get_region_desc(ev.addr, mem_info)) begin
				uvm_report_info(m_name, $psprintf("Target memory info: %s", mem_info));
			end else begin
				uvm_report_info(m_name, "no information on target memory region");
			end
			
			uvm_report_info(m_name, "--> Active descriptors");
			for (int j=0; j<m_active_descriptors.size(); j++) begin
				m_active_descriptors[j].desc.print();
			end 
			uvm_report_info(m_name, "<-- Active descriptors");
		end
	endfunction
	
	/****************************************************************
	 * check_ed_access()
	 * 
	 * Checks an access to an external descriptor
	 ****************************************************************/
	function void check_ed_access(
		wb_dma_mem_ev				ev,
		wb_dma_descriptor_sb_info	target,
		int							target_ll_idx);
		
		wb_dma_ll_desc target_ll_desc = target.desc.ll_desc[target_ll_idx];
		
		if ((ev.we && ev.ifc == target_ll_desc.dst_sel) ||
			(!ev.we && ev.ifc == target_ll_desc.src_sel)) begin
			uvm_report_info(m_name, $psprintf("Memory %0s to 'h%0h from ifc %0d targets DMA descriptor %0d (%0d reads / %0d writes)",
				(ev.we)?"write":"read", ev.addr, ev.ifc, target.desc.channel, target.num_reads, target.num_writes), UVM_FULL);
			// Check the address sequence
			if (ev.we) begin
				if (ev.addr != target.next_write_address) begin
					uvm_report_error(m_name, $psprintf(
						"[CHAN %0d] Expecting write to 'h%08h ; received write to 'h%08h",
						target.desc.channel, target.next_write_address, ev.addr));
					target.pass = 0;
				end
				target.ll_desc_writes++;
				
				// Move to the next descriptor in the chain
				if (target.ll_desc_writes >= target_ll_desc.tot_sz &&
					(target_ll_idx+1 < target.desc.ll_desc.size())) begin
					target_ll_desc = target.desc.ll_desc[target_ll_idx+1];
					uvm_report_info(m_name, $psprintf(
						"Setting write address ('h%08h) from next descriptor",
						 target_ll_desc.dest_addr), UVM_FULL);
					target.next_write_address = target_ll_desc.dest_addr; 
				end else begin
					target.next_write_address = next_ed_address(ev.we,
							target_ll_desc, target.next_write_address);
				end
			end else begin
				if (ev.addr != target.next_read_address) begin
					uvm_report_error(m_name, $psprintf(
						"[CHAN %0d] Expecting read to 'h%08h ; received read to 'h%08h",
						target.desc.channel, target.next_read_address, ev.addr));
					target.pass = 0;
				end
				
				target.ll_desc_reads++;
				// Move to the next descriptor in the chain
				if (target.ll_desc_reads >= target_ll_desc.tot_sz &&
					(target_ll_idx+1 < target.desc.ll_desc.size())) begin
					target_ll_desc = target.desc.ll_desc[target_ll_idx+1];
					uvm_report_info(m_name, $psprintf(
						"Setting read address ('h%08h) from next descriptor",
						 target_ll_desc.src_addr), UVM_FULL);
					target.next_read_address = target_ll_desc.src_addr; 
				end else begin
					target.next_read_address = next_ed_address(ev.we,
							target_ll_desc, target.next_read_address);
				end
			end
			
			target_ll_desc = target.desc.ll_desc[target_ll_idx];
			if (target.ll_desc_reads >= target_ll_desc.tot_sz &&
				target.ll_desc_writes >= target_ll_desc.tot_sz) begin
				uvm_report_info(m_name, $psprintf(
					"Moving to next descriptor (%0d) in the chain", 
					(target.ll_desc_idx+1)), UVM_FULL);
				target.ll_desc_reads = 0;
				target.ll_desc_writes = 0;
				target.ll_desc_idx++;
			end 
		end else begin
			uvm_report_error(m_name, $psprintf("Memory %0s to 'h%0h from ifc %0d is from the wrong master interface",
				(ev.we)?"write":"read", ev.addr, ev.ifc));
			target.pass = 0;
		end
	endfunction

	/****************************************************************
	 * next_ed_address()
	 * 
	 * Compute the next address for an external descriptor
	 ****************************************************************/
	function bit [31:0] next_ed_address(
		bit						we,
		wb_dma_ll_desc			target_ll_desc,
		bit [31:0]				address);
		if (we) begin
			if (target_ll_desc.inc_dst) begin
				// Always just +4
				address += 4;
			end
		end else begin
			if (target_ll_desc.inc_src) begin
				// Always just +4
				address += 4;
			end
		end
		
		return address;	 
	endfunction 

	/****************************************************************
	 * next_int_address()
	 * 
	 * Compute the next address for an internal descriptor
	 ****************************************************************/
	function bit [31:0] next_int_address(
		bit						we,
		wb_dma_descriptor		target,
		bit [31:0]				address);
		bit [31:0]				mask = 'hffff_ffff;
		
		if (we) begin
			if (target.inc_dst) begin
				if (target.dst_addr_mask_bits > 4) begin
					mask = ((mask << target.dst_addr_mask_bits) | 'hf);
				end
				
				address = ((address & (~mask)) | ((address + 4) & mask));
			end
		end else begin
			if (target.inc_src) begin
				if (target.src_addr_mask_bits > 4) begin
					mask = ((mask << target.src_addr_mask_bits) | 'hf);
				end
				
				address = ((address & (~mask)) | ((address + 4) & mask));
			end
		end
 
 		return address;
	endfunction 
	
	/****************************************************************
	 * is_descriptor_access()
	 * 
	 * Checks whether this memory access is to descriptor space 
	 ****************************************************************/
	function wb_dma_descriptor_sb_info is_descriptor_access(wb_dma_mem_ev ev);
		wb_dma_descriptor_sb_info ret = null;
		
		for (int i=0; i<m_active_descriptors.size(); i++) begin
			wb_dma_descriptor_sb_info desc_info = m_active_descriptors[i];
			wb_dma_descriptor desc = desc_info.desc;
			
			// This is an access to a linked descriptor
			if (desc.use_ed && ev.addr >= desc.ed_addr && 
				(ev.addr < (desc.ed_addr + ('h10 * desc.ll_desc.size())))) begin
				ret = desc_info;
				break;
			end
		end  
		
		return ret;
	endfunction

	/****************************************************************
	 * check_non_ed_access()
	 * 
	 * Checks an access to a descriptor described internally
	 ****************************************************************/
	function void check_non_ed_access(
		wb_dma_mem_ev				ev,
		wb_dma_descriptor_sb_info	target);
		
		if ((ev.we && ev.ifc == target.desc.dst_sel) ||
			(!ev.we && ev.ifc == target.desc.src_sel)) begin
			uvm_report_info(m_name, $psprintf("Memory %0s to 'h%0h from ifc %0d targets DMA descriptor %0d (%0d reads / %0d writes)",
				(ev.we)?"write":"read", ev.addr, ev.ifc, target.desc.channel, target.num_reads, target.num_writes), UVM_FULL);
		end else begin
			uvm_report_error(m_name, $psprintf("Memory %0s to 'h%0h from ifc %0d (descriptor %0d) is from the wrong master interface",
				(ev.we)?"write":"read", ev.addr, ev.ifc, target.desc.channel));
			target.pass = 0;
		end

		if (ev.we) begin
			target.next_write_address = next_int_address(ev.we,
					target.desc, target.next_write_address);
		end else begin
			target.next_read_address = next_int_address(ev.we,
					target.desc, target.next_read_address);
		end
	endfunction 
	
	/****************************************************************
	 * is_src_dst_access()
	 * 
	 * Checks whether the given memory-access event is within
	 ****************************************************************/
	function wb_dma_descriptor_sb_info is_src_dst_access(
		wb_dma_mem_ev			ev,
		output int 				ll_desc_idx_o);
		wb_dma_descriptor_sb_info ret = null;
		
		// Search for a descriptor with a memory range that matches this access 		
		for (int i=0; i<m_active_descriptors.size(); i++) begin
			wb_dma_descriptor_sb_info desc_info = m_active_descriptors[i];
			wb_dma_descriptor desc = desc_info.desc;
			
			if (desc.use_ed) begin
				for (int j=0; j<desc.ll_desc.size(); j++) begin
					wb_dma_ll_desc ll_desc = desc.ll_desc[j];
			
					if (ll_desc.inc_src) begin
						if (ev.we == 0 && ev.addr >= ll_desc.src_addr && 
								(ev.addr < (ll_desc.src_addr + (ll_desc.tot_sz*4)))) begin
							ret = desc_info;
							ll_desc_idx_o = j;
							desc_info.num_reads++;
						end
					end else begin
						if (ev.we == 0 && ev.addr == ll_desc.src_addr) begin
							ret = desc_info;
							ll_desc_idx_o = j;
							desc_info.num_reads++;
						end 
					end 

					if (ll_desc.inc_dst) begin
						if (ev.we == 1 && ev.addr >= ll_desc.dest_addr && 
								(ev.addr < (ll_desc.dest_addr + (ll_desc.tot_sz*4)))) begin
							ret = desc_info;
							ll_desc_idx_o = j;
							desc_info.num_writes++;
						end
					end else begin
						if (ev.we == 1 && ev.addr == ll_desc.dest_addr) begin
							ret = desc_info;
							ll_desc_idx_o = j;
							desc_info.num_writes++;
						end 
					end
				end
			end else begin
				if (desc.inc_src) begin
					if (ev.we == 0 && ev.addr >= desc.src_addr &&
						(ev.addr < (desc.src_addr + (desc.tot_sz*4)))) begin
						ret = desc_info;
						desc_info.num_reads++;
					end
				end else begin
					if (ev.we == 0 && ev.addr == desc.src_addr) begin
						ret = desc_info;
						desc_info.num_reads++;
					end 
				end
				 
				if (desc.inc_dst) begin
					if (ev.we == 1 && ev.addr >= desc.dest_addr && 
							(ev.addr < (desc.dest_addr + (desc.tot_sz*4)))) begin
						ret = desc_info;
						desc_info.num_writes++;
					end
				end else begin
					if (ev.we == 1 && ev.addr == desc.dest_addr) begin
						ret = desc_info;
						desc_info.num_writes++;
					end 
				end
			end
			
			if (ret != null) begin
				break;
			end  
		end
		
		return ret;
	endfunction 
	
	function void check_priorities(wb_dma_descriptor_sb_info target);
/*
		wb_dma_descriptor_sb_info d1, d2;
		wb_dma_descriptor_sb_info sl[$];
		
		if (m_last_write_ch_id == -1) begin
			m_last_write_ch_id = target.desc.channel;
		end else begin
			for (int i=0; i<m_active_descriptors.size(); i++) begin
				sl.push_back(m_active_descriptors[i]);
			end
			
			// Sort the descriptors by priority
			for (int i=0; i<sl.size(); i++) begin
				for (int j=i+1; j<sl.size(); j++) begin
					d1 = sl[i];
					d2 = sl[j];
					if (d1.desc.chn_priority > d2.desc.chn_priority) begin
						sl[i] = d2;
						sl[j] = d1;
					end 
				end 
			end
		end
 */
	endfunction 
	 
	/****************************************************************
	 * write_descriptor_start()
	 * 
	 * Called when the analysis port receives notification of a
	 * starting descriptor
	 ****************************************************************/
	function void write_descriptor_start(wb_dma_descriptor desc);
		wb_dma_descriptor_sb_info desc_info = new;
		
		desc_info.last_acc_write = 1;
		
		desc_info.desc = wb_dma_descriptor'(desc.clone());

		if (desc_info.desc.use_ed) begin
			for (int i=0; i<desc_info.desc.ll_desc.size(); i++) begin
				desc_info.exp_access_cnt += desc_info.desc.ll_desc[i].tot_sz; 
			end
			desc_info.next_read_address = desc_info.desc.ll_desc[0].src_addr;
			desc_info.next_write_address = desc_info.desc.ll_desc[0].dest_addr;
		end else begin
			desc_info.exp_access_cnt = desc_info.desc.tot_sz;
			desc_info.next_read_address = desc_info.desc.src_addr;
			desc_info.next_write_address = desc_info.desc.dest_addr;
		end 
		
		m_active_descriptors.push_back(desc_info);
	endfunction 

	
	function void write_descriptor_complete(wb_dma_desc_complete_ev ev);
		wb_dma_descriptor_sb_info 	desc_info = null;
		
		uvm_report_info(m_name, $psprintf("Descriptor on channel %0d complete",
			ev.channel), UVM_FULL);
			
		for (int i=0; i<m_active_descriptors.size(); i++) begin
			if (m_active_descriptors[i].desc.channel == ev.channel) begin
				desc_info = m_active_descriptors[i];
				m_active_descriptors.delete(i);
				break;
			end 
		end
		
		for (int i=0; i<m_stop_barrier.size(); i++) begin
			if (m_stop_barrier[i].desc.channel == ev.channel) begin
				m_stop_barrier.delete(i);
			end 
		end 
		
		if (desc_info != null) begin
			if (desc_info.num_reads != desc_info.exp_access_cnt ||
				desc_info.num_writes != desc_info.exp_access_cnt) begin
				uvm_report_error(m_name, $psprintf(
					"[FAIL] Expecting %0d reads/writes ; received %0d reads / %0d writes", 
					desc_info.exp_access_cnt, desc_info.num_reads, desc_info.num_writes));
			end
			
			m_total_descriptors++;
			uvm_report_info(m_name, $psprintf("[%0s] Descriptor %0d on channel %0d",
				(desc_info.pass)?"PASS":"FAIL", 
				m_total_descriptors, desc_info.desc.channel), UVM_LOW);	 
		end else begin
			uvm_report_error(m_name, "No matching descriptor");
		end 
	endfunction 
	
	function wb_dma_descriptor_sb_info find_ch_sb_info(int channel);
		
		for (int i=0; i<m_active_descriptors.size(); i++) begin
			if (m_active_descriptors[i].desc.channel == channel) begin
				return m_active_descriptors[i];
			end 
		end 
		return null;
	endfunction 
	
	
	function void write_handshake_ev(wb_dma_handshake_ev ev);
		wb_dma_descriptor_sb_info sb_info = find_ch_sb_info(ev.channel_id);
		wb_dma_ll_desc ll_desc;
		int sz_delta;
		
		if (ev.ev_type == Restart) begin
			uvm_report_info(m_name, $psprintf("Restart event on descriptor %0d of channel %0d ; adjust size by %0d",
				ev.descriptor_index, ev.channel_id, ev.words_transferred), UVM_MEDIUM);
				
			ll_desc = sb_info.desc.ll_desc[ev.descriptor_index];
			
			sb_info.ll_desc_idx = ev.descriptor_index;
			sb_info.ll_desc_reads = 0;
			sb_info.ll_desc_writes = 0;
			sb_info.next_read_address = ll_desc.src_addr;
			sb_info.next_write_address = ll_desc.dest_addr;
			
			sb_info.exp_access_cnt += ev.words_transferred;
		end if (ev.ev_type == ForceNext) begin
			ll_desc = sb_info.desc.ll_desc[ev.descriptor_index];
			sz_delta = (ll_desc.tot_sz - ev.words_transferred);
			
			uvm_report_info(m_name, $psprintf("ForceNext event on descriptor %0d of channel %0d ; adjust size by %0d",
				ev.descriptor_index, ev.channel_id, sz_delta), UVM_MEDIUM);
			uvm_report_info(m_name, $psprintf("    %0d words transferred (%0d) ; tot_sz %0d ; delta %0d",
				ev.words_transferred, sb_info.ll_desc_reads, ll_desc.tot_sz, sz_delta), UVM_MEDIUM);
			
			// Only move to the next descriptor if we've actually started
			// work on it. With very-small transfers, the scoreboard will have
			// already adjusted the pointers to the next descriptor 
			if (sb_info.ll_desc_reads > 0 && sb_info.ll_desc_writes > 0) begin
				sb_info.ll_desc_idx++;
			end 
			
			if (sb_info.ll_desc_idx < sb_info.desc.ll_desc.size()) begin
				ll_desc = sb_info.desc.ll_desc[sb_info.ll_desc_idx];
				sb_info.ll_desc_reads = 0;
				sb_info.ll_desc_writes = 0;
				sb_info.next_read_address = ll_desc.src_addr;
				sb_info.next_write_address = ll_desc.dest_addr;
			
				sb_info.exp_access_cnt -= sz_delta;
			end else begin
				uvm_report_fatal(m_name, $psprintf("ll_desc_idx out-of-bounds - %0d with ll_length=%0d",
					sb_info.ll_desc_idx, sb_info.desc.ll_desc.size()));
			end 
		end 
		
	endfunction 
	
    virtual task stop(string ph_name);
		bit sync_end;
    	super.stop(ph_name);
		
		// Allow the end-test synchronization to be skipped
		if (!$value$plusargs("SCOREBOARD_END_SYNC=%d", sync_end)) begin
			sync_end = 1;
		end
		
		if (sync_end) begin
			uvm_report_info(m_name, $psprintf("Stop Request: %0s", ph_name), UVM_LOW);
			uvm_report_info(m_name, $psprintf("Currently %0d active descriptors", 
				m_active_descriptors.size()), UVM_LOW);
		
			// Add all the in-flight descriptors
			for (int i=0; i<m_active_descriptors.size(); i++) begin
				m_stop_barrier.push_back(m_active_descriptors[i]);
			end 
		
			wait(m_stop_barrier.size() == 0);
		
			uvm_report_info(m_name,  "Scoreboard stop request acknowledged", UVM_LOW);
		end
    endtask
	
endclass 

`endif /* INCLUDED_WB_DMA_SCOREBOARD_SVH */

