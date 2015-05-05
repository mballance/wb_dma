/****************************************************************************
 * wb_dma_regs.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 *
 * Defines SV structs that describe the bit fields in the DMA registers
 ****************************************************************************/
`ifndef INCLUDED_WB_DMA_REGS_SVH
`define INCLUDED_WB_DMA_REGS_SVH

`define CH_REG_BASE(REG_BASE, CHAN) ((REG_BASE) + 'h20 + ('h20 * (CHAN)))

typedef struct packed {
	bit [31:23]				reserved;
	
	// RO bits indicating interrupts
	bit 					i_chk_sz;		// 22
	bit						i_ch_done;		// 21
	bit						i_ch_err;		// 20
	
	bit						ine_chk_done;
	bit						ine_done;
	bit						ine_err;
	
	bit						rest_en;
	
	bit [15:13]				chn_priority;
	
	// RO bits indicating DMA status
	bit						err;
	bit						done;
	bit						busy;
	
	bit						stop;
	
	bit						sz_wb;
	
	bit						use_ed;
	bit						ars;
	bit						mode;
	bit						inc_src;
	bit						inc_dst;
	bit						src_sel;
	bit						dst_sel;
	
	bit						ch_en;				
} CH_CSR_t;	

typedef struct packed {
	bit [31:21]				reserved_1;
	bit						EOL; 		// 20
	bit						inc_src;	// 19
	bit						inc_dst;	// 18
	bit						src_sel;	// 17
	bit						dst_sel;	// 16
	bit [15:12]				reserved_2;
	bit [11:0]				tot_sz;
} CH_LL_CSR_t;	

typedef struct packed {
	bit [31:25]				reserved_1;
	bit [24:16]				chk_sz;
	bit [15:12]				reserved_2;
	bit [11:0]				tot_sz;
} CH_SZ_t;

typedef struct packed {
	bit [31:2]				address;
	bit [1:0]				reserved;
} CH_Am_t;

typedef struct packed {
	bit [31:4]				mask;
	bit [3:0]				reserved;
} CH_AMm_t;
	

`endif /* INCLUDED_WB_DMA_REGS_SVH */
