class l2_mem_monitor extends uvm_component;
  `uvm_component_utils(l2_mem_monitor)
  l2_mem_cfg cfg;
  virtual l2_mem_if vif;
  uvm_analysis_port #(l2_mem_obs) ap;
  function new(string name, uvm_component parent); super.new(name,parent); ap=new("ap",this); endfunction
  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(l2_mem_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal(get_type_name(),"missing cfg")
    vif=cfg.vif;
  endfunction
  task run_phase(uvm_phase phase);
    l2_mem_obs o;
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.reset) continue;
      if (vif.mon_cb.req_valid && vif.mon_cb.req_ready) begin
        o=l2_mem_obs::type_id::create("mem_req"); o.kind=MEM_REQ;
        o.rw=vif.mon_cb.req_rw; o.addr=vif.mon_cb.req_addr; o.data=vif.mon_cb.req_data;
        o.byteen=vif.mon_cb.req_byteen; o.tag=vif.mon_cb.req_tag; ap.write(o);
      end else if (vif.mon_cb.req_valid && !vif.mon_cb.req_ready) begin
        o=l2_mem_obs::type_id::create("mem_req_stall"); o.kind=MEM_REQ_STALL;
        o.rw=vif.mon_cb.req_rw; o.addr=vif.mon_cb.req_addr; o.tag=vif.mon_cb.req_tag; ap.write(o);
      end
      if (vif.mon_cb.rsp_valid && vif.mon_cb.rsp_ready) begin
        o=l2_mem_obs::type_id::create("mem_rsp"); o.kind=MEM_RSP;
        o.data=vif.mon_cb.rsp_data; o.tag=vif.mon_cb.rsp_tag; ap.write(o);
      end else if (vif.mon_cb.rsp_valid && !vif.mon_cb.rsp_ready) begin
        o=l2_mem_obs::type_id::create("mem_rsp_stall"); o.kind=MEM_RSP_STALL;
        o.data=vif.mon_cb.rsp_data; o.tag=vif.mon_cb.rsp_tag; ap.write(o);
      end
    end
  endtask
endclass
