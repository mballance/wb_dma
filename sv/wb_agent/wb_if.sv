/****************************************************************************
 * wb_if.sv
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 *
 * Interface to Wishbone interfaces
 ****************************************************************************/

interface wb_if(
	input wire			clk_i,
	input wire			rst_i);
	
	logic				clk;
	logic				rst;
	logic [31:0]		dat_i;
	logic [31:0]		dat_o;
	logic [31:0]		adr;
	logic [3:0]			sel;
	logic				cyc;
	logic				stb;
	logic				we;
	logic				ack;
	logic				err;
	logic				rty;
	
	logic				post_clk;
	
	assign clk = clk_i;
	assign rst = rst_i;
	always post_clk = #1 clk_i;
	
	modport master(
		input		dat_i,
		output		dat_o,
		output		adr,
		output		sel,
		output		cyc,
		output		stb,
		output		we,
		input		ack,
		input		err,
		input		rty
	);

	modport slave(
		input		dat_i,
		output		dat_o,
		input		adr,
		input		sel,
		input		cyc,
		input		stb,
		input		we,
		output		ack,
		output		err,
		output		rty
	);

	modport monitor(
		input		dat_i,
		input		dat_o,
		input		adr,
		input		sel,
		input		cyc,
		input		stb,
		input		we,
		input		ack,
		input		err,
		input		rty
	);
	
	
endinterface 


