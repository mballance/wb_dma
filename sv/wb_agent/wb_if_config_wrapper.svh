/****************************************************************************
 * wb_if_config_wrapper.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 *
 * The config-wrapper class provides an easy way to pass a virtual interface
 * to the testbench via the uvm configuration system
 ****************************************************************************/
`ifndef INCLUDED_WB_IF_CONFIG_WRAPPER_SVH
`define INCLUDED_WB_IF_CONFIG_WRAPPER_SVH

class wb_if_config_wrapper #(type T=int) extends uvm_object;
	
	T					m_if;
	
	function new(string field_name, T value);
		super.new(field_name);
		
		m_if = value;
	endfunction
	
endclass 

`endif /* INCLUDED_WB_IF_CONFIG_WRAPPER_SVH */
