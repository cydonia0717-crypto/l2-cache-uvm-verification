class l2_prepare_dirty_seq extends l2_base_seq;
  `uvm_object_utils(l2_prepare_dirty_seq)
  function new(string name="l2_prepare_dirty_seq"); super.new(name); endfunction
  task body();
    longint unsigned base=64'h0200_0000;
    longint unsigned same_set_stride=64*1024;
    for (int i=0;i<4;i++) send_write(base+i*same_set_stride,64'habc0_0000+i,8'hff);
  endtask
endclass

class l2_trigger_dirty_evict_seq extends l2_base_seq;
  `uvm_object_utils(l2_trigger_dirty_evict_seq)
  function new(string name="l2_trigger_dirty_evict_seq"); super.new(name); endfunction
  task body();
    send_write(64'h0200_0000 + 4*(64*1024),64'habc0_0004,8'hff);
  endtask
endclass

class l2_refill_writeback_overlap_test extends l2_base_test;
  `uvm_component_utils(l2_refill_writeback_overlap_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.min_read_latency=25;
    m_cfg.max_read_latency=60;
    m_cfg.enable_ooo=1;
    m_cfg.req_stall_pct=10;
  endfunction

  task run_phase(uvm_phase phase);
    l2_prepare_dirty_seq prep=l2_prepare_dirty_seq::type_id::create("prep");
    l2_trigger_dirty_evict_seq ev=l2_trigger_dirty_evict_seq::type_id::create("ev");
    l2_outstanding_seq rd=l2_outstanding_seq::type_id::create("rd");
    phase.raise_objection(this);
    prep.start(env.core0.sqr);
    wait_cycles(320);
    rd.base=64'h0300_0000; rd.count=12; rd.stride=64;
    fork
      ev.start(env.core0.sqr);
      rd.start(env.core1.sqr);
    join
    wait_cycles(700);
    if (env.sb.mem_writebacks==0)
      `uvm_error("REFILL_WB","expected at least one dirty writeback")
    if (env.cov.max_outstanding_refills < 4)
      `uvm_error("REFILL_WB",$sformatf("insufficient refill overlap observed: %0d",env.cov.max_outstanding_refills))
    if (env.sb.checks != 12)
      `uvm_error("REFILL_WB",$sformatf("expected 12 core1 read checks, got %0d",env.sb.checks))
    phase.drop_objection(this);
  endtask
endclass
