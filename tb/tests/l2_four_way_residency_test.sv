class l2_four_way_residency_seq extends l2_base_seq;
  `uvm_object_utils(l2_four_way_residency_seq)
  function new(string name="l2_four_way_residency_seq"); super.new(name); endfunction
  task body();
    longint unsigned base=64'h0a00_0000;
    longint unsigned same_set_stride=64*1024;
    // Fill exactly four lines mapping to one set, then touch all four again.
    // A real 4-way set should retain all of them without another refill.
    for (int i=0;i<4;i++) send_read(base+i*same_set_stride);
    for (int i=0;i<4;i++) send_read(base+i*same_set_stride);
  endtask
endclass

class l2_four_way_residency_test extends l2_base_test;
  `uvm_component_utils(l2_four_way_residency_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.min_read_latency=8;
    m_cfg.max_read_latency=18;
    m_cfg.enable_ooo=1;
  endfunction
  task run_phase(uvm_phase phase);
    l2_four_way_residency_seq s=l2_four_way_residency_seq::type_id::create("s");
    phase.raise_objection(this);
    s.start(env.core0.sqr);
    wait_cycles(500);
    if (env.sb.mem_refill_reqs != 4)
      `uvm_error("FOUR_WAY",$sformatf("expected four fills followed by four hits; refill count=%0d",env.sb.mem_refill_reqs))
    if (env.sb.checks != 8)
      `uvm_error("FOUR_WAY",$sformatf("expected 8 read checks, got %0d",env.sb.checks))
    phase.drop_objection(this);
  endtask
endclass
