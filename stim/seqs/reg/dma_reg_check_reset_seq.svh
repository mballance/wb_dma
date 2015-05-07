/****************************************************************************
 * dma_reg_check_reset_seq.svh
 ****************************************************************************/

/**
 * Class: dma_reg_check_reset_seq
 * 
 * TODO: Add class documentation
 */
class dma_reg_check_reset_seq extends dma_reg_seq_base;
	`uvm_object_utils(dma_reg_check_reset_seq)

	function new(string name="dma_reg_check_reset_seq");
		super.new(name);
	endfunction



	/**
	 * Task: body
	 *
	 * Override from class 
	 */
	virtual task body();
		uvm_reg dma_regs[$];
		uvm_reg_data_t ref_data;
		uvm_reg_data_t data;
		uvm_status_e status;
		
		m_dma_regs.get_registers(dma_regs);
		
		foreach (dma_regs[i]) begin
			ref_data = dma_regs[i].get_reset();
			dma_regs[i].read(status, data);
	
			if (ref_data != data) begin
				`uvm_error("RESET_TEST_SEQ:", 
						$sformatf("Register %0s: reset read error; Expected: 'h%08h Actual: 'h%08h",
							dma_regs[i].get_name(), ref_data, data));
			end
		end

	endtask

	

endclass


