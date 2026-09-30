class l2_mem_rsp_backpressure_test extends l2_base_test;
  `uvm_component_utils(l2_mem_rsp_backpressure_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void configure();
    c0_cfg.rsp_stall_pct=100;
    c1_cfg.rsp_stall_pct=100;
    m_cfg.min_read_latency=4;
    m_cfg.max_read_latency=8;
    m_cfg.enable_ooo=1;
  endfunction

  task run_phase(uvm_phase phase);
    l2_outstanding_seq a=l2_outstanding_seq::type_id::create("a");
    l2_outstanding_seq b=l2_outstanding_seq::type_id::create("b");

    phase.raise_objection(this);
    a.base=64'h0800_0000; a.count=16; a.stride=64;
    b.base=64'h0900_0000; b.count=16; b.stride=64;

    fork
      a.start(env.core0.sqr);
      b.start(env.core1.sqr);
      begin
        // Hold core responses long enough for the cache-side memory response
        // queue/pipeline to fill, then release it so the test can drain.
        wait_cycles(180);
        c0_cfg.rsp_stall_pct=0;
        c1_cfg.rsp_stall_pct=0;
      end
    join

    wait_cycles(900);
    if (env.cov.mem_rsp_stall_count==0)
      `uvm_error("MEM_RSP_BP","memory response backpressure was not observed")
    if (env.sb.checks != 32)
      `uvm_error("MEM_RSP_BP",$sformatf("expected 32 checked reads, got %0d",env.sb.checks))
    phase.drop_objection(this);
  endtask
endclass
