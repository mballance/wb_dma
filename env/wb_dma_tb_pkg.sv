/****************************************************************************
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 *
 * Top-level testbench package for the DMA testbench
 ****************************************************************************/
`include "uvm_macros.svh"
`include "wb_dma_analysis_closure.svh"

`define REG_BASE 'hb000_0000

package wb_dma_tb_pkg;
	import uvm_pkg::*;
	import wb_vip_pkg::*;

`ifdef INFACT
	import inFactSv::*;
	
	`include "infact_sv_utils.svh"
`endif
	  
	`include "wb_dma_regs.svh"
	
	`include "wb_dma_irq_ev.svh"
	`include "wb_dma_mem_ev.svh"
	`include "wb_dma_handshake_ev.svh"
	`include "wb_dma_desc_complete_ev.svh"
	`include "wb_dma_descriptor.svh"
	`include "wb_dma_descriptor_cg.svh"
	`include "wb_dma_descriptor_cg_small.svh"
	`include "wb_dma_descriptor_cg_demo.svh"

	`include "wb_dma_memory_mgr.svh"
	`include "wb_dma_timer.svh"
	`include "wb_dma_slave_seq.svh"
	
	`include "wb_dma_irq_monitor.svh"
	`include "wb_dma_scoreboard.svh"
	
	`include "wb_dma_descriptor_driver.svh"
	`include "wb_dma_handshake_driver.svh"
	`include "wb_dma_channel_seq.svh"

`ifdef INFACT
	`include "infact_channel_desc_seq.svh"
`endif

	`include "wb_dma_sw.svh"
	`include "wb_dma_env.svh"
	
`ifdef INFACT
	`include "wb_dma_infact_env.svh"
`endif 
	
endpackage
