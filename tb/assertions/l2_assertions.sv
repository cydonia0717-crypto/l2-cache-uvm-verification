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
endmodule
