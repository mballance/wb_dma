/****************************************************************************
 * wb_dma_analysis_closure.svh
 * 
 * Copyright 2010 Mentor Graphics Corporation. All Rights Reserved
 * 
 * Defines macros that are used to declare closure classes for analysis 
 * ports that call an arbitrary method within the target class
 ****************************************************************************/

`define wb_dma_analysis_closure_imp_t(closure_type, data_type, target, func) \
	typedef class target; \
	class wb_dma_analysis_closure_``data_type``_``target``_``func \
		extends uvm_component; \
		uvm_analysis_imp #(data_type, \
			wb_dma_analysis_closure_``data_type``_``target``_``func) exp; \
		\
		target							m_target_ptr; \
		\
		function new(string name, target t); \
			super.new(name, t); \
			m_target_ptr = t; \
			exp = new("exp", this); \
		endfunction \
		\
		virtual function void write(data_type t); \
			m_target_ptr. func (t); \
		endfunction \
	endclass \
	typedef wb_dma_analysis_closure_``data_type``_``target``_``func closure_type ;
	
