class l2_clean_eviction_seq extends l2_base_seq;
  `uvm_object_utils(l2_clean_eviction_seq)
  function new(string name="l2_clean_eviction_seq"); super.new(name); endfunction
  task body();
    longint unsigned base=64'h0010_0000;
    longint unsigned same_set_stride=64*1024;
    for (int i=0;i<5;i++) send_read(base+i*same_set_stride);
    send_read(base);
  endtask
endclass

class l2_clean_eviction_test extends l2_base_test;
  `uvm_component_utils(l2_clean_eviction_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  task run_phase(uvm_phase phase);
    l2_clean_eviction_seq s=l2_clean_eviction_seq::type_id::create("s");
    phase.raise_objection(this);
    s.start(env.core0.sqr);
    wait_cycles(450);
    if (env.sb.mem_writebacks!=0)
      `uvm_error("CLEAN_EVICT",$sformatf("clean replacement generated %0d writebacks",env.sb.mem_writebacks))
    phase.drop_objection(this);
  endtask
endclass
