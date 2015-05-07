/****************************************************************************
 * wb_dma_handshake_driver.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * Hardware handshake driver. Receives broadcast descriptors from the 
 * descriptor drivers. When this channel is performing a hardware-controlled
 * transfer, this driver interacts with the hardware-handshake interface
 * to request transfers and (possibly) request descriptor restart or skip
 ****************************************************************************/

class wb_dma_handshake_driver extends uvm_component;
	
	uvm_analysis_imp #(dma_channel_transfer_desc, wb_dma_handshake_driver)	descriptor_analysis_export;
	uvm_analysis_port #(wb_dma_handshake_ev)						handshake_analysis_port;
	
	int							m_channel_id;
	virtual wb_dma_handshake_if	m_if;
	string						m_name = "HANDSHAKE";
	dma_channel_transfer_desc			m_descriptor;
	bit							m_descriptor_ev;
	wb_dma_handshake_ev			m_handshake_ev;
	
	function new(string name, uvm_component parent);
		super.new(name, parent);
		
		m_handshake_ev = wb_dma_handshake_ev::type_id::create("ev");
	endfunction 
	
	function void init(int channel_id);
		m_channel_id = channel_id;
	endfunction 
		
	function void build();
		uvm_object												cfg_o;
		wb_if_config_wrapper #(virtual wb_dma_handshake_if) 	cfg;
		
		if (!get_config_object("handshake_if", cfg_o, 0)) begin
			uvm_report_error(m_name, "Failed to get handshake interface");
			$stop;
		end
			
		if (!$cast(cfg, cfg_o)) begin
			uvm_report_error(m_name, "Failed to cast handshake interface");
		end
			
		m_if = cfg.m_if;
		
		descriptor_analysis_export = new("descriptor_analysis_export", this);
		handshake_analysis_port = new("handshake_analysis_port", this);
	endfunction 
	
	function void write(dma_channel_transfer_desc item);
		if (item.channel == m_channel_id) begin
			m_descriptor = dma_channel_transfer_desc'(item.clone());
			m_descriptor_ev = 1;
		end
	endfunction 
	
	task run();
		m_if.dma_req[m_channel_id]  = 0;
		m_if.dma_nd[m_channel_id]   = 0;
		m_if.dma_rest[m_channel_id] = 0;
		forever begin
			wait(m_descriptor_ev == 1);
			m_descriptor_ev = 0;
			
			if (m_descriptor.mode == 0) begin
				continue;
			end
			
			// This descriptor is a hw-controlled descriptor
			uvm_report_info(m_name, "Begin hw-controlled descriptor");
			
			if (!m_descriptor.use_ed) begin
				for (int sz=0; sz<m_descriptor.tot_sz;
					sz+= (m_descriptor.chk_sz)?m_descriptor.chk_sz:m_descriptor.tot_sz) begin
					@(m_if.clk);
					
					// Raise REQ and wait for ACK
					m_if.dma_req[m_channel_id] = 1;
					
					@(posedge m_if.clk);
					while (m_if.dma_ack[m_channel_id] == 0) begin
						@(posedge m_if.clk);
					end
					
//					uvm_report_info(m_name, "Received ACK");
				end
			end else begin
				int restart = -1, force_next = -1;
				int post_xfer_total;
				bit assert_nd;

				
				for (int i=0; i<m_descriptor.ll_desc.size(); i++) begin
					
					assert_nd = 0;					

					for (int sz=0; sz<m_descriptor.ll_desc[i].tot_sz; 
							sz+= (m_descriptor.chk_sz)?m_descriptor.chk_sz:m_descriptor.ll_desc[i].tot_sz) begin
						
						// Compute the number of words that will have been 
						// transferred at the end of this operation
						post_xfer_total = sz;
						if (m_descriptor.chk_sz > 0) begin
							post_xfer_total += m_descriptor.chk_sz;
						end else begin
							post_xfer_total += m_descriptor.ll_desc[i].tot_sz;
						end
						
						if (post_xfer_total > m_descriptor.ll_desc[i].tot_sz) begin
							post_xfer_total = m_descriptor.ll_desc[i].tot_sz;
						end
						
						@(m_if.clk);

						// Raise REQ and wait for ACK
						m_if.dma_req[m_channel_id] = 1;
						
						if (assert_nd) begin
							m_if.dma_nd[m_channel_id] = 1;
						end else begin
							m_if.dma_nd[m_channel_id] = 0;
						end 
							

						@(posedge m_if.clk);
						while (m_if.dma_ack[m_channel_id] == 0) begin
							@(posedge m_if.clk);
						end
						
						m_if.dma_req[m_channel_id] = 0;
						
						assert_nd = 0;

						if (m_descriptor.ll_desc[i].ars == 1 && restart != i && 
							m_if.dma_nd[m_channel_id] != 1) begin
							uvm_report_info(m_name, 
								$psprintf("Restarting ll_desc %0d", i));
							restart = i;

							@(posedge m_if.clk);
							@(posedge m_if.clk);
							m_if.dma_rest[m_channel_id] = 1;
							@(posedge m_if.clk);
							@(posedge m_if.clk);
							m_if.dma_rest[m_channel_id] = 0;
							
							m_handshake_ev.ev_type = Restart;
							m_handshake_ev.channel_id = m_channel_id;
							m_handshake_ev.descriptor_index = i;
							m_handshake_ev.words_transferred = post_xfer_total;
							handshake_analysis_port.write(m_handshake_ev);
							
							i--;
							break;
						end else if (force_next != i &&
							m_descriptor.ll_desc[i].force_next != ForceNext_Off) begin
							if (m_descriptor.ll_desc[i].force_next == ForceNext_Now) begin
								uvm_report_info(m_name, 
									$psprintf("ForceNext_Now on ll_desc %0d", i));
								
								m_if.dma_nd[m_channel_id] = 1;
								@(posedge m_if.clk);
								@(posedge m_if.clk);
								m_if.dma_nd[m_channel_id] = 0;
								m_handshake_ev.ev_type = ForceNext;
								m_handshake_ev.channel_id = m_channel_id;
								m_handshake_ev.descriptor_index = i;
								m_handshake_ev.words_transferred = post_xfer_total;
								handshake_analysis_port.write(m_handshake_ev);
								
								force_next = i;
								break;
							end else begin
								if (m_if.dma_nd[m_channel_id] == 1) begin
									uvm_report_info(m_name, 
										$psprintf("Complete ForceNext_Next on ll_desc %0d", i));
										
									m_if.dma_nd[m_channel_id] = 0;
									m_handshake_ev.ev_type = ForceNext;
									m_handshake_ev.channel_id = m_channel_id;
									m_handshake_ev.descriptor_index = i;
									m_handshake_ev.words_transferred = post_xfer_total;
									handshake_analysis_port.write(m_handshake_ev);
									force_next = i;
									break;
								end else begin
									uvm_report_info(m_name, 
										$psprintf("Begin ForceNext_Next on ll_desc %0d", i));
									
									assert_nd = 1;
								end 
							end 
						end 
					end
				end
			end

			uvm_report_info(m_name, "Hardware Handshake Transfer complete");			
			m_if.dma_req[m_channel_id] = 0;
		end 
	endtask
	
endclass 


