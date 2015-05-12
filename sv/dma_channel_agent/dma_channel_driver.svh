/****************************************************************************
 * dma_channel_driver.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 *
 * Driver that programs the DMA controller based on a DMA descriptor
 ****************************************************************************/

class dma_channel_driver extends uvm_driver #(dma_channel_transfer_desc);
	`uvm_component_utils(dma_channel_driver)
	
	typedef struct packed {
		bit [31:21]				reserved_1;
		bit						EOL; 		// 20
		bit						inc_src;	// 19
		bit						inc_dst;	// 18
		bit						src_sel;	// 17
		bit						dst_sel;	// 16
		bit [15:12]				reserved_2;
		bit [11:0]				tot_sz;
	} CH_LL_CSR_t;		
	
	
	uvm_analysis_port #(dma_channel_transfer_desc)						dma_desc_analysis_port;
	uvm_analysis_imp #(dma_transfer_complete_ev, dma_channel_driver)	dma_transfer_complete_exp;
	
	int										m_channel_id;
	int										m_count = 1;
	memory_mgr								m_mem_mgr;
	dma_reg_block							m_dma_regs;
	timer									m_timer;
	dma_channel_reg							m_channel_regs;
	event									m_descriptor_complete_ev;
	
	function new(string inst_name, uvm_component parent);
		super.new(inst_name, parent);
		
		dma_desc_analysis_port = new("dma_desc_analysis_port", this);
		dma_transfer_complete_exp = new("dma_transfer_complete_exp", this);
	endfunction
	

	/**
	 * Function: build_phase
	 *
	 * Override from class 
	 */
	virtual function void build_phase(input uvm_phase phase);
		void'(get_config_int("channel_id", m_channel_id));
		void'(uvm_config_db #(memory_mgr)::get(this, "", "memory_mgr", m_mem_mgr));
		void'(uvm_config_db #(timer)::get(this, "", "timer", m_timer));
		void'(uvm_config_db #(dma_reg_block)::get(this, "", "dma_regs", m_dma_regs));
		
		m_channel_regs = m_dma_regs.CH[m_channel_id];
	endfunction

	/**
	 * Function: connect_phase
	 *
	 * Override from class 
	 */
	virtual function void connect_phase(input uvm_phase phase);

	endfunction

	
	function void init(
		int										channel_id,
		memory_mgr								mem_mgr,
		timer									timer);
		m_channel_id = channel_id;
		m_mem_mgr    = mem_mgr;
		m_timer		 = timer;
	endfunction 

	task run_phase(uvm_phase phase);
		// TODO: update driver implementation
		CH_LL_CSR_t			ch_ll_csr;
		string				mem_info;
		uvm_status_e		status;
		
		dma_channel_transfer_desc	desc;
		bit [31:0]			data_t;
		bit [31:0]			ll_addr;

		forever begin
			seq_item_port.get_next_item(desc);
			
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

			m_channel_regs.SZ.CHK_SZ.set(desc.chk_sz);

			if (desc.use_ed) begin
				
				// Create a memory block for the descriptor
				$sformat(mem_info, "[%0t] Descriptor linked-list memory for channel %0d descriptor %0d",
						$time, m_channel_id, m_count);

				ll_addr = m_mem_mgr.malloc((4 * desc.ll_desc.size()), mem_info);
				 
				uvm_report_info("DESC DRV", $psprintf("Descriptor block addr: 'h%08h .. 'h%08h", 
					ll_addr, (ll_addr + 16* desc.ll_desc.size() - 1)), UVM_FULL);
				desc.ed_addr = ll_addr;
				
				// Write the linked-list pointer
				m_channel_regs.DESC.ADDR.set(ll_addr[31:2]);
				m_channel_regs.DESC.update(status);
				 
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
				
				m_channel_regs.SZ.TOT_SZ.set(desc.tot_sz);
				
				// Source address. The memory manager returns byte addresses
				m_channel_regs.SRC.ADDR.set(desc.src_addr[31:2]);
				m_channel_regs.SRC.update(status);

				// Destination address
				m_channel_regs.DST.ADDR.set(desc.dest_addr[31:2]);
				m_channel_regs.DST.update(status);
				
				// Fill in the CH_CSR information appropriate for
				// an internal descriptor
				m_channel_regs.CSR.DST_SEL.set(desc.dst_sel);
				m_channel_regs.CSR.SRC_SEL.set(desc.src_sel);
				m_channel_regs.CSR.INC_DST.set(desc.inc_dst);
				m_channel_regs.CSR.INC_SRC.set(desc.inc_src);
			end
			
			// +12 is the src mask
//			ch_amm = ('hFFFF_FFFF << desc.src_addr_mask_bits);
//			uvm_report_info("DESC DRV", $psprintf("SRC MASK: 'h%08h", ch_amm), UVM_FULL);
//			m_mem_mgr.access(base_addr + 12, 1, ch_amm);
//
//			// +20 is the dest mask
//			ch_amm = ('hFFFF_FFFF << desc.dst_addr_mask_bits);
//			uvm_report_info("DESC DRV", $psprintf("DST MASK: 'h%08h", ch_amm), UVM_FULL);
//			m_mem_mgr.access(base_addr + 20, 1, ch_amm);

			
			// Notify others that we've initiated a DMA descriptor 
			dma_desc_analysis_port.write(desc);
	
			m_channel_regs.SZ.update(status);
		
			m_channel_regs.CSR.INE_CHK_DONE.set(desc.ine_chk_done);
			m_channel_regs.CSR.INE_DONE.set(desc.ine_done);
			m_channel_regs.CSR.INE_ERR.set(desc.ine_err);
			
			// Always enable hardware restart, even though it will
			// only be used for external descriptors
			m_channel_regs.CSR.REST_EN.set(1);
			
			m_channel_regs.CSR.MODE.set(desc.mode);
			m_channel_regs.CSR.ARS.set(0); // TODO: need to allow testing ARS
			m_channel_regs.CSR.USE_ED.set(desc.use_ed); 
			m_channel_regs.CSR.SZ_WB.set(1); // TODO: need to exercise both options
			m_channel_regs.CSR.STOP.set(0); 

			// Begin the transfer
			m_channel_regs.CSR.CH_EN.set(1);
			m_channel_regs.CSR.update(status);
			
			// Wait for a message from the SW indicating that
			// the descriptor has completed
			@m_descriptor_complete_ev;
		
			// Read back the CSR value
			m_channel_regs.CSR.mirror(status);
			
			$display("DONE: %0d", m_channel_regs.CSR.DONE.get()); 

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
	function void descriptor_complete(dma_transfer_complete_ev ev);
		if (ev.channel == m_channel_id) begin
			uvm_report_info("DESC DRV", "Descriptor Complete", UVM_FULL);
			->m_descriptor_complete_ev;
		end
	endfunction 
	
	function void write(dma_transfer_complete_ev t);
		if (t.channel == m_channel_id) begin
			->m_descriptor_complete_ev;
		end
	endfunction
	
endclass 

