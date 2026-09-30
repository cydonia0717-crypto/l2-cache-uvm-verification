module l2_core_assertions(l2_core_if vif);
  property p_req_hold;
    @(posedge vif.clk) disable iff(vif.reset)
      vif.req_valid && !vif.req_ready |=> vif.req_valid &&
      $stable({vif.req_rw,vif.req_flush,vif.req_addr,vif.req_data,vif.req_byteen,vif.req_tag});
  endproperty
  a_req_hold: assert property(p_req_hold);

  property p_rsp_hold;
    @(posedge vif.clk) disable iff(vif.reset)
      vif.rsp_valid && !vif.rsp_ready |=> vif.rsp_valid && $stable({vif.rsp_data,vif.rsp_tag});
  endproperty
  a_rsp_hold: assert property(p_rsp_hold);
endmodule

module l2_mem_assertions(l2_mem_if vif);
  property p_mem_req_hold;
    @(posedge vif.clk) disable iff(vif.reset)
      vif.req_valid && !vif.req_ready |=> vif.req_valid &&
      $stable({vif.req_rw,vif.req_addr,vif.req_data,vif.req_byteen,vif.req_tag});
  endproperty
  a_mem_req_hold: assert property(p_mem_req_hold);

  property p_mem_rsp_hold;
    @(posedge vif.clk) disable iff(vif.reset)
      vif.rsp_valid && !vif.rsp_ready |=> vif.rsp_valid && $stable({vif.rsp_data,vif.rsp_tag});
  endproperty
  a_mem_rsp_hold: assert property(p_mem_rsp_hold);

  property p_mem_req_line_aligned;
    @(posedge vif.clk) disable iff(vif.reset)
      vif.req_valid && vif.req_ready |-> vif.req_addr[5:0] == 6'b0;
  endproperty
  a_mem_req_line_aligned: assert property(p_mem_req_line_aligned);
endmodule


//
// White-box invariant for the upstream Vortex flush controller.
//
// Historical Vortex fix a686ceec changed STATE_WAIT1 so eviction can begin
// only after both the MSHR and the bank pipeline/memory-request queue drain.
// This assertion deliberately checks the microarchitectural invariant rather
// than waiting for a later end-to-end data corruption, which is timing
// dependent.  It is valuable in normal regression and also makes the
// historical mutation test deterministic.
//
module l2_vortex_flush_internal_assertions (
  input logic       clk,
  input logic       reset,
  input logic [2:0] state,
  input logic       mshr_empty,
  input logic       bank_empty
);
  localparam logic [2:0] STATE_WAIT1 = 3'd2;

  property p_wait_for_bank_quiescent;
    @(posedge clk) disable iff (reset)
      (state == STATE_WAIT1 && mshr_empty && !bank_empty)
      |=> (state == STATE_WAIT1);
  endproperty

  a_wait_for_bank_quiescent: assert property (p_wait_for_bank_quiescent)
    else $error("FLUSH_RACE: flush left WAIT1 while bank pipeline/request queue was not empty");
endmodule

bind VX_cache_flush l2_vortex_flush_internal_assertions u_l2_flush_internal_sva (
  .clk        (clk),
  .reset      (reset),
  .state      (state),
  .mshr_empty (mshr_empty),
  .bank_empty (bank_empty)
);
