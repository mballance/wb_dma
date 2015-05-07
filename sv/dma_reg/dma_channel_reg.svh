/****************************************************************************
 * dma_channel_reg.svh
 ****************************************************************************/

/**
 * Class: dma_channel_reg
 * 
 * TODO: Add class documentation
 */
class dma_channel_reg extends uvm_object;
	`uvm_object_utils(dma_channel_reg)
	
	rand dma_channel_csr			CSR;
	rand dma_channel_sz				SZ;
	rand dma_channel_addr			SRC;
	rand dma_channel_amask			SRCM;
	rand dma_channel_addr			DST;
	rand dma_channel_amask			DSTM;
	rand dma_channel_addr			DESC;
	rand dma_channel_addr			SWPTR;

	function void build(int ch, uvm_reg_block parent);
		CSR = dma_channel_csr::type_id::create($psprintf("CH_%0d_CSR", ch));
		CSR.configure(parent, null, "");
		CSR.build();
		
		SZ = dma_channel_sz::type_id::create($psprintf("CH_%0d_SZ", ch));
		SZ.configure(parent, null, "");
		SZ.build();
		
		SRC = dma_channel_addr::type_id::create($psprintf("CH_%0d_SRC", ch));
		SRC.configure(parent, null, "");
		SRC.build();
		
		SRCM = dma_channel_amask::type_id::create($psprintf("CH_%0d_SRCM", ch));
		SRCM.configure(parent, null, "");
		SRCM.build();
		
		DST = dma_channel_addr::type_id::create($psprintf("CH_%0d_DST", ch));
		DST.configure(parent, null, "");
		DST.build();
		
		DSTM = dma_channel_amask::type_id::create($psprintf("CH_%0d_DSTM", ch));
		DSTM.configure(parent, null, "");
		DSTM.build();
		
		DESC = dma_channel_addr::type_id::create($psprintf("CH_%0d_DESC", ch));
		DESC.configure(parent, null, "");
		DESC.build();
		
		SWPTR = dma_channel_addr::type_id::create($psprintf("CH_%0d_SWPTR", ch));
		SWPTR.configure(parent, null, "");
		SWPTR.build();
		
	endfunction
	
	function void map(bit[31:0] base, uvm_reg_map dma_map);
		dma_map.add_reg(CSR, 	base+'h0000, "RW");
		dma_map.add_reg(SZ, 	base+'h0004, "RW");
		dma_map.add_reg(SRC, 	base+'h0008, "RW");
		dma_map.add_reg(SRCM, 	base+'h000C, "RW");
		dma_map.add_reg(DST, 	base+'h0010, "RW");
		dma_map.add_reg(DSTM, 	base+'h0014, "RW");
		dma_map.add_reg(DESC, 	base+'h0018, "RW");
		dma_map.add_reg(SWPTR, 	base+'h001C, "RW");
	endfunction


endclass


