// Directed P0: abort active misses with a mid-flight reset, then reuse
// the same core tag values in a clean new epoch.  No dirty data is abandoned.
class l2_reset_recovery_test extends l2_base_test;
  `uvm_component_utils(l2_reset_recovery_test)
  function new(string name,uvm_component parent); super.new(name,parent); endfunction
  function void configure();
    m_cfg.min_read_latency=400;
    m_cfg.max_read_latency=400;
    m_cfg.req_stall_pct=0;
    m_cfg.enable_ooo=0;
    c0_cfg.rsp_stall_pct=0;
    c1_cfg.rsp_stall_pct=0;
  endfunction

  task run_phase(uvm_phase phase);
    l2_outstanding_seq before_rst,after_rst;
    int unsigned timeout;
    phase.raise_objection(this);

    before_rst=l2_outstanding_seq::type_id::create("before_rst");
    before_rst.base=64'h0110_0000;
    before_rst.count=4;
    before_rst.stride=64;
    before_rst.start(env.core0.sqr);

    timeout=0;
    while(env.sb.active_refill_addr.num()<4 && timeout<180) begin
      wait_cycles(1);
      timeout++;
    end
    if(env.sb.active_refill_addr.num()<4 || env.sb.exp_read.num()<4)
      `uvm_error("RESET_RECOVERY",$sformatf(
        "failed to stage four active misses: refill=%0d core_reads=%0d",
        env.sb.active_refill_addr.num(),env.sb.exp_read.num()))
    if(env.sb.checks!=0)
      `uvm_error("RESET_RECOVERY","a pre-reset request unexpectedly completed")

    @(negedge reset_ctrl_vif.clk);
    reset_ctrl_vif.force_reset=1'b1;
    repeat(6) wait_cycles(1);
    @(negedge reset_ctrl_vif.clk);
    reset_ctrl_vif.force_reset=1'b0;
    wait_cycles(60);

    if(env.sb.reset_epochs!=1 || env.sb.reset_dropped_reads<4 ||
       env.sb.reset_dropped_refills<4 ||
       env.sb.active_refill_addr.num()!=0 || env.sb.exp_read.num()!=0)
      `uvm_error("RESET_RECOVERY",$sformatf(
        "reset did not retire previous epoch: epochs=%0d dropped_core=%0d dropped_refills=%0d live_core=%0d live_refills=%0d",
        env.sb.reset_epochs,env.sb.reset_dropped_reads,
        env.sb.reset_dropped_refills,env.sb.exp_read.num(),env.sb.active_refill_addr.num()))

    // A new sequence object intentionally starts with core tags 1..4 again.
    // Old memory-side responses must not alias these new transactions.
    after_rst=l2_outstanding_seq::type_id::create("after_rst");
    after_rst.base=64'h0120_0000;
    after_rst.count=4;
    after_rst.stride=64;
    after_rst.start(env.core0.sqr);
    timeout=0;
    while(env.sb.checks<4 && timeout<1300) begin
      wait_cycles(1);
      timeout++;
    end
    if(env.sb.checks!=4 || env.sb.errors!=0 ||
       env.sb.active_refill_addr.num()!=0 || env.sb.exp_read.num()!=0)
      `uvm_error("RESET_RECOVERY",$sformatf(
        "post-reset readback failed checks=%0d errors=%0d live_refills=%0d live_reads=%0d",
        env.sb.checks,env.sb.errors,env.sb.active_refill_addr.num(),env.sb.exp_read.num()))
    else
      `uvm_info("RESET_RECOVERY",$sformatf(
        "aborted %0d core reads and %0d refills on reset; four new core reads completed",
        env.sb.reset_dropped_reads,env.sb.reset_dropped_refills),UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass
