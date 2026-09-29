class l2_random_seq extends l2_base_seq;
  `uvm_object_utils(l2_random_seq)
  longint unsigned base;
  int unsigned n=100;
  function new(string name="l2_random_seq"); super.new(name); endfunction
  task body();
    for(int i=0;i<n;i++) begin
      longint unsigned a=base + ($urandom_range(0,4095) & ~7);
      if ($urandom_range(0,99)<35) send_write(a,{$urandom,$urandom},8'hff);
      else send_read(a);
    end
  endtask
endclass

class l2_random_test extends l2_base_test;
  `uvm_component_utils(l2_random_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure(); m_cfg.req_stall_pct=20; m_cfg.min_read_latency=4; m_cfg.max_read_latency=60; m_cfg.enable_ooo=1; c0_cfg.rsp_stall_pct=10; c1_cfg.rsp_stall_pct=10; endfunction
  task run_phase(uvm_phase phase);
    l2_random_seq a=l2_random_seq::type_id::create("a"), b=l2_random_seq::type_id::create("b");
    phase.raise_objection(this); a.base=64'h0100_0000; b.base=64'h0200_0000;
    fork a.start(env.core0.sqr); b.start(env.core1.sqr); join
    wait_cycles(1200); phase.drop_objection(this);
  endtask
endclass
