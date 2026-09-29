class l2_core_monitor extends uvm_component;
  `uvm_component_utils(l2_core_monitor)
  l2_core_cfg cfg;
  virtual l2_core_if vif;
  uvm_analysis_port #(l2_core_obs) ap;

  function new(string name, uvm_component parent);
    super.new(name,parent); ap = new("ap",this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(l2_core_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal(get_type_name(),"missing l2_core_cfg")
    vif = cfg.vif;
  endfunction

  task run_phase(uvm_phase phase);
    l2_core_obs o;
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.reset) continue;
      if (vif.mon_cb.req_valid && vif.mon_cb.req_ready) begin
        o = l2_core_obs::type_id::create("req_obs");
        o.kind=CORE_REQ; o.port_id=cfg.port_id; o.rw=vif.mon_cb.req_rw; o.flush=vif.mon_cb.req_flush;
        o.addr=vif.mon_cb.req_addr; o.data=vif.mon_cb.req_data;
        o.byteen=vif.mon_cb.req_byteen; o.tag=vif.mon_cb.req_tag; ap.write(o);
      end else if (vif.mon_cb.req_valid && !vif.mon_cb.req_ready) begin
        o = l2_core_obs::type_id::create("req_stall_obs");
        o.kind=CORE_REQ_STALL; o.port_id=cfg.port_id; o.rw=vif.mon_cb.req_rw; o.flush=vif.mon_cb.req_flush;
        o.addr=vif.mon_cb.req_addr; o.tag=vif.mon_cb.req_tag; ap.write(o);
      end
      if (vif.mon_cb.rsp_valid && vif.mon_cb.rsp_ready) begin
        o = l2_core_obs::type_id::create("rsp_obs");
        o.kind=CORE_RSP; o.port_id=cfg.port_id; o.data=vif.mon_cb.rsp_data;
        o.tag=vif.mon_cb.rsp_tag; ap.write(o);
      end else if (vif.mon_cb.rsp_valid && !vif.mon_cb.rsp_ready) begin
        o = l2_core_obs::type_id::create("rsp_stall_obs");
        o.kind=CORE_RSP_STALL; o.port_id=cfg.port_id; o.data=vif.mon_cb.rsp_data;
        o.tag=vif.mon_cb.rsp_tag; ap.write(o);
      end
    end
  endtask
endclass
