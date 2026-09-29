class l2_multi_bank_seq extends l2_base_seq;
  `uvm_object_utils(l2_multi_bank_seq)
  function new(string name="l2_multi_bank_seq"); super.new(name); endfunction
  task body();
    longint unsigned base=64'h0035_0000;
    for (int bank=0; bank<4; bank++) send_read(base + bank*64);
  endtask
endclass

class l2_multi_bank_test extends l2_base_test;
  `uvm_component_utils(l2_multi_bank_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.min_read_latency=40;
    m_cfg.max_read_latency=40;
  endfunction

  task run_phase(uvm_phase phase);
    l2_multi_bank_seq s=l2_multi_bank_seq::type_id::create("s");
    phase.raise_objection(this);
    s.start(env.core0.sqr);
    wait_cycles(260);
    if (env.cov.seen_mem_banks != 4'b1111)
      `uvm_error("MULTI_BANK",$sformatf("expected all banks, saw mask 0x%0h",env.cov.seen_mem_banks))
    if (env.cov.max_outstanding_refills < 4)
      `uvm_error("MULTI_BANK",$sformatf("expected >=4 concurrent refills, saw %0d",env.cov.max_outstanding_refills))
    phase.drop_objection(this);
  endtask
endclass
