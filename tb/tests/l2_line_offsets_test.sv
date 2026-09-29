class l2_line_offsets_seq extends l2_base_seq;
  `uvm_object_utils(l2_line_offsets_seq)
  function new(string name="l2_line_offsets_seq"); super.new(name); endfunction
  task body();
    longint unsigned base=64'h0037_0000;
    for (int word=0; word<8; word++) send_read(base + word*8);
  endtask
endclass

class l2_line_offsets_test extends l2_base_test;
  `uvm_component_utils(l2_line_offsets_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.min_read_latency=45;
    m_cfg.max_read_latency=45;
  endfunction

  task run_phase(uvm_phase phase);
    l2_line_offsets_seq s=l2_line_offsets_seq::type_id::create("s");
    phase.raise_objection(this);
    s.start(env.core0.sqr);
    wait_cycles(320);
    if (env.sb.mem_refill_reqs != 1)
      `uvm_error("LINE_OFFSETS",$sformatf("8 words in one missing line should coalesce to 1 refill; got %0d",env.sb.mem_refill_reqs))
    if (env.sb.checks != 8)
      `uvm_error("LINE_OFFSETS",$sformatf("expected 8 read responses, got %0d",env.sb.checks))
    phase.drop_objection(this);
  endtask
endclass
