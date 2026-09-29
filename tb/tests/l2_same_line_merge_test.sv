class l2_same_line_merge_test extends l2_base_test;
  `uvm_component_utils(l2_same_line_merge_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure(); m_cfg.min_read_latency=40; m_cfg.max_read_latency=40; endfunction
  task run_phase(uvm_phase phase);
    l2_same_line_seq a=l2_same_line_seq::type_id::create("a");
    l2_same_line_seq b=l2_same_line_seq::type_id::create("b");
    phase.raise_objection(this); a.word=0; b.word=3;
    fork a.start(env.core0.sqr); b.start(env.core1.sqr); join
    wait_cycles(180);
    if (!env.cov.saw_same_line_pending) `uvm_error("SAME_LINE","same-line pending condition was not observed")
    phase.drop_objection(this);
  endtask
endclass
