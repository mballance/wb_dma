/****************************************************************************
 * dma_reg_seqs_pkg.sv
 ****************************************************************************/
`include "uvm_macros.svh"

/**
 * Package: dma_reg_seqs_pkg
 * 
 * TODO: Add package documentation
 */
package dma_reg_seqs_pkg;
	import uvm_pkg::*;
	import dma_reg_pkg::*;
	
	`include "dma_reg_seq_base.svh"
	`include "dma_reg_check_reset_seq.svh"

endpackage


