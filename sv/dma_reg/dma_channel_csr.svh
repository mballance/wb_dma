/****************************************************************************
 * dma_channel_csr.svh
 ****************************************************************************/

/**
 * Class: dma_channel_csr
 * 
 * TODO: Add class documentation
 */
class dma_channel_csr extends uvm_reg;
	`uvm_object_utils(dma_channel_csr)
	
	rand uvm_reg_field				INE_CHK_DONE;
	rand uvm_reg_field				INE_DONE;
	rand uvm_reg_field				INE_ERR;
	rand uvm_reg_field				REST_EN;
	rand uvm_reg_field				PRIORITY;
	rand uvm_reg_field				ERR;
	rand uvm_reg_field				DONE;
	rand uvm_reg_field				BUSY;
	rand uvm_reg_field				STOP;
	rand uvm_reg_field				SZ_WB;
	rand uvm_reg_field				USE_ED;
	rand uvm_reg_field				ARS;
	rand uvm_reg_field				MODE;
	rand uvm_reg_field				INC_SRC;
	rand uvm_reg_field				INC_DST;
	rand uvm_reg_field				SRC_SEL;
	rand uvm_reg_field				DST_SEL;
	rand uvm_reg_field				CH_EN;
	
	function new(string name="dma_channel_csr");
		super.new(name, 32, UVM_NO_COVERAGE);
	endfunction

	function void build();
		INE_CHK_DONE = uvm_reg_field::type_id::create("INE_CHK_DONE");
		INE_CHK_DONE.configure(this, 1, 19, "RW", 0, 0, 1, 1, 0);
		
		INE_DONE = uvm_reg_field::type_id::create("INE_DONE");
		INE_DONE.configure(this, 1, 18, "RW", 0, 0, 1, 1, 0);
		
		INE_ERR = uvm_reg_field::type_id::create("INE_ERR");
		INE_ERR.configure(this, 1, 17, "RW", 0, 0, 1, 1, 0);
		
		REST_EN = uvm_reg_field::type_id::create("REST_EN");
		REST_EN.configure(this, 1, 16, "RW", 0, 0, 1, 1, 0);
		
		PRIORITY = uvm_reg_field::type_id::create("PRIORITY");
		PRIORITY.configure(this, 3, 13, "RW", 0, 0, 1, 1, 0);
		
		ERR = uvm_reg_field::type_id::create("ERR");
		ERR.configure(this, 1, 12, "RO", 0, 0, 1, 1, 0);
		
		DONE = uvm_reg_field::type_id::create("DONE");
		DONE.configure(this, 1, 11, "RO", 0, 0, 1, 1, 0);
		
		BUSY = uvm_reg_field::type_id::create("BUSY");
		BUSY.configure(this, 1, 10, "RO", 0, 0, 1, 1, 0);
		
		STOP = uvm_reg_field::type_id::create("STOP");
		STOP.configure(this, 1, 9, "WO", 0, 0, 1, 1, 0);
		
		SZ_WB = uvm_reg_field::type_id::create("SZ_WB");
		SZ_WB.configure(this, 1, 8, "RW", 0, 0, 1, 1, 0);
		
		USE_ED = uvm_reg_field::type_id::create("USE_ED");
		USE_ED.configure(this, 1, 7, "RW", 0, 0, 1, 1, 0);
		
		ARS = uvm_reg_field::type_id::create("ARS");
		ARS.configure(this, 1, 6, "RW", 0, 0, 1, 1, 0);
	
		MODE = uvm_reg_field::type_id::create("MODE");
		MODE.configure(this, 1, 5, "RW", 0, 0, 1, 1, 0);
		
		INC_SRC = uvm_reg_field::type_id::create("INC_SRC");
		INC_SRC.configure(this, 1, 4, "RW", 0, 0, 1, 1, 0);
	
		INC_DST = uvm_reg_field::type_id::create("INC_DST");
		INC_DST.configure(this, 1, 3, "RW", 0, 0, 1, 1, 0);
		
		SRC_SEL = uvm_reg_field::type_id::create("SRC_SEL");
		SRC_SEL.configure(this, 1, 2, "RW", 0, 0, 1, 1, 0);
		
		DST_SEL = uvm_reg_field::type_id::create("DST_SEL");
		DST_SEL.configure(this, 1, 1, "RW", 0, 0, 1, 1, 0);
		
		CH_EN = uvm_reg_field::type_id::create("CH_EN");
		CH_EN.configure(this, 1, 0, "RW", 0, 0, 1, 1, 0);
	endfunction


endclass


