class l2_core_item extends uvm_sequence_item;
  rand bit                    rw;
  rand longint unsigned       addr;
  rand bit [L2_DATA_W-1:0]    data;
  rand bit [L2_STRB_W-1:0]    byteen;
  rand bit [L2_CORE_TAG_W-1:0] tag;

  constraint c_align { addr[2:0] == 3'b000; }
  constraint c_byteen { if (!rw) byteen == '0; else byteen != '0; }

  `uvm_object_utils_begin(l2_core_item)
    `uvm_field_int(rw, UVM_DEFAULT)
    `uvm_field_int(addr, UVM_HEX)
    `uvm_field_int(data, UVM_HEX)
    `uvm_field_int(byteen, UVM_HEX)
    `uvm_field_int(tag, UVM_HEX)
  `uvm_object_utils_end

  function new(string name="l2_core_item"); super.new(name); endfunction
endclass

class l2_core_obs extends uvm_sequence_item;
  l2_core_evt_e              kind;
  int unsigned               port_id;
  bit                        rw;
  longint unsigned           addr;
  bit [L2_DATA_W-1:0]        data;
  bit [L2_STRB_W-1:0]        byteen;
  bit [L2_CORE_TAG_W-1:0]    tag;

  `uvm_object_utils_begin(l2_core_obs)
    `uvm_field_enum(l2_core_evt_e, kind, UVM_DEFAULT)
    `uvm_field_int(port_id, UVM_DEC)
    `uvm_field_int(rw, UVM_DEFAULT)
    `uvm_field_int(addr, UVM_HEX)
    `uvm_field_int(data, UVM_HEX)
    `uvm_field_int(byteen, UVM_HEX)
    `uvm_field_int(tag, UVM_HEX)
  `uvm_object_utils_end

  function new(string name="l2_core_obs"); super.new(name); endfunction
endclass
