/****************************************************************************
 * wb_dma_memory_mgr.svh
 *
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * Memory manager for the testbench. Models the memory used by the 
 * testbench for source and destination memory. Manages allocation of this
 * testbench memory. Channels memory-access requests from the testbench
 * and memory-access requests from the DMA engine to the correct memory
 * region.
 * 
 ****************************************************************************/
`ifndef INCLUDED_WB_DMA_MEMORY_MGR_SVH
`define INCLUDED_WB_DMA_MEMORY_MGR_SVH

`undef DEBUG_MEM_MGR
`undef DEBUG_MEM_MGR_VERBOSE

// class used to manage reserved memory
class wb_dma_mem_region;
	string					desc;
	bit [31:0]				addr;
	bit [31:0]				size;
	bit [31:0]				storage[];
	bit						freed;
endclass

class wb_dma_memory_mgr extends uvm_component;
	`uvm_component_utils(wb_dma_memory_mgr)
	
	uvm_analysis_port #(wb_dma_mem_ev)					mem_analysis_port;
	
	uvm_sequencer #(wb_master_req, wb_master_rsp)		m_m0_sequencer;
	uvm_sequencer #(wb_master_req, wb_master_rsp)		m_m1_sequencer;
	
	bit [31:0]											m_mem_base;
	bit [31:0]											m_mem_size;
	wb_dma_mem_region									m_map[$];
	wb_dma_mem_region									m_free_list[$];
	
	// Pool of R/W sequences
	wb_simple_rw_seq 									m_req_pool[$];
	semaphore											m_access_sem;
	wb_dma_mem_ev										m_mem_ev;
	
	
	function new(string name, uvm_component parent);
		super.new(name, parent);
		
		m_mem_base = 0;
		m_mem_size = 1024 * 1024 * 32 * 4;
		mem_analysis_port = new("mem_analysis_port", this);
		
		m_access_sem = new(1);
		
		m_mem_ev = wb_dma_mem_ev::type_id::create("ev");
	endfunction
	
	function void init(
		uvm_sequencer #(wb_master_req, wb_master_rsp) m0_seqr,
		uvm_sequencer #(wb_master_req, wb_master_rsp) m1_seqr);
		m_m0_sequencer = m0_seqr;
		m_m1_sequencer = m1_seqr;
	endfunction
	
	/**
	 * Allocate a memory address given the block size (in words)
	 * 
	 * align must be power of 2
	 */
	function bit [31:0] malloc(
		bit [31:0]				size,
		string					desc,
		bit [31:0]				align=1);
		wb_dma_mem_region region = new, region_t;
		bit [31:0] align_mask = align-1;
		bit [31:0] align_addr;
		
`ifdef DEBUG_MEM_MGR
		uvm_report_info("MEM_MGR", $psprintf("malloc(%0d) align=%0d align_mask='h%08h %0s", 
			size, align, align_mask, desc));
`endif
		
		region.addr    = m_mem_base;
		region.size    = size;
		region.desc    = desc;
		region.storage = new[size];
		
		if (m_map.size() == 0) begin
`ifdef DEBUG_MEM_MGR
			uvm_report_info("MEM_MGR", "    first alloc");
`endif
			m_map.push_back(region);
		end else begin 
			for (int i=0; i<m_map.size(); i++) begin
`ifdef DEBUG_MEM_MGR
				uvm_report_info("MEM_MGR", 
					$psprintf("    region 'h%0h .. 'h%0h",
						(m_map[i].addr << 2), ((m_map[i].addr+m_map[i].size-1) << 2)));
`endif
				// Align the address as specified
				if (align > 1) begin
`ifdef DEBUG_MEM_MGR
					uvm_report_info("MEM_MGR", $psprintf("    pre-align addr='h%08h", region.addr));
`endif
					region.addr = (region.addr + (align - (region.addr & align_mask)));
`ifdef DEBUG_MEM_MGR
					uvm_report_info("MEM_MGR", $psprintf("    post-align addr='h%08h", region.addr));
