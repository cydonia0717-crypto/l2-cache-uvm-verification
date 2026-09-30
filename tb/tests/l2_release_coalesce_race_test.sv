class l2_release_coalesce_warm_seq extends l2_base_seq;
  `uvm_object_utils(l2_release_coalesce_warm_seq)
  longint unsigned addr=64'h0e00_0000;
  function new(string name="l2_release_coalesce_warm_seq"); super.new(name); endfunction
  task body(); send_read(addr); endtask
endclass

class l2_release_coalesce_burst_seq extends l2_base_seq;
  `uvm_object_utils(l2_release_coalesce_burst_seq)
  longint unsigned addr=64'h0e00_0000;
  int unsigned count=12;
  function new(string name="l2_release_coalesce_burst_seq"); super.new(name); endfunction
  task body();
    for (int i=0;i<count;i++) send_read(addr);
  endtask
endclass

class l2_release_coalesce_race_test extends l2_base_test;
  `uvm_component_utils(l2_release_coalesce_race_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.min_read_latency=8;
    m_cfg.max_read_latency=8;
    m_cfg.enable_ooo=0;
  endfunction

  task run_phase(uvm_phase phase);
    l2_release_coalesce_warm_seq warm=l2_release_coalesce_warm_seq::type_id::create("warm");
    l2_release_coalesce_burst_seq burst=l2_release_coalesce_burst_seq::type_id::create("burst");
    int timeout;

    phase.raise_objection(this);
    warm.start(env.core0.sqr);
    timeout=0;
    while (env.sb.checks<1 && timeout<250) begin wait_cycles(1); timeout++; end
    if (env.sb.checks != 1)
      `uvm_error("REL_COAL","warm-up read did not complete")

    // Once resident, a burst of same-line hits enters on adjacent cycles.
    // The MSHR preallocates each request before lookup; the next allocation can
    // therefore coincide with the previous hit's finalize/release.  The fixed
    // RTL excludes that releasing slot from same-line coalescing.
    burst.start(env.core0.sqr);
    wait_cycles(500);

    if (env.sb.mem_refill_reqs != 1)
      `uvm_error("REL_COAL",$sformatf("resident same-line hit burst should not refill; refills=%0d",env.sb.mem_refill_reqs))
    if (env.sb.checks != 13)
      `uvm_error("REL_COAL",$sformatf("expected 13 completed reads, got %0d",env.sb.checks))
    phase.drop_objection(this);
  endtask
endclass
