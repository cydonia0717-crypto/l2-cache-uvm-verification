class l2_core_agent extends uvm_agent;
  `uvm_component_utils(l2_core_agent)
  l2_core_cfg cfg;
  l2_core_sequencer sqr;
  l2_core_driver drv;
  l2_core_monitor mon;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(l2_core_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal(get_type_name(),"missing cfg")
    uvm_config_db#(l2_core_cfg)::set(this,"mon","cfg",cfg);
    mon = l2_core_monitor::type_id::create("mon",this);
    if (cfg.is_active == UVM_ACTIVE) begin
      uvm_config_db#(l2_core_cfg)::set(this,"drv","cfg",cfg);
      sqr = l2_core_sequencer::type_id::create("sqr",this);
      drv = l2_core_driver::type_id::create("drv",this);
      sqr.vif = cfg.vif; sqr.port_id = cfg.port_id;
    end
  endfunction
  function void connect_phase(uvm_phase phase);
    if (cfg.is_active == UVM_ACTIVE) drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
