class l2_flush_race_warm_seq extends l2_base_seq;
  `uvm_object_utils(l2_flush_race_warm_seq)
  longint unsigned addr=64'h0c00_0000;
  function new(string name="l2_flush_race_warm_seq"); super.new(name); endfunction
  task body();
    send_write(addr,64'h1111_2222_3333_4444,8'hff);
    send_read(addr);
  endtask
endclass

class l2_flush_race_write_seq extends l2_base_seq;
  `uvm_object_utils(l2_flush_race_write_seq)
  longint unsigned addr=64'h0c00_0000;
  bit [63:0] value=64'hDEAD_BEEF_0123_4567;
  function new(string name="l2_flush_race_write_seq"); super.new(name); endfunction
  task body(); send_write(addr,value,8'hff); endtask
endclass

class l2_flush_race_flush_seq extends l2_base_seq;
  `uvm_object_utils(l2_flush_race_flush_seq)
  function new(string name="l2_flush_race_flush_seq"); super.new(name); endfunction
  task body(); send_flush(); endtask
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
    l2_flush_race_write_seq wr=l2_flush_race_write_seq::type_id::create("wr");
    l2_flush_race_flush_seq fl=l2_flush_race_flush_seq::type_id::create("fl");
    l2_flush_race_readback_seq rd=l2_flush_race_readback_seq::type_id::create("rd");
    int timeout;
    int flush_before;
    bit hit_write_accepted=0;

    phase.raise_objection(this);

    // Make the target line resident and cleanly finish the miss/replay path.
    warm.start(env.core0.sqr);
    timeout=0;
    while (env.sb.checks<1 && timeout<300) begin wait_cycles(1); timeout++; end
    if (env.sb.checks != 1)
      `uvm_error("FLUSH_RACE","warm-up read did not complete")

    // Historical Vortex bug a686ceec: flush waited only for MSHR empty, not
    // for the bank pipeline to drain.  Drive a resident-line write hit on p0,
    // observe its *input handshake*, and launch the global flush from p1 on
    // the immediately following scheduling opportunity.  At that point the
    // write has left the interface but is still traversing lookup/commit.
    flush_before=env.sb.flush_responses;
    fork
      wr.start(env.core0.sqr);
      begin
        timeout=0;
        while (!hit_write_accepted && timeout<100) begin
          @(core0_vif.mon_cb);
          if (!core0_vif.mon_cb.reset &&
              core0_vif.mon_cb.req_valid && core0_vif.mon_cb.req_ready &&
              core0_vif.mon_cb.req_rw && !core0_vif.mon_cb.req_flush &&
              core0_vif.mon_cb.req_addr==wr.addr)
            hit_write_accepted=1;
          timeout++;
        end
        if (!hit_write_accepted)
          `uvm_error("FLUSH_RACE","target hit-write handshake was not observed")
        fl.start(env.core1.sqr);
      end
    join

    timeout=0;
    while (env.sb.flush_responses==flush_before && timeout<500) begin
      wait_cycles(1); timeout++;
    end
    if (env.sb.flush_responses != flush_before+1)
      `uvm_error("FLUSH_RACE","flush completion was not observed")

    // The accepted write must have committed before the flush sweep evicted
    // the line.  A post-flush refill therefore has to return the new value.
    rd.start(env.core0.sqr);
    wait_cycles(320);
    if (env.sb.checks != 2)
      `uvm_error("FLUSH_RACE",$sformatf("expected warm-up + post-flush read checks, got %0d",env.sb.checks))
    if (env.sb.mem_writebacks < 1)
      `uvm_error("FLUSH_RACE","expected dirty target line to be written back by flush")

    phase.drop_objection(this);
  endtask
endclass
