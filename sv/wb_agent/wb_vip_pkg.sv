/****************************************************************************
 * wb_vip_pkg.sv
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 *
 * Top-level package for the Wishbone VIP
 ****************************************************************************/
`include "uvm_macros.svh"

package wb_vip_pkg;
	import uvm_pkg::*;
	
	`include "wb_if_config_wrapper.svh"
	`include "wb_master_seq_items.svh"
	`include "wb_master_driver.svh"
	`include "wb_simple_rw_seq.svh"

	`include "wb_slave_seq_items.svh"
	`include "wb_master_rw_seq.svh"
	`include "wb_slave_driver.svh"
	
	`include "wb_master_agent.svh"
	`include "wb_slave_agent.svh"
	
	
endpackage
