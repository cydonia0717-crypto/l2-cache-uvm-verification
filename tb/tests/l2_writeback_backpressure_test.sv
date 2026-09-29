class l2_writeback_backpressure_test extends l2_base_test;
  `uvm_component_utils(l2_writeback_backpressure_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.req_stall_pct=60;
    m_cfg.min_read_latency=12;
    m_cfg.max_read_latency=30;
  endfunction

  task run_phase(uvm_phase phase);
    l2_dirty_eviction_seq s=l2_dirty_eviction_seq::type_id::create("s");
    phase.raise_objection(this);
    s.start(env.core0.sqr);
    wait_cycles(650);
    if (env.sb.mem_writebacks==0)
      `uvm_error("WB_BP","expected dirty writeback")
    if (env.cov.mem_req_stall_count==0)
      `uvm_error("WB_BP","memory request backpressure was not observed during dirty-eviction traffic")
    phase.drop_objection(this);
  endtask
endclass
