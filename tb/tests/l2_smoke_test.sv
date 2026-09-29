class l2_smoke_test extends l2_base_test;
  `uvm_component_utils(l2_smoke_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  task run_phase(uvm_phase phase);
    l2_smoke_seq s=l2_smoke_seq::type_id::create("s");
    phase.raise_objection(this); s.start(env.core0.sqr); wait_cycles(250); phase.drop_objection(this);
  endtask
endclass
