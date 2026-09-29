class l2_partial_write_seq extends l2_base_seq;
  `uvm_object_utils(l2_partial_write_seq)
  function new(string name="l2_partial_write_seq"); super.new(name); endfunction
  task body();
    send_write(64'h0032_0018,64'hfeed_face_dead_beef,8'b0101_1010);
  endtask
endclass

class l2_partial_write_test extends l2_base_test;
  `uvm_component_utils(l2_partial_write_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  task run_phase(uvm_phase phase);
    l2_same_line_seq rd0=l2_same_line_seq::type_id::create("rd0");
    l2_partial_write_seq wr=l2_partial_write_seq::type_id::create("wr");
    l2_same_line_seq rd1=l2_same_line_seq::type_id::create("rd1");
    phase.raise_objection(this);
    rd0.base=64'h0032_0000; rd0.word=3;
    rd1.base=rd0.base; rd1.word=3;
    rd0.start(env.core0.sqr);
    wait_cycles(120);
    wr.start(env.core0.sqr);
    wait_cycles(40);
    rd1.start(env.core0.sqr);
    wait_cycles(120);
    if (env.sb.mem_refill_reqs != 1)
      `uvm_error("PARTIAL_WRITE",$sformatf("expected one initial refill, got %0d",env.sb.mem_refill_reqs))
    if (env.sb.checks != 2)
      `uvm_error("PARTIAL_WRITE",$sformatf("expected two read checks, got %0d",env.sb.checks))
    phase.drop_objection(this);
  endtask
endclass
