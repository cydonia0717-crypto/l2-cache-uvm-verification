class l2_release_coalesce_warm_seq extends l2_base_seq;
  `uvm_object_utils(l2_release_coalesce_warm_seq)
  longint unsigned addr=64'h0e00_0000;
  function new(string name="l2_release_coalesce_warm_seq"); super.new(name); endfunction
  task body(); send_read(addr); endtask
endclass

class l2_release_coalesce_write_burst_seq extends l2_base_seq;
  `uvm_object_utils(l2_release_coalesce_write_burst_seq)
  longint unsigned addr=64'h0e00_0000;
  int unsigned count=24;
  bit [63:0] last_value;
  function new(string name="l2_release_coalesce_write_burst_seq"); super.new(name); endfunction
  task body();
    for (int i=0;i<count;i++) begin
      last_value=64'hA500_0000_0000_0000 | i;
      send_write(addr,last_value,8'hff);
    end
  endtask
endclass

class l2_release_coalesce_read_seq extends l2_base_seq;
  `uvm_object_utils(l2_release_coalesce_read_seq)
  longint unsigned addr=64'h0e00_0000;
  function new(string name="l2_release_coalesce_read_seq"); super.new(name); endfunction
  task body(); send_read(addr); endtask
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
    l2_release_coalesce_write_burst_seq burst=l2_release_coalesce_write_burst_seq::type_id::create("burst");
    l2_release_coalesce_read_seq rd=l2_release_coalesce_read_seq::type_id::create("rd");
    int timeout;
    int refills_before;

    phase.raise_objection(this);
    warm.start(env.core0.sqr);
    timeout=0;
    while (env.sb.checks<1 && timeout<250) begin wait_cycles(1); timeout++; end
    if (env.sb.checks != 1)
      `uvm_error("REL_COAL","warm-up read did not complete")

    refills_before=env.sb.mem_refill_reqs;

    // The upstream Vortex fix 35e85f6 was motivated by heavy same-line WRITE
    // contention. Every resident-line request preallocates an MSHR slot before
    // lookup; adjacent hits make allocation overlap the prior request's
    // finalize/release. A broken matcher can link the new request behind the
    // entry that is being released, leaving it orphaned forever.
    burst.start(env.core0.sqr);
    rd.start(env.core0.sqr);

    timeout=0;
    while (env.sb.checks<2 && timeout<700) begin wait_cycles(1); timeout++; end

    if (env.sb.mem_refill_reqs != refills_before)
      `uvm_error("REL_COAL",$sformatf("resident same-line write burst unexpectedly refilled; before=%0d after=%0d",
                 refills_before,env.sb.mem_refill_reqs))
    if (env.sb.checks != 2)
      `uvm_error("REL_COAL",$sformatf("post-contention read failed to complete; checks=%0d",env.sb.checks))

    phase.drop_objection(this);
  endtask
endclass
