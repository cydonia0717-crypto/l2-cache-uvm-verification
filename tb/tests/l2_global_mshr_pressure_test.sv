class l2_global_mshr_pressure_test extends l2_base_test;
  `uvm_component_utils(l2_global_mshr_pressure_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.min_read_latency=220;
    m_cfg.max_read_latency=220;
    m_cfg.enable_ooo=0;
  endfunction

  task run_phase(uvm_phase phase);
    l2_outstanding_seq s=l2_outstanding_seq::type_id::create("s");
    phase.raise_objection(this);
    s.base=64'h0100_0000; s.count=33; s.stride=64;
    s.start(env.core0.sqr);
    wait_cycles(900);
    if (env.cov.max_outstanding_refills != 32)
      `uvm_error("GLOBAL_MSHR",$sformatf("expected aggregate 32 outstanding refills, saw %0d",env.cov.max_outstanding_refills))
    if (env.cov.core_req_stall_count==0)
      `uvm_error("GLOBAL_MSHR","33rd miss did not observe upstream resource backpressure")
    if (env.sb.checks != 33)
      `uvm_error("GLOBAL_MSHR",$sformatf("expected 33 completed reads, got %0d",env.sb.checks))
    phase.drop_objection(this);
  endtask
endclass
