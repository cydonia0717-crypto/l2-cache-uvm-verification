class l2_flush_prepare_seq extends l2_base_seq;
  `uvm_object_utils(l2_flush_prepare_seq)
  longint unsigned base=64'h0400_0000;
  function new(string name="l2_flush_prepare_seq"); super.new(name); endfunction
  task body();
    // One dirty line per bank. No replacement is needed before the flush.
    for (int bank=0; bank<4; bank++)
      send_write(base + bank*64, 64'hf100_0000_0000_0000 + bank, 8'hff);
    send_flush();
  endtask
endclass

class l2_flush_readback_seq extends l2_base_seq;
  `uvm_object_utils(l2_flush_readback_seq)
  longint unsigned base=64'h0400_0000;
  function new(string name="l2_flush_readback_seq"); super.new(name); endfunction
  task body();
    for (int bank=0; bank<4; bank++)
      send_read(base + bank*64);
  endtask
endclass

class l2_flush_test extends l2_base_test;
  `uvm_component_utils(l2_flush_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.min_read_latency=10;
    m_cfg.max_read_latency=24;
    m_cfg.enable_ooo=1;
  endfunction

  task run_phase(uvm_phase phase);
    l2_flush_prepare_seq prep=l2_flush_prepare_seq::type_id::create("prep");
    l2_flush_readback_seq rd=l2_flush_readback_seq::type_id::create("rd");
    int unsigned timeout;
    int unsigned refill_after_flush;

    phase.raise_objection(this);

    // The flush request is held by VX_cache_init until all in-flight traffic
    // drains and the per-bank sweep completes.
    prep.start(env.core0.sqr);

    timeout=0;
    while (env.sb.flush_responses==0 && timeout<400) begin
      wait_cycles(1);
      timeout++;
    end
    if (env.sb.flush_responses != 1)
      `uvm_error("FLUSH","flush completion response was not observed")
    if (env.sb.mem_writebacks < 4)
      `uvm_error("FLUSH",$sformatf("expected >=4 dirty flush writebacks, got %0d",env.sb.mem_writebacks))

    refill_after_flush=env.sb.mem_refill_reqs;
    rd.start(env.core0.sqr);
    wait_cycles(320);

    // Flush invalidates the cached dirty lines. The four readbacks must fetch
    // them again from backing memory, whose contents were updated by writeback.
    if (env.sb.mem_refill_reqs != refill_after_flush + 4)
      `uvm_error("FLUSH",$sformatf("expected 4 post-flush refills, before=%0d after=%0d",
                 refill_after_flush,env.sb.mem_refill_reqs))
    if (env.sb.checks != 4)
      `uvm_error("FLUSH",$sformatf("expected 4 post-flush data checks, got %0d",env.sb.checks))

    phase.drop_objection(this);
  endtask
endclass