`endif
				end
				if (m_map[i].addr > region.addr &&
						(region.addr + region.size) <= m_map[i].addr) begin
					$sformat(region.desc, "%s ('h%08h .. 'h%08h)", desc,
						(region.addr << 2), ((region.addr+region.size-1) << 2)); 
					if (get_region_desc(region.addr << 2, desc)) begin
						uvm_report_error("MEM_MGR", 
							$psprintf("Allocation fail: Address 'h%0h already allocated", (region.addr << 2)));
					end
							
					m_map.insert(i, region);
`ifdef DEBUG_MEM_MGR
					uvm_report_info("MEM_MGR", "    insert region here");
`endif
					break;
				end else begin
					// Otherwise, update the address
					region.addr = m_map[i].addr + m_map[i].size;

					if (align > 1) begin
						region.addr = (region.addr + (align - (region.addr & align_mask)));
					end
					
					if (i+1 >= m_map.size()) begin
						$sformat(region.desc, "%s ('h%08h .. 'h%08h)", desc,
							(region.addr << 2), ((region.addr+region.size-1) << 2)); 
						if (get_region_desc(region.addr << 2, desc)) begin
							uvm_report_error("MEM_MGR", 
								$psprintf("Allocation fail: Address 'h%0h already allocated", (region.addr << 2)));
						end
						m_map.push_back(region);
`ifdef DEBUG_MEM_MGR
						uvm_report_info("MEM_MGR", "    add at end");
`endif
						break;
					end
				end  
			end
		end

`ifdef DEBUG_MEM_MGR
		uvm_report_info("MEM_MGR", $psprintf("malloc returns 'h%0h", (region.addr << 2)));
`endif

		if ((region.addr+region.size) >= (m_mem_base + m_mem_size)) begin
			uvm_report_error("MEM_MGR", $psprintf("Memory allocation of %0d words (%s) failed", 
				size, desc));
		end
				
		return region.addr << 2;
	endfunction
	
	/**
	 * Free a memory block given the address
	 */
	function void free(bit [31:0] addr);
		bit found = 0;
		wb_dma_mem_region region = null;
		
		for (int i=0; i<m_map.size(); i++) begin
			if (m_map[i].addr == (addr >> 2)) begin
				region = m_map[i];
				break;
			end 
		end
		
		if (region != null) begin
			m_free_list.push_back(region);
			region.freed = 1;
		end
		
		if (m_free_list.size() >= 4) begin
			region = m_free_list.pop_front();
			do_free(region);
		end   
	endfunction 
	
	function void do_free(wb_dma_mem_region region);
		bit found = 0;
		
		for (int i=0; i<m_map.size(); i++) begin
			if (m_map[i].addr == region.addr) begin
				found = 1;
				m_map.delete(i);
				break;
			end 
		end 
	endfunction
	
	function wb_dma_mem_region find_mem_region(bit [31:0] addr);
		addr = addr[31:2]; // page-align
		
		for (int i=0; i<m_map.size(); i++) begin
			if ((addr >= m_map[i].addr) && 
				(addr < (m_map[i].addr + m_map[i].size))) begin
				return m_map[i];
			end 
		end
		
		return null;
	endfunction 
	
	function bit get_region_desc(bit [31:0] addr, output string desc);
		addr = addr[31:2]; // page-align
		
		for (int i=0; i<m_map.size(); i++) begin
			if ((addr >= m_map[i].addr) && 
				(addr < (m_map[i].addr + m_map[i].size))) begin
				desc = m_map[i].desc;
				return 1;
			end 
		end
		
		for (int i=0; i<m_free_list.size(); i++) begin
			if ((addr >= m_free_list[i].addr) && 
				(addr < (m_free_list[i].addr + m_free_list[i].size))) begin
				desc = m_free_list[i].desc;
				return 1;
			end 
		end
		
		return 0;
	endfunction 
		 

	/**
	 * This function is called to perform a direct access
	 * to the memory
	 */
	function void direct_access(
		bit [31:0]			addr,
		bit					we,
		inout bit [31:0]	data);
		wb_dma_mem_region region;

		if (addr[1:0] != 0) begin
			uvm_report_error("MEM_MGR", 
				$psprintf("Access to 'h%h is not word aligned", addr));
		end 
		
		
		if ((addr & 'hb000_0000) == 'hb000_0000) begin
			uvm_report_error("MEM_MGR", $psprintf(
				"Attempt direct access to address 'h%0h in device space", addr));
			return;
		end else if (addr < (m_mem_base + m_mem_size)) begin
			region = find_mem_region(addr);
			
			if (region != null) begin
				if (region.freed) begin
					uvm_report_error("MEM_MGR",
						$psprintf("%0s to 'h%08h is to a freed region",
							(we)?"Write":"Read", addr));
				end
				addr = (addr[31:2] - region.addr);
				if (we) begin
					region.storage[addr] = data;
				end else begin
					data = region.storage[addr];
				end
			end else begin
				uvm_report_error("MEM_MGR", $psprintf(
					"%0s to 'h%08h is to an unmapped region", 
					(we)?"Write":"Read", addr));
			end  
		end else begin
			uvm_report_error("MEM_MGR", 
				$psprintf("Direct access to address 'h%h outside the memory space", addr));
		end

`ifdef DEBUG_MEM_MGR_VERBOSE
		 uvm_report_info("MEM_MGR", $psprintf("[Direct Access] %0s 'h%08h = 'h%08h", 
				(we)?"Write":"Read", addr << 2, data));
