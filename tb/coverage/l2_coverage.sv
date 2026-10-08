class l2_coverage extends uvm_component;
  `uvm_component_utils(l2_coverage)
  uvm_analysis_imp_core #(l2_core_obs, l2_coverage) core_imp;
  uvm_analysis_imp_mem  #(l2_mem_obs,  l2_coverage) mem_imp;

  int unsigned outstanding_refills;
  int unsigned max_outstanding_refills;
  bit saw_ooo_refill;
  bit saw_same_line_pending;
  int unsigned core_req_stall_count;
  int unsigned core_rsp_stall_count;
  int unsigned mem_req_stall_count;
  int unsigned mem_rsp_stall_count;
  bit [L2_NUM_PORTS-1:0] core_traffic_started;
  bit [L2_NUM_BANKS-1:0] seen_mem_banks;
  bit [L2_MEM_TAG_W-1:0] mem_read_order[$];
  bit [L2_STRB_W-1:0] write_mask_p0[longint unsigned];
  bit [L2_STRB_W-1:0] write_mask_p1[longint unsigned];
  bit cross_port_write_counted[longint unsigned];
  int unsigned cross_port_disjoint_write_words;
  bit refill_tag_seen[bit [L2_MEM_TAG_W-1:0]];
  virtual l2_core_if reset_vif;
  longint unsigned read_line_by_key[longint unsigned];
  int unsigned line_pending[longint unsigned];

  covergroup core_cg with function sample(int kind, int port, bit rw, bit flush, longint unsigned addr, bit same_line_pending);
    option.per_instance=1;
    cp_kind: coverpoint kind { bins req={CORE_REQ}; bins req_stall={CORE_REQ_STALL}; bins rsp={CORE_RSP}; bins rsp_stall={CORE_RSP_STALL}; }
    cp_port: coverpoint port { bins p0={0}; bins p1={1}; }
    cp_rw: coverpoint rw iff (kind==CORE_REQ && !flush) { bins rd={0}; bins wr={1}; }
    cp_flush: coverpoint flush iff (kind==CORE_REQ) { bins normal={0}; bins flush_req={1}; }
    cp_offset: coverpoint addr[5:0] iff(kind==CORE_REQ) { bins first={0}; bins middle={[8:48]}; bins last={56}; }
    cp_set_slice: coverpoint addr[15:12] iff(kind==CORE_REQ) { bins all[]={[0:15]}; }
    cp_same_line_pending: coverpoint same_line_pending iff(kind==CORE_REQ && !rw) { bins no={0}; bins yes={1}; }
    x_port_rw: cross cp_port, cp_rw;
  endgroup

  covergroup mem_cg with function sample(int kind, bit rw, longint unsigned addr, int unsigned depth, bit reordered);
    option.per_instance=1;
    cp_kind: coverpoint kind { bins req={MEM_REQ}; bins req_stall={MEM_REQ_STALL}; bins rsp={MEM_RSP}; ignore_bins rsp_stall={MEM_RSP_STALL}; }
    cp_rw: coverpoint rw iff(kind==MEM_REQ) { bins refill={0}; bins writeback={1}; }
    // Misaligned downstream requests are a protocol failure, not a coverage
    // target.  Alignment is enforced independently by SVA.
    cp_line_align: coverpoint addr[5:0] iff(kind==MEM_REQ) { bins aligned={0}; ignore_bins bad=default; }
    cp_bank: coverpoint addr[7:6] iff(kind==MEM_REQ) { bins b0={0}; bins b1={1}; bins b2={2}; bins b3={3}; }
    cp_outstanding_depth: coverpoint depth {
      bins zero={0}; bins one={1}; bins low={[2:4]}; bins high={[5:7]}; bins full_or_more={[8:32]};
    }
    cp_reordered_rsp: coverpoint reordered iff(kind==MEM_RSP) { bins in_order={0}; bins out_of_order={1}; }
  endgroup

  covergroup cross_port_write_cg with function sample(bit observed);
    option.per_instance=1;
    cp_disjoint_write_pair: coverpoint observed {
      bins both_ports_disjoint={1};
    }
  endgroup

  covergroup tag_lifecycle_cg with function sample(bit reused);
    option.per_instance=1;
    cp_tag_lifecycle: coverpoint reused {
      bins first_allocation={0};
      bins reuse_after_retirement={1};
    }
  endgroup

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual l2_core_if)::get(this,"","reset_vif",reset_vif))
      `uvm_fatal("COV","missing reset_vif")
  endfunction

  task run_phase(uvm_phase phase);
    bit reset_prev=1'b1;
    forever begin
      @(posedge reset_vif.clk);
      if (reset_vif.reset && !reset_prev) begin
        outstanding_refills=0;
        mem_read_order.delete();
        read_line_by_key.delete();
        line_pending.delete();
        core_traffic_started='0;
        write_mask_p0.delete();
        write_mask_p1.delete();
        cross_port_write_counted.delete();
      end
      reset_prev=reset_vif.reset;
    end
  endtask

  function new(string name, uvm_component parent);
    super.new(name,parent); core_imp=new("core_imp",this); mem_imp=new("mem_imp",this);
    core_cg=new(); mem_cg=new(); tag_lifecycle_cg=new(); cross_port_write_cg=new();
    outstanding_refills=0; max_outstanding_refills=0; saw_ooo_refill=0; saw_same_line_pending=0;
    core_req_stall_count=0; core_rsp_stall_count=0; mem_req_stall_count=0; mem_rsp_stall_count=0;
    core_traffic_started='0; seen_mem_banks='0;
  endfunction

  function longint unsigned core_key(int unsigned port, bit [L2_CORE_TAG_W-1:0] tag);
    return (longint'(port) << L2_CORE_TAG_W) | tag;
  endfunction

  function void write_core(l2_core_obs o);
    bit same_line=0;
    longint unsigned k, line;
    k=core_key(o.port_id,o.tag);
    if (o.kind==CORE_REQ && !o.rw) begin
      line=o.addr & ~(longint'(L2_LINE_BYTES-1));
      same_line=line_pending.exists(line) && line_pending[line]!=0;
      if (same_line) saw_same_line_pending=1;
      line_pending[line] = line_pending.exists(line) ? line_pending[line]+1 : 1;
      read_line_by_key[k]=line;
    end else if (o.kind==CORE_RSP && read_line_by_key.exists(k)) begin
      line=read_line_by_key[k];
      if (line_pending.exists(line) && line_pending[line]>0) begin
        line_pending[line]--;
        if (line_pending[line]==0) line_pending.delete(line);
      end
      read_line_by_key.delete(k);
    end
    if (o.kind==CORE_REQ && o.rw && !o.flush) begin
      if(o.port_id==0)
        write_mask_p0[o.addr]=(write_mask_p0.exists(o.addr)?write_mask_p0[o.addr]:8'h00)|o.byteen;
      else if(o.port_id==1)
        write_mask_p1[o.addr]=(write_mask_p1.exists(o.addr)?write_mask_p1[o.addr]:8'h00)|o.byteen;
      if(write_mask_p0.exists(o.addr) && write_mask_p1.exists(o.addr) &&
         !cross_port_write_counted.exists(o.addr) &&
         ((write_mask_p0[o.addr] & write_mask_p1[o.addr])==0)) begin
        cross_port_write_counted[o.addr]=1;
        cross_port_disjoint_write_words++;
        cross_port_write_cg.sample(1'b1);
      end
    end
    if (o.kind==CORE_REQ) core_traffic_started[o.port_id]=1'b1;
    if (o.kind==CORE_REQ_STALL && core_traffic_started[o.port_id]) core_req_stall_count++;
    if (o.kind==CORE_RSP_STALL) core_rsp_stall_count++;
    core_cg.sample(o.kind,o.port_id,o.rw,o.flush,o.addr,same_line);
  endfunction

  function void write_mem(l2_mem_obs o);
    bit reordered=0;
    if (o.kind==MEM_REQ_STALL) mem_req_stall_count++;
    if (o.kind==MEM_RSP_STALL) mem_rsp_stall_count++;
    if (o.kind==MEM_REQ) seen_mem_banks[o.addr[7:6]] = 1'b1;
    if (o.kind==MEM_REQ && !o.rw) begin
      tag_lifecycle_cg.sample(refill_tag_seen.exists(o.tag));
      refill_tag_seen[o.tag]=1;
      mem_read_order.push_back(o.tag);
      outstanding_refills++;
      if (outstanding_refills>max_outstanding_refills) max_outstanding_refills=outstanding_refills;
    end else if (o.kind==MEM_RSP) begin
      int idx=-1;
      for (int i=0;i<mem_read_order.size();i++) begin
        if (mem_read_order[i]==o.tag) begin idx=i; break; end
      end
      if (idx>=0) begin
        reordered=(idx!=0);
        if (reordered) saw_ooo_refill=1;
        mem_read_order.delete(idx);
      end
      if (outstanding_refills>0) outstanding_refills--;
    end
    mem_cg.sample(o.kind,o.rw,o.addr,outstanding_refills,reordered);
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV",$sformatf("max_mem_outstanding=%0d saw_ooo=%0b saw_same_line_pending=%0b core_req_stall=%0d core_rsp_stall=%0d mem_req_stall=%0d mem_rsp_stall=%0d banks=0x%0h",
      max_outstanding_refills,saw_ooo_refill,saw_same_line_pending,
      core_req_stall_count,core_rsp_stall_count,mem_req_stall_count,mem_rsp_stall_count,seen_mem_banks),UVM_LOW)
  endfunction
endclass
