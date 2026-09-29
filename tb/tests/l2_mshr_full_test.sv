class l2_mshr_full_test extends l2_base_test;
  `uvm_component_utils(l2_mshr_full_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void configure(); m_cfg.min_read_latency=80; m_cfg.max_read_latency=100; m_cfg.enable_ooo=0; endfunction
  task run_phase(uvm_phase phase);
    l2_outstanding_seq s=l2_outstanding_seq::type_id::create("s");
    bit saw_stall=0;
    phase.raise_objection(this); s.count=9; s.stride=256;
    fork
      s.start(env.core0.sqr);
      begin
        repeat(220) begin
          @(core0_vif.mon_cb);
          if (core0_vif.mon_cb.req_valid && !core0_vif.mon_cb.req_ready) saw_stall=1;
        end
      end
    join
    if (!saw_stall) `uvm_error("MSHR_FULL","expected upstream backpressure was not observed")
    wait_cycles(220); phase.drop_objection(this);
  endtask
endclass
