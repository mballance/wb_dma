/****************************************************************************
 * wb_dma_tb_top.sv
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved.
 * 
 * Top-level uvm testbench for the Wishbone DMA
 ****************************************************************************/

`include "wb_dma_defines.v"

module wb_dma_tb_top;
	import uvm_pkg::*;
	import wb_dma_tb_pkg::*;
	import wb_vip_pkg::*;

parameter CH_COUNT = 4;

reg		clk;
reg		rst;

// Interfaces used by the uvm testbench to connect to the design
wb_if						wb0m_if(.clk_i(clk), .rst_i(rst));
wb_if						wb1m_if(.clk_i(clk), .rst_i(rst));

wb_if						wb0s_if(.clk_i(clk), .rst_i(rst));
wb_if						wb1s_if(.clk_i(clk), .rst_i(rst));

wb_dma_irq_if				irq_if(.clk_i(clk), .rst_i(rst));

wb_dma_handshake_if			handshake_if(.clk_i(clk), .rst_i(rst));


/* Clock/Reset Generator */
always #5 clk = ~clk;
initial
   begin
   	clk = 0;
   	rst = 1;

   	repeat(10)	@(posedge clk);
   	rst = 0;
   	repeat(10)	@(posedge clk);
end


wb_dma_top
	#(	4'hb,		// register file address
		2'd1,		// Number of priorities (4)
		CH_COUNT,	// Number of channels
		4'hf,
		4'hf,
		4'hf,
		4'hf,
		4'hf,
		4'hf,
		4'hf,
		4'hf
		)
		u0(
		.clk_i(		clk		),
		.rst_i(		rst		),
		// Slave 0 Interface
		.wb0_addr_i(	wb0m_if.adr	),
		.wb0m_data_i(	wb0m_if.dat_o ),
		.wb0m_data_o(	wb0m_if.dat_i ),
		.wb0_sel_i(		wb0m_if.sel	),
		.wb0_we_i(		wb0m_if.we	),
		.wb0_cyc_i(		wb0m_if.cyc	),
		.wb0_stb_i(		wb0m_if.stb	),
		.wb0_ack_o(		wb0m_if.ack	),
		.wb0_err_o(		wb0m_if.err	),
		.wb0_rty_o(		wb0m_if.rty	),
		
		// Master 0 Interface
		.wb0_addr_o(	wb0s_if.adr	),
		.wb0s_data_i(	wb0s_if.dat_o),
		.wb0s_data_o(	wb0s_if.dat_i),
		.wb0_sel_o(		wb0s_if.sel	),
		.wb0_we_o(		wb0s_if.we	),
		.wb0_cyc_o(		wb0s_if.cyc	),
		.wb0_stb_o(		wb0s_if.stb	),
		.wb0_ack_i(		wb0s_if.ack	),
		.wb0_err_i(		wb0s_if.err	),
		.wb0_rty_i(		wb0s_if.rty	),
		
		// Slave 1 Interface
		.wb1_addr_i(	wb1m_if.adr	),
		.wb1m_data_i(	wb1m_if.dat_o	),
		.wb1m_data_o(	wb1m_if.dat_i	),
		.wb1_sel_i(		wb1m_if.sel	),
		.wb1_we_i(		wb1m_if.we	),
		.wb1_cyc_i(		wb1m_if.cyc	),
		.wb1_stb_i(		wb1m_if.stb	),
		.wb1_ack_o(		wb1m_if.ack	),
		.wb1_err_o(		wb1m_if.err	),
		.wb1_rty_o(		wb1m_if.rty	),
		
		// Master 1 Interface
		.wb1_addr_o(	wb1s_if.adr	),
		.wb1s_data_i(	wb1s_if.dat_o),
		.wb1s_data_o(	wb1s_if.dat_i),
		.wb1_sel_o(		wb1s_if.sel	),
		.wb1_we_o(		wb1s_if.we	),
		.wb1_cyc_o(		wb1s_if.cyc	),
		.wb1_stb_o(		wb1s_if.stb	),
		.wb1_ack_i(		wb1s_if.ack	),
		.wb1_err_i(		wb1s_if.err	),
		.wb1_rty_i(		wb1s_if.rty	),
		
		// DMA Interface
		.dma_req_i(	handshake_if.dma_req[CH_COUNT-1:0]	),
		.dma_ack_o(	handshake_if.dma_ack[CH_COUNT-1:0]	),
		.dma_nd_i(	handshake_if.dma_nd[CH_COUNT-1:0]		),
		.dma_rest_i(handshake_if.dma_rest[CH_COUNT-1:0]	),
		
		// Interrupt Interface
		.inta_o(		irq_if.inta	),
		.intb_o(		irq_if.intb	)
		
		);


initial begin
	wb_if_config_wrapper #(virtual wb_if) 				m0_cfg, m1_cfg;
	wb_if_config_wrapper #(virtual wb_if) 				s0_cfg, s1_cfg;
	wb_if_config_wrapper #(virtual wb_dma_irq_if)		irq_cfg;
	wb_if_config_wrapper #(virtual wb_dma_handshake_if)	handshake_cfg;
	
	m0_cfg = new("master_if", wb0m_if);
	m1_cfg = new("master_if", wb1m_if);
	s0_cfg = new("slave_if",  wb0s_if);
	s1_cfg = new("slave_if",  wb1s_if);
	
	irq_cfg = new("irq_if", irq_if);
	handshake_cfg = new("handshake_if", handshake_if);
	
	set_config_object("uvm_test_top.m0_driver", "master_if", m0_cfg, 0);
	set_config_object("uvm_test_top.m1_driver", "master_if", m1_cfg, 0);
	set_config_object("uvm_test_top.s0_driver", "slave_if", s0_cfg, 0);
	set_config_object("uvm_test_top.s1_driver", "slave_if", s1_cfg, 0);
	set_config_object("uvm_test_top.irq_monitor", "irq_if", irq_cfg, 0);

	set_config_object("uvm_test_top.timer", "timer_if", m0_cfg, 0);
	
	set_config_object("uvm_test_top.*", "handshake_if", handshake_cfg, 0);

	// Pass the channel count to the testbench	
	set_config_int("*", "num_channels", CH_COUNT);
//	set_config_int("*", "num_channels", 1);
	
	run_test();
end 

endmodule

