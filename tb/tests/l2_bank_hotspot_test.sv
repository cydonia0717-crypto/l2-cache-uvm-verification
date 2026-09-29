class l2_bank_hotspot_seq extends l2_base_seq;
  `uvm_object_utils(l2_bank_hotspot_seq)
  longint unsigned base=64'h0020_0000;
  int unsigned count=12;
  function new(string name="l2_bank_hotspot_seq"); super.new(name); endfunction
  task body();
    for (int i=0;i<count;i++) send_read(base+i*256);
  endtask
endclass

class l2_bank_hotspot_test extends l2_base_test;
  `uvm_component_utils(l2_bank_hotspot_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.min_read_latency=15; m_cfg.max_read_latency=50; m_cfg.req_stall_pct=15; m_cfg.enable_ooo=1;
  endfunction
  task run_phase(uvm_phase phase);
    l2_bank_hotspot_seq a=l2_bank_hotspot_seq::type_id::create("a");
    l2_bank_hotspot_seq b=l2_bank_hotspot_seq::type_id::create("b");
    phase.raise_objection(this);
    b.base=64'h0060_0000;
    fork a.start(env.core0.sqr); b.start(env.core1.sqr); join
    wait_cycles(700);
    phase.drop_objection(this);
  endtask
endclass
