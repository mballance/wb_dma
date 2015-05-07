/****************************************************************************
 * dma_reg_block.svh
 ****************************************************************************/

/**
 * Class: dma_reg_block
 * 
 * TODO: Add class documentation
 */
class dma_reg_block extends uvm_reg_block;
	`uvm_object_utils(dma_reg_block)
	
	uvm_reg_map					dma_map;
	
	rand dma_csr				CSR;
	rand dma_int_msk			INT_MSK_A;
	rand dma_int_msk			INT_MSK_B;
	rand dma_int_src			INT_SRC_A;
	rand dma_int_src			INT_SRC_B;
	dma_channel_reg				CH[];

	function new(string name="dma_reg_block");
		super.new(name, UVM_NO_COVERAGE);
	
	endfunction
	
	function void build(bit[31:0] base);
		CSR = dma_csr::type_id::create("CSR");
		CSR.configure(this, null, "");
		CSR.build();
		
		INT_MSK_A = dma_int_msk::type_id::create("INT_MSK_A");
		INT_MSK_A.configure(this, null, "");
		INT_MSK_A.build();
		
		INT_MSK_B = dma_int_msk::type_id::create("INT_MSK_B");
		INT_MSK_B.configure(this, null, "");
		INT_MSK_B.build();
		
		INT_SRC_A = dma_int_src::type_id::create("INT_SRC_A");
		INT_SRC_A.configure(this, null, "");
		INT_SRC_A.build();
		
		INT_SRC_B = dma_int_src::type_id::create("INT_SRC_B");
		INT_SRC_B.configure(this, null, "");
		INT_SRC_B.build();
		
		CH = new[31];
		for (int i=0; i<31; i++) begin
			CH[i] = dma_channel_reg::type_id::create($psprintf("CH_%0d", i));
			CH[i].build(i, this);
		end
		
		dma_map = create_map("dma_map", 'h0, 4, UVM_LITTLE_ENDIAN);
		dma_map.add_reg(CSR, 		base+'h0000, "RW");
		dma_map.add_reg(INT_MSK_A, 	base+'h0004, "RW");
		dma_map.add_reg(INT_MSK_B, 	base+'h0008, "RW");
		dma_map.add_reg(INT_SRC_A, 	base+'h000C, "RW");
		dma_map.add_reg(INT_SRC_B, 	base+'h0010, "RW");
		
		foreach (CH[i]) begin
			CH[i].map(base+'h0020+'h20*i, dma_map);
		end
		
		lock_model();
		
	endfunction


endclass


