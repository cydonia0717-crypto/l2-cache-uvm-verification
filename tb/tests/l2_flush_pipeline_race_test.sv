class l2_flush_race_warm_seq extends l2_base_seq;
  `uvm_object_utils(l2_flush_race_warm_seq)
  longint unsigned addr=64'h0c00_0000;
  function new(string name="l2_flush_race_warm_seq"); super.new(name); endfunction
  task body();
    send_write(addr,64'h1111_2222_3333_4444,8'hff);
    send_read(addr);
  endtask
endclass

class l2_flush_race_trigger_seq extends l2_base_seq;
  `uvm_object_utils(l2_flush_race_trigger_seq)
  longint unsigned addr=64'h0c00_0000;
  function new(string name="l2_flush_race_trigger_seq"); super.new(name); endfunction
  task body();
    // The write is a hit.  Flush follows immediately so the cache must wait
    // for the bank pipeline/commit path to quiesce before eviction starts.
    send_write(addr,64'hDEAD_BEEF_0123_4567,8'hff);
    send_flush();
  endtask
endclass

class l2_flush_race_readback_seq extends l2_base_seq;
  `uvm_object_utils(l2_flush_race_readback_seq)
  longint unsigned addr=64'h0c00_0000;
  function new(string name="l2_flush_race_readback_seq"); super.new(name); endfunction
  task body(); send_read(addr); endtask
endclass

class l2_flush_pipeline_race_test extends l2_base_test;
  `uvm_component_utils(l2_flush_pipeline_race_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.min_read_latency=8;
    m_cfg.max_read_latency=16;
  endfunction

  task run_phase(uvm_phase phase);
    l2_flush_race_warm_seq warm=l2_flush_race_warm_seq::type_id::create("warm");
    l2_flush_race_trigger_seq race=l2_flush_race_trigger_seq::type_id::create("race");
    l2_flush_race_readback_seq rd=l2_flush_race_readback_seq::type_id::create("rd");
    int timeout;
    int flush_before;

    phase.raise_objection(this);
    warm.start(env.core0.sqr);
    timeout=0;
    while (env.sb.checks<1 && timeout<300) begin wait_cycles(1); timeout++; end
    if (env.sb.checks != 1)
      `uvm_error("FLUSH_RACE","warm-up read did not complete")

    flush_before=env.sb.flush_responses;
    race.start(env.core0.sqr);
    timeout=0;
    while (env.sb.flush_responses==flush_before && timeout<500) begin wait_cycles(1); timeout++; end
    if (env.sb.flush_responses != flush_before+1)
      `uvm_error("FLUSH_RACE","flush completion was not observed")

    rd.start(env.core0.sqr);
    wait_cycles(320);
    if (env.sb.checks != 2)
      `uvm_error("FLUSH_RACE",$sformatf("expected warm-up + post-flush read checks, got %0d",env.sb.checks))
    phase.drop_objection(this);
  endtask
endclass
