class l2_mem_responder extends uvm_component;
  `uvm_component_utils(l2_mem_responder)
  l2_mem_cfg cfg;
  virtual l2_mem_if vif;
  byte unsigned dram[longint unsigned];
  l2_pending_rsp pending[$];
  int unsigned cycle_count;
  bit rsp_busy;
  int unsigned read_accept_count;
  l2_pending_rsp active_rsp;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(l2_mem_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal(get_type_name(),"missing l2_mem_cfg")
    vif = cfg.vif;
  endfunction

  function byte unsigned read_byte(longint unsigned a);
    if (dram.exists(a)) return dram[a];
    return l2_default_byte(a);
  endfunction

  function bit [L2_LINE_BITS-1:0] read_line(longint unsigned base);
    bit [L2_LINE_BITS-1:0] line;
    for (int i=0;i<L2_LINE_BYTES;i++) line[i*8 +: 8] = read_byte(base+i);
    return line;
  endfunction

  function void apply_write(longint unsigned base, bit [L2_LINE_BITS-1:0] data,
                            bit [L2_LINE_BYTES-1:0] byteen);
    for (int i=0;i<L2_LINE_BYTES;i++)
      if (byteen[i]) dram[base+i] = data[i*8 +: 8];
  endfunction

  task run_phase(uvm_phase phase);
    vif.rsp_cb.req_ready <= 0;
    vif.rsp_cb.rsp_valid <= 0;
    vif.rsp_cb.rsp_data  <= '0;
    vif.rsp_cb.rsp_tag   <= '0;
    cycle_count = 0;
    rsp_busy = 0;
    read_accept_count = 0;
    forever begin
      @(vif.rsp_cb);
      cycle_count++;
      if (vif.rsp_cb.reset) begin
        vif.rsp_cb.req_ready <= 0;
        vif.rsp_cb.rsp_valid <= 0;
        pending.delete(); rsp_busy=0;
        continue;
      end

      vif.rsp_cb.req_ready <= ($urandom_range(0,99) >= cfg.req_stall_pct);

      if (vif.rsp_cb.req_valid && vif.req_ready) begin
        if (vif.rsp_cb.req_rw) begin
          apply_write(vif.rsp_cb.req_addr, vif.rsp_cb.req_data, vif.rsp_cb.req_byteen);
        end else begin
          l2_pending_rsp p = l2_pending_rsp::type_id::create("pending_rsp");
          p.addr = vif.rsp_cb.req_addr;
          p.tag  = vif.rsp_cb.req_tag;
          p.data = read_line(vif.rsp_cb.req_addr);
          if (cfg.force_ooo) begin
            int unsigned skew = read_accept_count * 3;
            int unsigned lat = (cfg.max_read_latency > skew) ? (cfg.max_read_latency-skew) : cfg.min_read_latency;
            if (lat < cfg.min_read_latency) lat = cfg.min_read_latency;
            p.due_cycle = cycle_count + lat;
          end else begin
            p.due_cycle = cycle_count + $urandom_range(cfg.max_read_latency, cfg.min_read_latency);
          end
          read_accept_count++;
          pending.push_back(p);
        end
      end

      if (rsp_busy) begin
        vif.rsp_cb.rsp_valid <= 1'b1;
        vif.rsp_cb.rsp_data  <= active_rsp.data;
        vif.rsp_cb.rsp_tag   <= active_rsp.tag;
        if (vif.rsp_cb.rsp_ready) begin
          vif.rsp_cb.rsp_valid <= 1'b0;
          rsp_busy = 0;
        end
      end else begin
        int ready_idx[$];
        for (int i=0;i<pending.size();i++)
          if (pending[i].due_cycle <= cycle_count) ready_idx.push_back(i);
        if (ready_idx.size() != 0) begin
          int pick = cfg.force_ooo ? (ready_idx.size()-1) : (cfg.enable_ooo ? $urandom_range(ready_idx.size()-1,0) : 0);
          int idx  = ready_idx[pick];
          active_rsp = pending[idx];
          pending.delete(idx);
          rsp_busy = 1;
          vif.rsp_cb.rsp_valid <= 1'b1;
          vif.rsp_cb.rsp_data  <= active_rsp.data;
          vif.rsp_cb.rsp_tag   <= active_rsp.tag;
        end else begin
          vif.rsp_cb.rsp_valid <= 1'b0;
        end
      end
    end
  endtask
endclass
