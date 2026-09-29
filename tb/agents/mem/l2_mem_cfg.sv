class l2_mem_cfg extends uvm_object;
  `uvm_object_utils(l2_mem_cfg)
  virtual l2_mem_if vif;
  int unsigned req_stall_pct = 0;
  int unsigned min_read_latency = 8;
  int unsigned max_read_latency = 20;
  bit enable_ooo = 1;
  bit force_ooo = 0;
  function new(string name="l2_mem_cfg"); super.new(name); endfunction
endclass
