class l2_ooo_refill_test extends l2_base_test;
  `uvm_component_utils(l2_ooo_refill_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure(); m_cfg.min_read_latency=20; m_cfg.max_read_latency=80; m_cfg.enable_ooo=1; m_cfg.force_ooo=1; m_cfg.req_stall_pct=0; endfunction
  task run_phase(uvm_phase phase);
    l2_outstanding_seq a=l2_outstanding_seq::type_id::create("a");
    l2_outstanding_seq b=l2_outstanding_seq::type_id::create("b");
    phase.raise_objection(this); a.count=4; b.count=4; b.base=64'h0004_0000;
    fork a.start(env.core0.sqr); b.start(env.core1.sqr); join
    wait_cycles(350);
    if (!env.cov.saw_ooo_refill) `uvm_error("OOO_REFILL","out-of-order memory response was not observed")
    phase.drop_objection(this);
  endtask
endclass
