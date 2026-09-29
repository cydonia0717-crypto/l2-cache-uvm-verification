class l2_env extends uvm_env;
  `uvm_component_utils(l2_env)
  l2_core_agent core0, core1;
  l2_mem_agent mem;
  l2_scoreboard sb;
  l2_coverage cov;
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void build_phase(uvm_phase phase);
    core0=l2_core_agent::type_id::create("core0",this);
    core1=l2_core_agent::type_id::create("core1",this);
    mem=l2_mem_agent::type_id::create("mem",this);
    sb=l2_scoreboard::type_id::create("sb",this);
    cov=l2_coverage::type_id::create("cov",this);
  endfunction
  function void connect_phase(uvm_phase phase);
    core0.mon.ap.connect(sb.core_imp); core1.mon.ap.connect(sb.core_imp);
    core0.mon.ap.connect(cov.core_imp); core1.mon.ap.connect(cov.core_imp);
    mem.mon.ap.connect(sb.mem_imp); mem.mon.ap.connect(cov.mem_imp);
  endfunction
endclass
