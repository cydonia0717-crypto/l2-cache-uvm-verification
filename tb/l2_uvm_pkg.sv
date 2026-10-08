package l2_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  localparam int L2_NUM_PORTS   = 2;
  localparam int L2_ADDR_W      = 64;
  localparam int L2_DATA_W      = 64;
  localparam int L2_STRB_W      = 8;
  localparam int L2_CORE_TAG_W  = 16;
  localparam int L2_LINE_BYTES  = 64;
  localparam int L2_LINE_BITS   = 512;
  localparam int L2_MEM_TAG_W   = 6;
  localparam int L2_MSHR_SIZE   = 8;
  localparam int L2_NUM_BANKS   = 4;
  localparam int L2_NUM_WAYS    = 4;
  localparam int L2_CACHE_BYTES = 256*1024;

  function automatic byte unsigned l2_default_byte(longint unsigned addr);
    return byte'((addr[7:0] ^ addr[15:8] ^ addr[23:16] ^ 8'hA5));
  endfunction

  typedef enum int {CORE_REQ, CORE_RSP, CORE_REQ_STALL, CORE_RSP_STALL} l2_core_evt_e;
  typedef enum int {MEM_REQ, MEM_RSP, MEM_REQ_STALL, MEM_RSP_STALL} l2_mem_evt_e;

  `uvm_analysis_imp_decl(_core)
  `uvm_analysis_imp_decl(_mem)

  `include "agents/core/l2_core_item.sv"
  `include "agents/core/l2_core_cfg.sv"
  `include "agents/core/l2_core_sequencer.sv"
  `include "agents/core/l2_core_driver.sv"
  `include "agents/core/l2_core_monitor.sv"
  `include "agents/core/l2_core_agent.sv"

  `include "agents/mem/l2_mem_item.sv"
  `include "agents/mem/l2_mem_cfg.sv"
  `include "agents/mem/l2_mem_responder.sv"
  `include "agents/mem/l2_mem_monitor.sv"
  `include "agents/mem/l2_mem_agent.sv"

  `include "scoreboard/l2_scoreboard.sv"
  `include "coverage/l2_coverage.sv"
  `include "env/l2_env.sv"
  `include "seq/l2_base_seq.sv"
  `include "seq/l2_smoke_seq.sv"
  `include "seq/l2_outstanding_seq.sv"
  `include "seq/l2_same_line_seq.sv"
  `include "tests/l2_base_test.sv"
  `include "tests/l2_smoke_test.sv"
  `include "tests/l2_mshr_full_test.sv"
  `include "tests/l2_ooo_refill_test.sv"
  `include "tests/l2_same_line_merge_test.sv"
  `include "tests/l2_dirty_eviction_test.sv"
  `include "tests/l2_clean_eviction_test.sv"
  `include "tests/l2_bank_hotspot_test.sv"
  `include "tests/l2_random_test.sv"
  `include "tests/l2_read_hit_test.sv"
  `include "tests/l2_write_allocate_test.sv"
  `include "tests/l2_partial_write_test.sv"
  `include "tests/l2_mem_backpressure_test.sv"
  `include "tests/l2_core_rsp_backpressure_test.sv"
  `include "tests/l2_multi_bank_test.sv"
  `include "tests/l2_mshr_reuse_test.sv"
  `include "tests/l2_reset_recovery_test.sv"
  `include "tests/l2_line_offsets_test.sv"
  `include "tests/l2_global_mshr_pressure_test.sv"
  `include "tests/l2_writeback_backpressure_test.sv"
  `include "tests/l2_refill_writeback_overlap_test.sv"
  `include "tests/l2_flush_test.sv"
  `include "tests/l2_set_slice_sweep_test.sv"
  `include "tests/l2_mem_rsp_backpressure_test.sv"
  `include "tests/l2_four_way_residency_test.sv"
  `include "tests/l2_byteen_sweep_test.sv"
  `include "tests/l2_flush_pipeline_race_test.sv"
  `include "tests/l2_plru_victim_test.sv"
  `include "tests/l2_release_coalesce_race_test.sv"
endpackage
