/****************************************************************************
 * dma_block_copy_test.svh
 ****************************************************************************/

/**
 * Class: dma_block_copy_test
 * 
 * TODO: Add class documentation
 */
class dma_block_copy_test extends wb_dma_test_base;
	`uvm_component_utils(dma_block_copy_test)

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	


	/**
	 * Task: run_scenario
	 *
	 * Override from class 
	 */
	virtual task run_scenario(uvm_phase phase);
		process plist[$];
		int n_running = 0;
		event ev;
		
		n_running = m_env.m_num_channels;
		for (int i=0; i<m_env.m_num_channels; i++) begin
			automatic string name = $psprintf("Sequence %0d", i);
			automatic wb_dma_channel_seq seq = wb_dma_channel_seq::type_id::create(name);
			automatic dma_channel_agent agent = m_env.channel_agents[i];
	
			fork
				begin
					$display("--> %0s", name);
					plist.push_back(process::self());
					seq.start(agent.m_seqr);
					n_running--;
					->ev;
					$display("EV: %0d", n_running);
					#0;
					$display("<-- %0s", name);
				end
			join_none
			#0;
		end
		
		while (n_running > 0) begin
			@ev;
			$display("n_running=%0d %0d", n_running, plist.size());
		end
	endtask


endclass


