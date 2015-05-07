/****************************************************************************
 * dma_channel_transfer_desc_cg_demo.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * Stimulus coverage for the DMA descriptor. This coverage is specialized
 * for the amount of time we typically have for simulation during a demo.
 ****************************************************************************/

class dma_channel_transfer_desc_cg_demo;
	
	dma_channel_transfer_desc					m_desc;
	wb_dma_ll_desc						m_ll_desc;
	
	int									m_count;
	bit									m_report_coverage;

	covergroup cov;
		chn_priority_cp	: coverpoint m_desc.chn_priority;

		inc_src_cp : coverpoint m_desc.inc_src;
		inc_dst_cp : coverpoint m_desc.inc_dst;

		// Source/Destination bus
		src_sel_cp  : coverpoint m_desc.src_sel;
		dst_sel_cp  : coverpoint m_desc.dst_sel;
		
		src_mask_cp : coverpoint m_desc.src_addr_mask_bits {
			bins src_addr_mask_bits[] = {[4:6]};
		}
		
		dst_mask_cp : coverpoint m_desc.dst_addr_mask_bits {
			bins dst_addr_mask_bits[] = {[4:6]};
		}
		

		// Combinations of src/dst selection, increment 
		inc_sel_src_dst_mask_cross : cross src_sel_cp, dst_sel_cp, 
			inc_src_cp, inc_dst_cp, src_mask_cp, dst_mask_cp {
			// Declare mask sizes >4 to be ignored for non-incrementing src/dst
			ignore_bins invalid_mask = 
				(binsof(inc_src_cp) intersect {0} && 
					binsof(src_mask_cp.src_addr_mask_bits) intersect {[5:$]}) ||
				(binsof(inc_dst_cp) intersect {0} && 
					binsof(dst_mask_cp.dst_addr_mask_bits) intersect {[5:$]});
		}	

		tot_sz_cp : coverpoint m_desc.tot_sz {
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

		chk_sz_cp : coverpoint m_desc.chk_sz {
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

		chk_tot_sz_cross : cross chk_sz_cp, tot_sz_cp;
	endgroup
	
	function new();
		cov = new;
		
		if (!$value$plusargs("REPORT_COVERAGE=%d", m_report_coverage)) begin
			m_report_coverage = 0;
		end 
	endfunction 


	function void sample(dma_channel_transfer_desc desc);
		real total;
		real inc_sel_src_dst_mask_cross, tot_sz_cp, chk_sz_cp, chk_tot_sz_cross;
		m_desc = desc;
		
		cov.sample();
		
		m_count++;
		
		if (m_report_coverage) begin
			if ((m_count < 1000 && !(m_count % 10)) ||
				(m_count < 10000 && !(m_count % 100)) ||
				!(m_count % 1000)) begin
				inc_sel_src_dst_mask_cross = cov.inc_sel_src_dst_mask_cross.get_coverage();
				tot_sz_cp = cov.tot_sz_cp.get_coverage();
				chk_sz_cp = cov.chk_sz_cp.get_coverage();
				chk_tot_sz_cross = cov.chk_tot_sz_cross.get_coverage();
				
                total = cov.get_coverage();
				
				$display("[COVERAGE] %0d total=%f inc_sel_src_dst_mask_cross=%f tot_sz_cp=%f chk_sz_cp=%f chk_tot_sz_cross=%f",
					m_count, total, inc_sel_src_dst_mask_cross, tot_sz_cp, chk_sz_cp, chk_tot_sz_cross);

                if (total >= 100) begin
                    global_stop_request();
                end
			end  
		end 
	endfunction
	
endclass 

