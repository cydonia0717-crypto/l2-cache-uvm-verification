class l2_mem_agent extends uvm_agent;
  `uvm_component_utils(l2_mem_agent)
  l2_mem_cfg cfg;
  l2_mem_responder rsp;
  l2_mem_monitor mon;
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(l2_mem_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal(get_type_name(),"missing cfg")
    uvm_config_db#(l2_mem_cfg)::set(this,"rsp","cfg",cfg);
    uvm_config_db#(l2_mem_cfg)::set(this,"mon","cfg",cfg);
    rsp=l2_mem_responder::type_id::create("rsp",this);
    mon=l2_mem_monitor::type_id::create("mon",this);
  endfunction
endclass
