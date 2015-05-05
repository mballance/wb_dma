/****************************************************************************
 * wb_dma_descriptor_driver.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 *
 * Driver that programs the DMA controller based on a DMA descriptor
 ****************************************************************************/
`ifndef INCLUDED_WB_DMA_DESCRIPTOR_DRIVER_SVH
`define INCLUDED_WB_DMA_DESCRIPTOR_DRIVER_SVH

`wb_dma_analysis_closure_imp_t(drv_descriptor_complete_analysis_export_t, 
	wb_dma_desc_complete_ev, wb_dma_descriptor_driver, descriptor_complete)

class wb_dma_descriptor_driver extends uvm_driver #(wb_dma_descriptor);
	
	uvm_analysis_port #(wb_dma_descriptor)	dma_desc_analysis_port;
	drv_descriptor_complete_analysis_export_t	descriptor_complete_analysis_export;
	
	int										m_channel_id;
	int										m_count = 1;
	wb_dma_memory_mgr						m_mem_mgr;
	wb_dma_timer							m_timer;
	bit										m_descriptor_complete_ev;
	
	static wb_dma_descriptor_cg				m_cov;
	static wb_dma_descriptor_cg_small		m_cov_small;
	static wb_dma_descriptor_cg_demo		m_cov_demo;
	bit										m_use_small_cov;
	bit										m_use_demo_cov;
	
	
	function new(string inst_name, uvm_component parent);
		super.new(inst_name, parent);
		
		dma_desc_analysis_port = new("dma_desc_analysis_port", this);
		descriptor_complete_analysis_export = new("descriptor_complete_analysis_port", this);
		
		if (!$value$plusargs("SMALL_COVERAGE=%d", m_use_small_cov)) begin
			m_use_small_cov = 0;
		end 
		if (!$value$plusargs("DEMO_COVERAGE=%d", m_use_demo_cov)) begin
			m_use_demo_cov = 0;
		end 
		
		if (m_use_small_cov) begin
			if (m_cov_small == null) begin
				m_cov_small = new;
			end 
		end else if (m_use_demo_cov) begin
			if (m_cov_demo == null) begin
				m_cov_demo = new;
			end 
		end else begin
			if (m_cov == null) begin
				m_cov = new;
			end
		end 
	endfunction
	
	function void init(
		int												channel_id,
		wb_dma_memory_mgr								mem_mgr,
		wb_dma_timer									timer);
		m_channel_id = channel_id;
		m_mem_mgr    = mem_mgr;
		m_timer		 = timer;
	endfunction 

	task run();
		CH_CSR_t            ch_csr;
		CH_LL_CSR_t			ch_ll_csr;
		CH_SZ_t             ch_sz;
		CH_Am_t             ch_am;
		CH_AMm_t            ch_amm;
		string				mem_info;
		
		wb_dma_descriptor	desc;
		bit [31:0]			base_addr = 
			'hb000_0000 + 'h20 + (m_channel_id * 'h20);
		bit [31:0]			data_t;
		bit [31:0]			ll_addr;

		forever begin
			seq_item_port.get_next_item(desc);
			
			// Update the covergroup
			if (m_use_small_cov) begin
				m_cov_small.sample(desc);
			end else if (m_use_demo_cov) begin
				m_cov_demo.sample(desc);
			end else begin
				m_cov.sample(desc);
			end 
			
			desc.channel = m_channel_id;
			
			uvm_report_info("DESC DRV", $psprintf(
				"Channel %0d begin descriptor %0d", m_channel_id, m_count), UVM_FULL);
					
			if (desc.use_ed) begin
				for (int i=0; i<desc.ll_desc.size(); i++) begin
					wb_dma_ll_desc ll_desc = desc.ll_desc[i];
				
`ifndef DR_0002
					if (ll_desc.tot_sz == 0) begin
						uvm_report_info("DESC DRV", "Changing tot_sz from 0 to 1");
						ll_desc.tot_sz = 1;
					end
