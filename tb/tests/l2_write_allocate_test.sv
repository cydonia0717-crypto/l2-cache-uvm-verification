class l2_write_allocate_seq extends l2_base_seq;
  `uvm_object_utils(l2_write_allocate_seq)
  function new(string name="l2_write_allocate_seq"); super.new(name); endfunction
  task body();
    send_write(64'h0031_0040,64'h0123_4567_89ab_cdef,8'hff);
  endtask
endclass

class l2_write_allocate_test extends l2_base_test;
  `uvm_component_utils(l2_write_allocate_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  task run_phase(uvm_phase phase);
    l2_write_allocate_seq wr=l2_write_allocate_seq::type_id::create("wr");
    l2_same_line_seq rd=l2_same_line_seq::type_id::create("rd");
    phase.raise_objection(this);
    wr.start(env.core0.sqr);
    wait_cycles(140);
    rd.base=64'h0031_0040; rd.word=0;
    rd.start(env.core0.sqr);
    wait_cycles(120);
    if (env.sb.mem_refill_reqs != 1)
      `uvm_error("WRITE_ALLOC",$sformatf("write miss should allocate with one refill; got %0d",env.sb.mem_refill_reqs))
    if (env.sb.checks != 1)
      `uvm_error("WRITE_ALLOC",$sformatf("expected readback check, got %0d",env.sb.checks))
    phase.drop_objection(this);
  endtask
endclass
