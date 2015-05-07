/****************************************************************************
 * wb_dma_tests_pkg.sv
 ****************************************************************************/

/**
 * Package: wb_dma_tests_pkg
 * 
 * TODO: Add package documentation
 */
`include "uvm_macros.svh"
package wb_dma_tests_pkg;
	import uvm_pkg::*;
	import wb_dma_tb_pkg::*;
	import dma_config_pkg::*;
	import dma_reg_seqs_pkg::*;
	
	`include "wb_dma_test_base.svh"
	`include "wb_dma_reg_test_base.svh"


endpackage


