class l2_core_driver extends uvm_driver #(l2_core_item);
  `uvm_component_utils(l2_core_driver)
  l2_core_cfg cfg;
  virtual l2_core_if vif;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(l2_core_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal(get_type_name(),"missing l2_core_cfg")
    vif = cfg.vif;
  endfunction

  task run_phase(uvm_phase phase);
    vif.drv_cb.req_valid <= 0;
    vif.drv_cb.req_rw <= 0;
    vif.drv_cb.req_addr <= '0;
    vif.drv_cb.req_data <= '0;
    vif.drv_cb.req_byteen <= '0;
    vif.drv_cb.req_tag <= '0;
    vif.drv_cb.rsp_ready <= 0;
    fork
      drive_requests();
      drive_rsp_ready();
    join
  endtask

  task drive_requests();
    l2_core_item tr;
    forever begin
      seq_item_port.get_next_item(tr);
      while (vif.drv_cb.reset) @(vif.drv_cb);
      vif.drv_cb.req_valid  <= 1'b1;
      vif.drv_cb.req_rw     <= tr.rw;
      vif.drv_cb.req_addr   <= tr.addr;
      vif.drv_cb.req_data   <= tr.data;
      vif.drv_cb.req_byteen <= tr.byteen;
      vif.drv_cb.req_tag    <= tr.tag;
      do @(vif.drv_cb); while (vif.drv_cb.reset || !vif.drv_cb.req_ready);
      vif.drv_cb.req_valid <= 1'b0;
      seq_item_port.item_done();
    end
  endtask

  task drive_rsp_ready();
    forever begin
      @(vif.drv_cb);
      if (vif.drv_cb.reset)
        vif.drv_cb.rsp_ready <= 1'b0;
      else
        vif.drv_cb.rsp_ready <= ($urandom_range(0,99) >= cfg.rsp_stall_pct);
    end
  endtask
endclass
