class l2_byteen_sweep_seq extends l2_base_seq;
  `uvm_object_utils(l2_byteen_sweep_seq)
  longint unsigned base=64'h0b00_0000;
  function new(string name="l2_byteen_sweep_seq"); super.new(name); endfunction
  task body();
    bit [63:0] d;
    // Bring the line in once; every subsequent store should be a write hit.
    send_read(base);
    for (int be=1; be<256; be++) begin
      d = 64'hA55A_0123_89AB_CDEF ^ (longint'(be) * 64'h0101_0101_0101_0101);
      send_write(base,d,bit'(be[7:0]));
      send_read(base);
    end
  endtask
endclass

class l2_byteen_sweep_test extends l2_base_test;
  `uvm_component_utils(l2_byteen_sweep_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.min_read_latency=6;
    m_cfg.max_read_latency=12;
  endfunction
  task run_phase(uvm_phase phase);
    l2_byteen_sweep_seq s=l2_byteen_sweep_seq::type_id::create("s");
    phase.raise_objection(this);
    s.start(env.core0.sqr);
    wait_cycles(2600);
    if (env.sb.mem_refill_reqs != 1)
      `uvm_error("BYTEEN",$sformatf("byte-enable sweep should stay resident after first fill; refills=%0d",env.sb.mem_refill_reqs))
    if (env.sb.checks != 256)
      `uvm_error("BYTEEN",$sformatf("expected 256 read checks, got %0d",env.sb.checks))
    phase.drop_objection(this);
  endtask
endclass
