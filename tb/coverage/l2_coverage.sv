class l2_coverage extends uvm_component;
  `uvm_component_utils(l2_coverage)
  uvm_analysis_imp_core #(l2_core_obs, l2_coverage) core_imp;
  uvm_analysis_imp_mem  #(l2_mem_obs,  l2_coverage) mem_imp;

  covergroup core_cg with function sample(int kind, int port, bit rw, longint unsigned addr);
    option.per_instance=1;
    cp_kind: coverpoint kind { bins req={CORE_REQ}; bins req_stall={CORE_REQ_STALL}; bins rsp={CORE_RSP}; bins rsp_stall={CORE_RSP_STALL}; }
    cp_port: coverpoint port { bins p0={0}; bins p1={1}; }
    cp_rw: coverpoint rw iff (kind==CORE_REQ) { bins rd={0}; bins wr={1}; }
    cp_offset: coverpoint addr[5:0] iff(kind==CORE_REQ) { bins first={0}; bins middle={[8:48]}; bins last={56}; }
    cp_set_slice: coverpoint addr[15:12] iff(kind==CORE_REQ) { bins all[]={[0:15]}; }
    x_port_rw: cross cp_port, cp_rw;
  endgroup

  covergroup mem_cg with function sample(int kind, bit rw, longint unsigned addr);
    option.per_instance=1;
    cp_kind: coverpoint kind { bins req={MEM_REQ}; bins req_stall={MEM_REQ_STALL}; bins rsp={MEM_RSP}; bins rsp_stall={MEM_RSP_STALL}; }
    cp_rw: coverpoint rw iff(kind==MEM_REQ) { bins refill={0}; bins writeback={1}; }
    cp_line_align: coverpoint addr[5:0] iff(kind==MEM_REQ) { bins aligned={0}; illegal_bins bad=default; }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name,parent); core_imp=new("core_imp",this); mem_imp=new("mem_imp",this);
    core_cg=new(); mem_cg=new();
  endfunction
  function void write_core(l2_core_obs o); core_cg.sample(o.kind,o.port_id,o.rw,o.addr); endfunction
  function void write_mem(l2_mem_obs o); mem_cg.sample(o.kind,o.rw,o.addr); endfunction
endclass
