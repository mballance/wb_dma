/****************************************************************************
 * dma_reg_pkg.sv
 ****************************************************************************/
`include "uvm_macros.svh"

/**
 * Package: dma_reg_pkg
 * 
 * TODO: Add package documentation
 */
package dma_reg_pkg;
	import uvm_pkg::*;
	import wb_vip_pkg::*;
	
	`include "dma_int_msk.svh"
	`include "dma_int_src.svh"
	`include "dma_csr.svh"
	`include "dma_channel_csr.svh"
	`include "dma_channel_sz.svh"
	`include "dma_channel_addr.svh"
	`include "dma_channel_amask.svh"
	`include "dma_channel_reg.svh"

	`include "dma_reg_block.svh"

	`include "dma_reg_rw.svh"
	`include "dma_reg2rw_adapter.svh"
	`include "dma_reg_driver.svh"
	`include "dma_reg_agent.svh"

endpackage


