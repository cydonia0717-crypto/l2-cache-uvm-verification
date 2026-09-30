class l2_scoreboard extends uvm_component;
  `uvm_component_utils(l2_scoreboard)
  uvm_analysis_imp_core #(l2_core_obs, l2_scoreboard) core_imp;
  uvm_analysis_imp_mem  #(l2_mem_obs,  l2_scoreboard) mem_imp;

  byte unsigned arch_mem[longint unsigned];
  bit [L2_DATA_W-1:0] exp_read[longint unsigned];
  bit exp_flush[longint unsigned];
  int unsigned checks, errors, flush_responses;
  int unsigned mem_refill_reqs, mem_writebacks;
  longint unsigned writeback_addrs[$];

  function new(string name, uvm_component parent);
    super.new(name,parent); core_imp=new("core_imp",this); mem_imp=new("mem_imp",this);
  endfunction

  function byte unsigned get_byte(longint unsigned a);
    if (arch_mem.exists(a)) return arch_mem[a];
    return l2_default_byte(a);
  endfunction

  function bit [L2_DATA_W-1:0] get_word(longint unsigned a);
    bit [L2_DATA_W-1:0] d;
    for (int i=0;i<L2_STRB_W;i++) d[i*8 +: 8]=get_byte(a+i);
    return d;
  endfunction

  function longint unsigned key(int unsigned port, bit [L2_CORE_TAG_W-1:0] tag);
    return (longint'(port) << L2_CORE_TAG_W) | tag;
  endfunction

  function void write_core(l2_core_obs o);
    longint unsigned k;
    if (o.kind==CORE_REQ) begin
      k=key(o.port_id,o.tag);
      if (o.flush) begin
        exp_flush[k]=1'b1;
      end else if (o.rw) begin
        for (int i=0;i<L2_STRB_W;i++) if (o.byteen[i]) arch_mem[o.addr+i]=o.data[i*8 +: 8];
      end else begin
        if (exp_read.exists(k)) begin
          errors++;
          `uvm_error("SB",$sformatf("duplicate outstanding core tag port=%0d tag=0x%0h",o.port_id,o.tag))
        end
        exp_read[k]=get_word(o.addr);
      end
    end else if (o.kind==CORE_RSP) begin
      k=key(o.port_id,o.tag);
      if (exp_flush.exists(k)) begin
        flush_responses++;
        exp_flush.delete(k);
      end else begin
        checks++;
        if (!exp_read.exists(k)) begin
          errors++;
          `uvm_error("SB",$sformatf("unexpected response port=%0d tag=0x%0h data=0x%0h",o.port_id,o.tag,o.data))
        end else begin
          if (o.data !== exp_read[k]) begin
            errors++;
            `uvm_error("SB",$sformatf("read mismatch p%0d tag=0x%0h exp=0x%0h act=0x%0h",o.port_id,o.tag,exp_read[k],o.data))
          end
          exp_read.delete(k);
        end
      end
    end
  endfunction

  function void write_mem(l2_mem_obs o);
    if (o.kind==MEM_REQ && !o.rw) mem_refill_reqs++;
    if (o.kind==MEM_REQ && o.rw) begin
      mem_writebacks++;
      writeback_addrs.push_back(o.addr);
      for (int i=0;i<L2_LINE_BYTES;i++) begin
        if (o.byteen[i] && o.data[i*8 +: 8] !== get_byte(o.addr+i)) begin
          errors++;
          `uvm_error("SB",$sformatf("writeback mismatch addr=0x%0h byte=%0d exp=%02x act=%02x",
                    o.addr,i,get_byte(o.addr+i),o.data[i*8 +: 8]))
        end
      end
    end
  endfunction

  function void check_phase(uvm_phase phase);
    if (exp_read.num()!=0)
      `uvm_error("SB",$sformatf("%0d core read responses still outstanding",exp_read.num()))
    if (exp_flush.num()!=0)
      `uvm_error("SB",$sformatf("%0d flush responses still outstanding",exp_flush.num()))
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB",$sformatf("data_checks=%0d errors=%0d refill_reqs=%0d writebacks=%0d flush_rsp=%0d",checks,errors,mem_refill_reqs,mem_writebacks,flush_responses),UVM_LOW)
  endfunction
endclass
