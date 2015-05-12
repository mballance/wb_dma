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
		dma_reg_rw bus;
		$cast(bus, bus_item);
		
		rw.kind = (bus.is_write)?UVM_WRITE:UVM_READ;
		rw.addr = bus.addr;
		rw.data = bus.data;
		rw.byte_en = 'hf;
		rw.status = UVM_IS_OK;
	endfunction
	
	virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
		dma_reg_rw bus = dma_reg_rw::type_id::create("rw");

		if (rw.kind == UVM_WRITE) begin
			$display("WRITE: 'h%08h 'h%08h", rw.addr, rw.data);
		end
		
		bus.is_write = (rw.kind == UVM_WRITE);
		bus.addr = rw.addr;
		bus.data = rw.data;
//		bus.byte_en = rw.byte_en;
		
		return bus;
	endfunction
		

endclass


