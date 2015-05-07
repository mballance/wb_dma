/****************************************************************************
 * dma_reg2rw_adapter.svh
 ****************************************************************************/

/**
 * Class: dma_reg2rw_adapter
 * 
 * TODO: Add class documentation
 */
class dma_reg2rw_adapter extends uvm_reg_adapter;
	`uvm_object_utils(dma_reg2rw_adapter)

	function new(string name="dma_reg2rw_adapter");
		super.new(name);
		supports_byte_enable = 1;
	endfunction
	
	virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
	endfunction
	
	virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
		dma_reg_rw bus = dma_reg_rw::type_id::create("rw");
		
		bus.is_write = (rw.kind == UVM_WRITE);
		bus.addr = rw.addr;
		bus.data = rw.data;
//		bus.byte_en = rw.byte_en;
		
		return bus;
	endfunction
		

endclass


