class l2_mem_obs extends uvm_sequence_item;
  l2_mem_evt_e             kind;
  bit                      rw;
  longint unsigned         addr;
  bit [L2_LINE_BITS-1:0]   data;
  bit [L2_LINE_BYTES-1:0]  byteen;
  bit [L2_MEM_TAG_W-1:0]   tag;

  `uvm_object_utils_begin(l2_mem_obs)
    `uvm_field_enum(l2_mem_evt_e, kind, UVM_DEFAULT)
    `uvm_field_int(rw, UVM_DEFAULT)
    `uvm_field_int(addr, UVM_HEX)
    `uvm_field_int(data, UVM_HEX)
    `uvm_field_int(byteen, UVM_HEX)
    `uvm_field_int(tag, UVM_HEX)
  `uvm_object_utils_end
  function new(string name="l2_mem_obs"); super.new(name); endfunction
endclass

class l2_pending_rsp extends uvm_object;
  `uvm_object_utils(l2_pending_rsp)
  bit [L2_LINE_BITS-1:0] data;
  bit [L2_MEM_TAG_W-1:0] tag;
  longint unsigned       addr;
  int unsigned           due_cycle;
  function new(string name="l2_pending_rsp"); super.new(name); endfunction
endclass
