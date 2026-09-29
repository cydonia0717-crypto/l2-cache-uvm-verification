class l2_core_rsp_backpressure_test extends l2_base_test;
  `uvm_component_utils(l2_core_rsp_backpressure_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    c0_cfg.rsp_stall_pct=70;
    m_cfg.min_read_latency=8;
    m_cfg.max_read_latency=20;
  endfunction

  task run_phase(uvm_phase phase);
    l2_outstanding_seq s=l2_outstanding_seq::type_id::create("s");
    phase.raise_objection(this);
    s.base=64'h0034_0000; s.count=12; s.stride=64;
    s.start(env.core0.sqr);
    wait_cycles(500);
    if (env.cov.core_rsp_stall_count==0)
      `uvm_error("CORE_RSP_BP","core response backpressure was not observed")
    if (env.sb.checks != 12)
      `uvm_error("CORE_RSP_BP",$sformatf("expected 12 checked reads, got %0d",env.sb.checks))
    phase.drop_objection(this);
  endtask
endclass
