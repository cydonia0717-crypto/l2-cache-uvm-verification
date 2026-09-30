class l2_set_slice_sweep_seq extends l2_base_seq;
  `uvm_object_utils(l2_set_slice_sweep_seq)
  function new(string name="l2_set_slice_sweep_seq"); super.new(name); endfunction
  task body();
    longint unsigned base=64'h0700_0000;
    for (int slice=0; slice<16; slice++)
      send_read(base | (longint'(slice) << 12));
  endtask
endclass

class l2_set_slice_sweep_test extends l2_base_test;
  `uvm_component_utils(l2_set_slice_sweep_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.min_read_latency=6;
    m_cfg.max_read_latency=18;
    m_cfg.enable_ooo=1;
  endfunction

  task run_phase(uvm_phase phase);
    l2_set_slice_sweep_seq s=l2_set_slice_sweep_seq::type_id::create("s");
    phase.raise_objection(this);
    s.start(env.core0.sqr);
    wait_cycles(600);
    if (env.sb.checks != 16)
      `uvm_error("SET_SWEEP",$sformatf("expected 16 checked reads, got %0d",env.sb.checks))
    phase.drop_objection(this);
  endtask
endclass