`endif
	endfunction

	
	
	/**
	 * Perform a memory access. If the address is
	 * mapped to the testbench, then perform the access directly.
	 * If not, then perform the access on interface 'ifc'
	 */
	task access(
		input bit [31:0]	addr,
		input bit			we,
		inout bit [31:0]	data,
		input bit			ifc=0);
		wb_simple_rw_seq	req;
		
		if (addr[1:0] != 0) begin
			uvm_report_error("MEM_MGR", 
				$psprintf("Access to 'h%h is not word aligned", addr));
		end 
		
		if ((addr & 'hb000_0000) == 'hb000_0000) begin
			m_access_sem.get(1);
			
			if (m_req_pool.size() == 0) begin
				req = wb_simple_rw_seq::type_id::create("req");
			end else begin
				req = m_req_pool.pop_back();
			end 
			
			req.addr 	= addr;
			req.rnw  	= ~we;
			req.data[0] = data;
			req.n_bytes = 4;
			
			if (ifc == 0) begin
				req.start(m_m0_sequencer);
			end else begin
				req.start(m_m1_sequencer);
			end
			
			if (we == 0)  begin
				data = req.data[0];
			end
			
			m_req_pool.push_back(req);
			
			m_access_sem.put(1);
		end else if (addr < (m_mem_base + m_mem_size)) begin
			direct_access(addr, we, data);
		end else begin
			uvm_report_error("MEM_MGR", 
				$psprintf("Access to address 'h%h outside the memory space", addr));
		end 
	endtask 
	
	/**
	 * This function is called by the slave sequences
	 * when they detect an access on the slave interfaces 
	 */
	function void bus_access(
		bit					ifc,
		bit [31:0]			addr,
		bit					we,
		inout bit [31:0]	data);
		
		if (addr[1:0] != 0) begin
			uvm_report_error("MEM_MGR", 
				$psprintf("Access to 'h%h is not word aligned", addr));
		end 
		m_mem_ev.ifc  = ifc;
		m_mem_ev.addr = addr;
		m_mem_ev.we 	= we;
		m_mem_ev.data = data;
		
		if (addr < (m_mem_base + m_mem_size)) begin
			direct_access(addr, we, data);
		end else begin
			uvm_report_error("MEM_MGR", 
				$psprintf("Bus Access to address 'h%h outside the memory space", addr));
		end

`ifdef DEBUG_MEM_MGR_VERBOSE
		uvm_report_info("MEM_MGR", $psprintf("[Bus Access] %0s 'h%08h = 'h%08h", 
				(we)?"Write":"Read", addr << 2, data));
`endif
		
		mem_analysis_port.write(m_mem_ev);
	endfunction
	
endclass 

`endif /* INCLUDED_WB_DMA_MEMORY_MGR_SVH */
