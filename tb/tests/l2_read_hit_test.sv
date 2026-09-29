class l2_read_hit_test extends l2_base_test;
  `uvm_component_utils(l2_read_hit_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  task run_phase(uvm_phase phase);
    l2_same_line_seq first=l2_same_line_seq::type_id::create("first");
    l2_same_line_seq second=l2_same_line_seq::type_id::create("second");
    phase.raise_objection(this);
    first.base=64'h0030_0000; first.word=2;
    second.base=first.base; second.word=2;
    first.start(env.core0.sqr);
    wait_cycles(120);
    second.start(env.core0.sqr);
    wait_cycles(120);
    if (env.sb.mem_refill_reqs != 1)
      `uvm_error("READ_HIT",$sformatf("expected exactly 1 refill, got %0d",env.sb.mem_refill_reqs))
    if (env.sb.checks != 2)
      `uvm_error("READ_HIT",$sformatf("expected 2 checked reads, got %0d",env.sb.checks))
    phase.drop_objection(this);
  endtask
endclass
