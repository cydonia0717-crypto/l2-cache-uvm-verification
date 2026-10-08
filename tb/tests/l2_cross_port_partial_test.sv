// P1: two upstream ports update opposite halves of each same cache word.
// Disjoint byte enables make the final result deterministic regardless of
// arbitration order; readback detects lost writes or incorrect byte merges.
class l2_cross_port_write_seq extends l2_base_seq;
  `uvm_object_utils(l2_cross_port_write_seq)
  int unsigned port_id=0;
  localparam longint unsigned BASE=64'h0130_0000;
  function new(string name="l2_cross_port_write_seq"); super.new(name); endfunction
  task body();
    longint unsigned addr;
    for(int i=0;i<16;i++) begin
      addr=BASE+((i/4)*256)+((i%4)*64)+((i/4)*8);
      if(port_id==0)
        send_write(addr,64'h1122_3344_5566_7788,8'h0f);
      else
        send_write(addr,64'h99aa_bbcc_ddee_ff00,8'hf0);
    end
  endtask
endclass

class l2_cross_port_readback_seq extends l2_base_seq;
  `uvm_object_utils(l2_cross_port_readback_seq)
  localparam longint unsigned BASE=64'h0130_0000;
  function new(string name="l2_cross_port_readback_seq"); super.new(name); endfunction
  task body();
    longint unsigned addr;
    for(int i=0;i<16;i++) begin
      addr=BASE+((i/4)*256)+((i%4)*64)+((i/4)*8);
      send_read(addr);
    end
  endtask
endclass

class l2_cross_port_partial_test extends l2_base_test;
  `uvm_component_utils(l2_cross_port_partial_test)
  function new(string name,uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.min_read_latency=15;
    m_cfg.max_read_latency=55;
    m_cfg.req_stall_pct=15;
    m_cfg.enable_ooo=1;
    c0_cfg.rsp_stall_pct=20;
    c1_cfg.rsp_stall_pct=20;
  endfunction
  task run_phase(uvm_phase phase);
    l2_cross_port_write_seq a,b;
    l2_cross_port_readback_seq rd;
    phase.raise_objection(this);
    a=l2_cross_port_write_seq::type_id::create("write_low");
    b=l2_cross_port_write_seq::type_id::create("write_high");
    rd=l2_cross_port_readback_seq::type_id::create("readback");
    a.port_id=0;
    b.port_id=1;
    fork
      a.start(env.core0.sqr);
      b.start(env.core1.sqr);
    join
    wait_cycles(500);
    rd.start(env.core0.sqr);
    wait_cycles(450);

    if(env.sb.checks!=16 || env.sb.errors!=0)
      `uvm_error("CROSS_PORT",$sformatf(
        "cross-port partial readback failed: checks=%0d errors=%0d",
        env.sb.checks,env.sb.errors))
    if(env.cov.seen_mem_banks!=4'hf)
      `uvm_error("CROSS_PORT",$sformatf(
        "expected all four banks, observed 0x%0h",env.cov.seen_mem_banks))
    if(env.cov.cross_port_disjoint_write_words!=16)
      `uvm_error("CROSS_PORT",$sformatf(
        "expected 16 accepted dual-port disjoint-byte write pairs, observed %0d",
        env.cov.cross_port_disjoint_write_words))
    if(env.sb.checks==16 && env.sb.errors==0 &&
       env.cov.cross_port_disjoint_write_words==16)
      `uvm_info("CROSS_PORT","16 dual-port disjoint-byte write pairs merged correctly across 4 banks",UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass
