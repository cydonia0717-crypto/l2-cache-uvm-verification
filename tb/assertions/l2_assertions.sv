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


//
// White-box MSHR invariant for upstream Vortex fix 35e85f6.
//
// A newly allocated request must never be linked behind an MSHR entry that is
// being released as a hit in the same cycle.  That entry will never receive a
// fill/dequeue event, so such a link would orphan the younger request forever.
//
module l2_vortex_mshr_internal_assertions #(
  parameter int ID_W = 1
) (
  input logic              clk,
  input logic              reset,
  input logic              allocate_fire,
  input logic              allocate_pending,
  input logic [ID_W-1:0]   allocate_previd,
  input logic              finalize_valid,
  input logic              finalize_is_release,
  input logic [ID_W-1:0]   finalize_id
);
  property p_no_coalesce_onto_releasing_entry;
    @(posedge clk) disable iff (reset)
      !(allocate_fire && finalize_valid && finalize_is_release &&
        allocate_pending && (allocate_previd == finalize_id));
  endproperty

  a_no_coalesce_onto_releasing_entry:
    assert property (p_no_coalesce_onto_releasing_entry)
      else $error("MSHR_RELEASE_COALESCE: allocation linked behind an entry released in the same cycle");
endmodule

bind VX_cache_mshr l2_vortex_mshr_internal_assertions #(
  .ID_W (MSHR_ADDR_WIDTH)
) u_l2_mshr_internal_sva (
  .clk                 (clk),
  .reset               (reset),
  .allocate_fire       (allocate_fire),
  .allocate_pending    (allocate_pending),
  .allocate_previd     (allocate_previd),
  .finalize_valid      (finalize_valid),
  .finalize_is_release (finalize_is_release),
  .finalize_id         (finalize_id)
);
