class l2_mshr_full_test extends l2_base_test;
  `uvm_component_utils(l2_mshr_full_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.min_read_latency=80;
    m_cfg.max_read_latency=100;
    m_cfg.enable_ooo=0;
  endfunction

  task run_phase(uvm_phase phase);
    l2_outstanding_seq s=l2_outstanding_seq::type_id::create("s");
    phase.raise_objection(this);
    // 256-byte stride keeps all misses on the same bank.  Eight can occupy
    // that bank's eight MSHRs; the ninth must wait for an entry to free.
    s.count=9; s.stride=256;
    s.start(env.core0.sqr);
    wait_cycles(220);
    if (env.cov.max_outstanding_refills != 8)
      `uvm_error("MSHR_FULL",$sformatf("expected bank-local depth 8, saw %0d",env.cov.max_outstanding_refills))
    if (env.cov.core_req_stall_count==0)
      `uvm_error("MSHR_FULL","ninth same-bank miss did not observe runtime backpressure")
    if (env.sb.checks != 9)
      `uvm_error("MSHR_FULL",$sformatf("expected 9 completed reads, got %0d",env.sb.checks))
    phase.drop_objection(this);
  endtask
endclass
