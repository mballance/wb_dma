/****************************************************************************
 * wb_dma_irq_if.sv
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * Interface between the testbench and the interrupt interface on the
 * DMA engine
 ****************************************************************************/

interface wb_dma_irq_if(
	input				clk_i,
	input				rst_i);
	
	logic				clk;
	logic				rst;
	bit					inta;
	bit					intb;
	
	assign clk = clk_i;
	assign rst = rst_i;
	
	modport monitor(
		input			inta,
		input			intb);
	
endinterface 