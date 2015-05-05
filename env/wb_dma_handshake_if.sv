/****************************************************************************
 * wb_dma_handshake_if.sv
 *
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * Interface for connecting the testbench to the hardware handshake 
 * interface on the DMA engine
 ****************************************************************************/

interface wb_dma_handshake_if(
	input			clk_i,
	input			rst_i);
	
	logic						clk;
	logic						rst;
	logic [31:0]		dma_req;
	logic [31:0]		dma_ack;
	logic [31:0]		dma_nd;
	logic [31:0]		dma_rest;
	
	assign clk = clk_i;
	assign rst = rst_i;
	
	modport handshake(
		output dma_req,
		input  dma_ack,
		output dma_nd,
		output dma_rest);
	
	
endinterface 