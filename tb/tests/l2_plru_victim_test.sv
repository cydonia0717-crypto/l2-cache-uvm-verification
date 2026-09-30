class l2_plru_fill_seq extends l2_base_seq;
  `uvm_object_utils(l2_plru_fill_seq)
  longint unsigned base=64'h0d00_0000;
  function new(string name="l2_plru_fill_seq"); super.new(name); endfunction
  task body();
    longint unsigned stride=64*1024;
    // Four write misses populate one set and make every resident line dirty.
    for (int i=0;i<4;i++)
      send_write(base+i*stride,64'hD100_0000_0000_0000+i,8'hff);
  endtask
endclass

class l2_plru_touch_seq extends l2_base_seq;
  `uvm_object_utils(l2_plru_touch_seq)
  longint unsigned base=64'h0d00_0000;
  function new(string name="l2_plru_touch_seq"); super.new(name); endfunction
  task body(); send_read(base); endtask
endclass

class l2_plru_insert_seq extends l2_base_seq;
  `uvm_object_utils(l2_plru_insert_seq)
  longint unsigned base=64'h0d00_0000;
  function new(string name="l2_plru_insert_seq"); super.new(name); endfunction
  task body(); send_write(base+4*(64*1024),64'hD100_0000_0000_0004,8'hff); endtask
endclass

class l2_plru_victim_test extends l2_base_test;
  `uvm_component_utils(l2_plru_victim_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.min_read_latency=8;
    m_cfg.max_read_latency=16;
    m_cfg.enable_ooo=0;
  endfunction

  task run_phase(uvm_phase phase);
    l2_plru_fill_seq fill=l2_plru_fill_seq::type_id::create("fill");
    l2_plru_touch_seq touch=l2_plru_touch_seq::type_id::create("touch");
    l2_plru_insert_seq ins=l2_plru_insert_seq::type_id::create("ins");
    longint unsigned base=64'h0d00_0000;
    longint unsigned stride=64*1024;
    int timeout;

    phase.raise_objection(this);

    fill.start(env.core0.sqr);
    wait_cycles(450);
    if (env.sb.mem_refill_reqs != 4)
      `uvm_error("PLRU",$sformatf("expected four initial refills, got %0d",env.sb.mem_refill_reqs))

    // With Vortex tree-PLRU initialized to zero, the four fills/replays occupy
    // ways in 0,2,1,3 order.  Touching line0 makes way2 the next victim, which
    // contains line1.
    touch.start(env.core0.sqr);
    timeout=0;
    while (env.sb.checks<1 && timeout<250) begin wait_cycles(1); timeout++; end
    if (env.sb.checks != 1)
      `uvm_error("PLRU","touch read did not complete")

    ins.start(env.core0.sqr);
    wait_cycles(450);

    if (env.sb.writeback_addrs.size()==0)
      `uvm_error("PLRU","no dirty victim writeback observed")
    else if (env.sb.writeback_addrs[0] != base+stride)
      `uvm_error("PLRU",$sformatf("unexpected victim: exp=0x%0h act=0x%0h",
                 base+stride,env.sb.writeback_addrs[0]))

    phase.drop_objection(this);
  endtask
endclass
