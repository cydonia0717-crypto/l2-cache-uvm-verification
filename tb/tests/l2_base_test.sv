class l2_base_test extends uvm_test;
  `uvm_component_utils(l2_base_test)
  l2_env env;
  virtual l2_core_if core0_vif, core1_vif;
  virtual l2_mem_if mem_vif;
  l2_core_cfg c0_cfg, c1_cfg;
  l2_mem_cfg m_cfg;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual l2_core_if)::get(this,"","core0_vif",core0_vif))
      `uvm_fatal("CFG","core0_vif not set")
    if (!uvm_config_db#(virtual l2_core_if)::get(this,"","core1_vif",core1_vif))
      `uvm_fatal("CFG","core1_vif not set")
    if (!uvm_config_db#(virtual l2_mem_if)::get(this,"","mem_vif",mem_vif))
      `uvm_fatal("CFG","mem_vif not set")

    c0_cfg=l2_core_cfg::type_id::create("c0_cfg"); c0_cfg.vif=core0_vif; c0_cfg.port_id=0;
    c1_cfg=l2_core_cfg::type_id::create("c1_cfg"); c1_cfg.vif=core1_vif; c1_cfg.port_id=1;
    m_cfg=l2_mem_cfg::type_id::create("m_cfg"); m_cfg.vif=mem_vif;

    configure();
    uvm_config_db#(l2_core_cfg)::set(this,"env.core0","cfg",c0_cfg);
    uvm_config_db#(l2_core_cfg)::set(this,"env.core1","cfg",c1_cfg);
    uvm_config_db#(l2_mem_cfg)::set(this,"env.mem","cfg",m_cfg);
    env=l2_env::type_id::create("env",this);
  endfunction

  virtual function void configure(); endfunction

  task wait_cycles(int n);
    repeat(n) @(core0_vif.mon_cb);
  endtask
endclass
