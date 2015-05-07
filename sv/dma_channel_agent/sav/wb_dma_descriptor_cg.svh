/****************************************************************************
 * dma_channel_transfer_desc_cg.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * Stimulus coverage for the DMA descriptor
 ****************************************************************************/

class dma_channel_transfer_desc_cg;
	
	dma_channel_transfer_desc					m_desc;
	wb_dma_ll_desc						m_ll_desc;
	
	int									m_count;
	bit									m_report_coverage;

	covergroup cov;
		chn_priority	: coverpoint m_desc.chn_priority;

		use_ed			: coverpoint m_desc.use_ed;
		ars 			: coverpoint m_ll_desc.ars iff (m_desc.use_ed);
		mode 			: coverpoint m_desc.mode;
		force_next		: coverpoint m_ll_desc.force_next iff (m_desc.use_ed);

		// Cross of the restart and force-next operations		
		ars_force_next : cross ars, force_next iff (m_desc.use_ed && m_desc.mode);
		
		inc_src_int : coverpoint m_desc.inc_src iff (!m_desc.use_ed);
		inc_dst_int : coverpoint m_desc.inc_dst iff (!m_desc.use_ed);

		inc_src_ext : coverpoint m_ll_desc.inc_src iff (m_desc.use_ed);
		inc_dst_ext : coverpoint m_ll_desc.inc_dst iff (m_desc.use_ed);

		src_mask : coverpoint m_desc.src_addr_mask_bits iff (!m_desc.use_ed) {
			bins src_addr_mask_bits[] = {[4:6]};
		}
		
		dst_mask : coverpoint m_desc.dst_addr_mask_bits iff (!m_desc.use_ed) {
			bins dst_addr_mask_bits[] = {[4:6]};
		}

		// Source/Destination bus
		src_sel_int  : coverpoint m_desc.src_sel iff (m_desc.use_ed);
		dst_sel_int  : coverpoint m_desc.dst_sel iff (m_desc.use_ed);

		src_sel_ext  : coverpoint m_ll_desc.src_sel iff (m_desc.use_ed);
		dst_sel_ext  : coverpoint m_ll_desc.dst_sel iff (m_desc.use_ed);

		// Combinations of src/dst selection, increment, address masks, 
		// and mode for internal descriptors
		inc_sel_src_dst_mask_mode_int_cross : cross 
				src_sel_int, dst_sel_int, inc_src_int, inc_dst_int, 
				src_mask, dst_mask, mode iff (!m_desc.use_ed) {
			// Declare mask sizes >4 to be ignored for non-incrementing src/dst
			ignore_bins invalid_mask = 
				(binsof(inc_src_int) intersect {0} && 
					binsof(src_mask.src_addr_mask_bits) intersect {[5:$]}) ||
				(binsof(inc_dst_int) intersect {0} && 
					binsof(dst_mask.dst_addr_mask_bits) intersect {[5:$]});
		}	

		// Combinations of src/dst selection, increment, and mode for
		// external descriptors
		inc_sel_src_dst_mode_ext_cross : cross 
				src_sel_ext, dst_sel_ext, inc_src_ext, inc_dst_ext, 
				mode iff (m_desc.use_ed);

		tot_sz_int			: coverpoint m_desc.tot_sz iff (!m_desc.use_ed) {
			bins small_sz[]        = {1, 2, 3, 4};
			bins medium_5_514      = {[5:514]};
			bins medium_515_1025   = {[515:1025]};
			bins medium_1026_1536  = {[1026:1536]};
			bins medium_1537_2047  = {[1537:2047]};
			bins medium_2048_2558  = {[2048:2558]};
			bins medium_2559_3069  = {[2559:3069]};
			bins medium_3070_3580  = {[3070:3580]};
			bins medium_3581_4091  = {[3581:4091]};
			bins large_sz[]    = {4092, 4093, 4094, 4095};
		}
		
		// Total size for external-descriptor transfers with
		// hardware handshaking
		tot_sz_ext			: coverpoint m_ll_desc.tot_sz iff (m_desc.use_ed) {
			bins small_sz[]        = {1, 2, 3, 4};
			bins medium_5_514      = {[5:514]};
			bins medium_515_1025   = {[515:1025]};
			bins medium_1026_1536  = {[1026:1536]};
			bins medium_1537_2047  = {[1537:2047]};
			bins medium_2048_2558  = {[2048:2558]};
			bins medium_2559_3069  = {[2559:3069]};
			bins medium_3070_3580  = {[3070:3580]};
			bins medium_3581_4091  = {[3581:4091]};
			bins large_sz[]    = {4092, 4093, 4094, 4095};
		}

		chk_sz_int			: coverpoint m_desc.chk_sz iff (!m_desc.use_ed) {
			bins small_sz[]       = {0, 1, 2, 3};
			bins medium_4_66      = {[4:66]};
			bins medium_67_129    = {[67:129]};
			bins medium_130_192   = {[130:192]};
			bins medium_193_255   = {[193:255]};
			bins medium_256_318   = {[256:318]};
			bins medium_319_381   = {[319:381]};
			bins medium_382_444   = {[382:444]};
			bins medium_445_507   = {[445:507]};
			bins large_sz[]       = {508, 509, 510, 511};
		}

		chk_sz_ext			: coverpoint m_desc.chk_sz iff (m_desc.use_ed) {
			bins small_sz[]       = {0, 1, 2, 3};
			bins medium_4_66      = {[4:66]};
			bins medium_67_129    = {[67:129]};
			bins medium_130_192   = {[130:192]};
			bins medium_193_255   = {[193:255]};
			bins medium_256_318   = {[256:318]};
			bins medium_319_381   = {[319:381]};
			bins medium_382_444   = {[382:444]};
			bins medium_445_507   = {[445:507]};
			bins large_sz[]       = {508, 509, 510, 511};
		}
		
		chk_tot_sz_ext_cross : cross chk_sz_ext, tot_sz_ext, mode iff (m_desc.use_ed);
		chk_tot_sz_int_cross : cross chk_sz_int, tot_sz_int iff (!m_desc.use_ed);
		
		// Ensure that all lengths of descriptor chains are produced
		ll_length	: coverpoint m_desc.ll_desc.size() iff (m_desc.use_ed) {
			bins ll_length[] = {[1:8]};
		}
	endgroup
	
	function new();
		cov = new;
		
		if (!$value$plusargs("REPORT_COVERAGE=%d", m_report_coverage)) begin
			m_report_coverage = 0;
		end 
	endfunction 


	function void sample(dma_channel_transfer_desc desc);
		real ars_force_next, inc_sel_src_dst_mask_mode_int;
		real inc_sel_src_dst_mode_ext, tot_sz_int, tot_sz_ext;
		real chk_sz_int, chk_sz_ext, chk_tot_sz_ext, chk_tot_sz_int;
		real ll_length, total;
		m_desc = desc;
		
		if (desc.use_ed) begin
			for (int i=0; i<m_desc.ll_desc.size(); i++) begin
				m_ll_desc = m_desc.ll_desc[i];
				cov.sample();
			end
		end else begin
			cov.sample();
		end
		
		m_count++;
		
		if (m_report_coverage) begin
			if ((m_count < 1000 && !(m_count % 10)) ||
				(m_count < 10000 && !(m_count % 100)) ||
				!(m_count % 1000)) begin
				ars_force_next = cov.ars_force_next.get_coverage();
				inc_sel_src_dst_mask_mode_int = 
					cov.inc_sel_src_dst_mask_mode_int_cross.get_coverage();
				inc_sel_src_dst_mode_ext =
					cov.inc_sel_src_dst_mode_ext_cross.get_coverage();
				tot_sz_int = cov.tot_sz_int.get_coverage();
				tot_sz_ext = cov.tot_sz_ext.get_coverage();
				chk_sz_int = cov.chk_sz_int.get_coverage();
				chk_sz_ext = cov.chk_sz_ext.get_coverage();
				chk_tot_sz_int = cov.chk_tot_sz_int_cross.get_coverage();
				chk_tot_sz_ext = cov.chk_tot_sz_ext_cross.get_coverage();
				ll_length = cov.ll_length.get_coverage();
                total = cov.get_coverage();
				
				$display("[COVERAGE] %0d total=%f ars_force_next=%f inc_sel_src_dst_mask_mode_int=%f inc_sel_src_dst_mode_ext=%f tot_sz_int=%f tot_sz_ext=%f chk_sz_int=%f chk_sz_ext=%f chk_tot_sz_int=%f chk_tot_sz_ext=%f ll_length=%f",
					m_count, total, ars_force_next, inc_sel_src_dst_mask_mode_int, inc_sel_src_dst_mode_ext,
					tot_sz_int, tot_sz_ext, chk_sz_int, chk_sz_ext, 
					chk_tot_sz_int, chk_tot_sz_ext, ll_length);

                if (total >= 100) begin
                    global_stop_request();
                end
			end  
		end 
	endfunction
	
endclass 

