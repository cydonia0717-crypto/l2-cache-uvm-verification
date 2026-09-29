class l2_core_cfg extends uvm_object;
  `uvm_object_utils(l2_core_cfg)
  virtual l2_core_if vif;
  int unsigned port_id;
  int unsigned rsp_stall_pct = 0;
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  function new(string name="l2_core_cfg"); super.new(name); endfunction
endclass