`endif
				
					$sformat(mem_info, "[%0t] Source memory for channel %0d descriptor %0d",
						$time, m_channel_id, m_count);
					ll_desc.src_addr = setup_xfer_block(1, ll_desc.inc_src, 
						ll_desc.tot_sz, 0, mem_info);
			
					$sformat(mem_info, "[%0t] Dest memory for channel %0d descriptor %0d",
						$time, m_channel_id, m_count);
					ll_desc.dest_addr = setup_xfer_block(0, ll_desc.inc_dst, 
						ll_desc.tot_sz, 0, mem_info);
				end 
			end else begin
`ifndef DR_0002
				if (desc.tot_sz == 0) begin
					uvm_report_info("DESC DRV", "Changing tot_sz from 0 to 1");
					desc.tot_sz = 1;
				end
`endif
				
				$sformat(mem_info, "[%0t] Source memory for channel %0d descriptor %0d",
						$time, m_channel_id, m_count);
				desc.src_addr = setup_xfer_block(1, desc.inc_src, desc.tot_sz, 
						(1 << (desc.src_addr_mask_bits-2)), mem_info);
			
				$sformat(mem_info, "[%0t] Dest memory for channel %0d descriptor %0d",
						$time, m_channel_id, m_count);
				desc.dest_addr = setup_xfer_block(0, desc.inc_dst, desc.tot_sz,
						(1 << (desc.dst_addr_mask_bits-2)), mem_info);
			end  

			ch_sz = 0;
			ch_sz.chk_sz = desc.chk_sz;

			ch_csr = 0;
			
			if (desc.use_ed) begin
				
				// Create a memory block for the descriptor
				$sformat(mem_info, "[%0t] Descriptor linked-list memory for channel %0d descriptor %0d",
						$time, m_channel_id, m_count);

				ll_addr = m_mem_mgr.malloc((4 * desc.ll_desc.size()), mem_info);
				 
				uvm_report_info("DESC DRV", $psprintf("Descriptor block addr: 'h%08h .. 'h%08h", 
					ll_addr, (ll_addr + 16* desc.ll_desc.size() - 1)), UVM_FULL);
				desc.ed_addr = ll_addr;
				
				// Write the linked-list pointer
				m_mem_mgr.access(base_addr + 'h18, 1, ll_addr);
				 
				for (int i=0; i<desc.ll_desc.size(); i++) begin
					wb_dma_ll_desc ll_desc = desc.ll_desc[i];
					ch_ll_csr = 0;
					
					ch_ll_csr.EOL   		= (i+1 >= desc.ll_desc.size());
					ch_ll_csr.inc_src 		= ll_desc.inc_src;
					ch_ll_csr.inc_dst 		= ll_desc.inc_dst;
					ch_ll_csr.src_sel 		= ll_desc.src_sel;
					ch_ll_csr.dst_sel 		= ll_desc.dst_sel;
					ch_ll_csr.tot_sz        = (ll_desc.tot_sz);
					
					m_mem_mgr.access(ll_addr, 1, ch_ll_csr);

					m_mem_mgr.access(ll_addr + 'h4, 1, ll_desc.src_addr);
					m_mem_mgr.access(ll_addr + 'h8, 1, ll_desc.dest_addr);
					
					if (i+1 < desc.ll_desc.size()) begin
						// write the address of the next descriptor
						data_t = ll_addr+'h10;
						m_mem_mgr.access(ll_addr+'h0C, 1, data_t);
					end 
					
					ll_addr += 'h10; // Move to next descriptor
				end
				uvm_report_info("DESC DRV", "Descriptor ", UVM_MEDIUM);
				if (get_report_verbosity_level() >= UVM_MEDIUM) begin
					desc.print();
				end 
			end else begin
				uvm_report_info("DESC DRV", "Descriptor ", UVM_MEDIUM);
				if (get_report_verbosity_level() >= UVM_MEDIUM) begin
					desc.print();
				end 
				
				ch_sz.tot_sz = desc.tot_sz;
				
				// Source address. The memory manager returns byte addresses
				ch_am.address = desc.src_addr[31:2];
				m_mem_mgr.access(base_addr + 8, 1, ch_am);

				// Destination address
				ch_am.address = desc.dest_addr[31:2];
				m_mem_mgr.access(base_addr + 16, 1, ch_am);
				
				// Fill in the CH_CSR information appropriate for
				// an internal descriptor
				ch_csr.dst_sel      = desc.dst_sel;
				ch_csr.src_sel      = desc.src_sel;
				ch_csr.inc_dst      = desc.inc_dst;
				ch_csr.inc_src      = desc.inc_src;
			end
			
			// +12 is the src mask
			ch_amm = ('hFFFF_FFFF << desc.src_addr_mask_bits);
			uvm_report_info("DESC DRV", $psprintf("SRC MASK: 'h%08h", ch_amm), UVM_FULL);
			m_mem_mgr.access(base_addr + 12, 1, ch_amm);

			// +20 is the dest mask
			ch_amm = ('hFFFF_FFFF << desc.dst_addr_mask_bits);
			uvm_report_info("DESC DRV", $psprintf("DST MASK: 'h%08h", ch_amm), UVM_FULL);
			m_mem_mgr.access(base_addr + 20, 1, ch_amm);

			
			// Notify others that we've initiated a DMA descriptor 
			dma_desc_analysis_port.write(desc);
			
			m_mem_mgr.access(base_addr + 'h04, 1, ch_sz);
			
			ch_csr.ch_en        = 1;
			
			ch_csr.ine_chk_done = desc.ine_chk_done;
			ch_csr.ine_done     = desc.ine_done;
			ch_csr.ine_err      = desc.ine_err;
			
			// Always enable hardware restart, even though it will
			// only be used for external descriptors
			ch_csr.rest_en		= 1;
			
			ch_csr.mode         = desc.mode;
			ch_csr.ars          = 0;
			ch_csr.use_ed       = desc.use_ed;
			ch_csr.sz_wb        = 1;
			ch_csr.stop         = 0;
			ch_csr.chn_priority = desc.chn_priority;

			m_mem_mgr.access(base_addr, 1, ch_csr);
			
			// Wait for a message from the SW indicating that
			// the descriptor has completed
			wait(m_descriptor_complete_ev == 1);
			m_descriptor_complete_ev = 0;

			seq_item_port.item_done(desc);
			
			
			if (desc.use_ed) begin
				for (int i=0; i<desc.ll_desc.size(); i++) begin
					m_mem_mgr.free(desc.ll_desc[i].src_addr);
					m_mem_mgr.free(desc.ll_desc[i].dest_addr);
				end 
				m_mem_mgr.free(desc.ed_addr);
			end else begin
				m_mem_mgr.free(desc.src_addr);
				m_mem_mgr.free(desc.dest_addr);
			end 
			
			m_count++;
		end 
	endtask
	
	/****************************************************************
	 * setup_xfer_block()
	 * 
	 * Allocates memory for a transfer block based on the src/dst
	 * transfer configuration
	 ****************************************************************/
	function bit [31:0] setup_xfer_block(
		bit					src_mem,
		bit					inc_addr,
		bit [31:0]			tot_sz,
		bit [31:0]			wrap_sz,
		string				mem_info);
		bit [31:0] addr, data_t;
		
		if (inc_addr) begin
			uvm_report_info(m_name, $psprintf("WrapSz=%0d TotSz=%0d", wrap_sz, tot_sz), UVM_FULL);
			addr = m_mem_mgr.malloc(tot_sz, mem_info,(wrap_sz>0)?wrap_sz:1);
				
			if (wrap_sz > 0) begin
				uvm_report_info("ALIGN", $psprintf("Allocating %0d words aligned to %0d => 'h%08h",
					tot_sz, wrap_sz, addr), UVM_FULL);
			end 
			
			if (src_mem) begin
				for (int i=0; i<tot_sz; i++) begin
					data_t = ('hd000_0000 | (m_channel_id << 16) | (m_count << 8) | i);
					m_mem_mgr.direct_access(addr + (i*4), 1, data_t);
				end 
			end 
		end else begin
			addr = m_mem_mgr.malloc(1, mem_info);
			if (src_mem) begin
				data_t = ('hd000_0000 | (m_channel_id << 16) | (m_count << 8) | 1);
				m_mem_mgr.direct_access(addr, 1, data_t);
			end 
		end 
		
		return addr;
	endfunction 
	
	/****************************************************************
	 * descriptor_complete()
	 * 
	 * Analysis-port event function called when a descriptor 
	 * completes
	 ****************************************************************/
	function void descriptor_complete(wb_dma_desc_complete_ev ev);
		if (ev.channel == m_channel_id) begin
			uvm_report_info("DESC DRV", "Descriptor Complete", UVM_FULL);
			m_descriptor_complete_ev = 1;
		end
	endfunction 
	
endclass 

 `endif /* INCLUDED_WB_DMA_DESCRIPTOR_DRIVER_SVH */
