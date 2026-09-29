class l2_mshr_reuse_test extends l2_base_test;
  `uvm_component_utils(l2_mshr_reuse_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.min_read_latency=35;
    m_cfg.max_read_latency=35;
    m_cfg.enable_ooo=0;
  endfunction

  task run_phase(uvm_phase phase);
    l2_outstanding_seq a=l2_outstanding_seq::type_id::create("a");
    l2_outstanding_seq b=l2_outstanding_seq::type_id::create("b");
    phase.raise_objection(this);
    a.base=64'h0036_0000; a.count=8; a.stride=256;
    b.base=64'h0046_0000; b.count=8; b.stride=256;
    a.start(env.core0.sqr);
    wait_cycles(220);
    b.start(env.core0.sqr);
    wait_cycles(260);
    if (env.sb.checks != 16)
      `uvm_error("MSHR_REUSE",$sformatf("expected 16 completed reads, got %0d",env.sb.checks))
    if (env.sb.mem_refill_reqs != 16)
      `uvm_error("MSHR_REUSE",$sformatf("expected 16 refills, got %0d",env.sb.mem_refill_reqs))
    phase.drop_objection(this);
  endtask
endclass
