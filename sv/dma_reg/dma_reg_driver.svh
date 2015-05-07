/****************************************************************************
 * dma_reg_driver.svh
 ****************************************************************************/
 
typedef class dma_reg_agent;

/**
 * Class: dma_reg_driver
 * 
 * TODO: Add class documentation
 */
class dma_reg_driver extends uvm_driver #(dma_reg_rw);
	`uvm_component_utils(dma_reg_driver)

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction


	/**
	 * Task: run_phase
	 *
	 * Override from class 
	 */
	virtual task run_phase(input uvm_phase phase);
		wb_master_rw_seq rw_seq;
		dma_reg_agent agent;
		
		rw_seq = wb_master_rw_seq::type_id::create();
		$cast(agent, get_parent());
		
		forever begin
			dma_reg_rw rw;
			
			seq_item_port.get_next_item(rw);
			if (rw.is_write) begin
				rw_seq.set_wr32(rw.addr, rw.data);
			end else begin
				rw_seq.set_rd32(rw.addr);
			end
			
			rw_seq.start(agent.m_wb_seqr);
			
			if (!rw.is_write) begin
				rw.data = rw_seq.rsp.data[0];
			end
			
			seq_item_port.item_done();
		end

	endtask



endclass


