/****************************************************************************
 * dma_channel_agent_pkg.sv
 ****************************************************************************/
`include "uvm_macros.svh"

/**
 * Package: dma_channel_agent_pkg
 * 
 * TODO: Add package documentation
 */
package dma_channel_agent_pkg;
	import uvm_pkg::*;
	import memory_mgr_pkg::*;
	import timer_pkg::*;

	`include "dma_channel_transfer_desc.svh"
	`include "dma_transfer_complete_ev.svh"
	`include "dma_channel_driver.svh"
	
	`include "dma_channel_agent.svh"

endpackage


