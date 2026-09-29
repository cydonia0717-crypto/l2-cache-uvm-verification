`include "VX_cache_define.vh"

module tb_top;
  import uvm_pkg::*;
  import l2_uvm_pkg::*;

  localparam int NUM_REQS   = 2;
  localparam int MEM_PORTS  = 1;
  localparam int ADDR_W     = 64;
  localparam int DATA_W     = 64;
  localparam int TAG_W      = 16;
  localparam int LINE_BYTES = 64;
  localparam int MEM_TAG_W  = `CACHE_MEM_TAG_WIDTH(8,4,1,VX_gpu_pkg::UUID_WIDTH);

  logic clk=0;
  logic reset=1;
  always #5 clk=~clk;

  l2_core_if #(.ADDR_W(ADDR_W),.DATA_W(DATA_W),.TAG_W(TAG_W)) core0_if(clk);
  l2_core_if #(.ADDR_W(ADDR_W),.DATA_W(DATA_W),.TAG_W(TAG_W)) core1_if(clk);
  l2_mem_if  #(.ADDR_W(ADDR_W),.LINE_BYTES(LINE_BYTES),.TAG_W(MEM_TAG_W)) mem_if(clk);

  wire core_req_valid [NUM_REQS];
  wire core_req_ready [NUM_REQS];
  wire core_req_rw [NUM_REQS];
  wire core_req_flush [NUM_REQS];
  wire [ADDR_W-1:0] core_req_addr [NUM_REQS];
  wire [DATA_W-1:0] core_req_data [NUM_REQS];
  wire [7:0] core_req_byteen [NUM_REQS];
  wire [TAG_W-1:0] core_req_tag [NUM_REQS];
  wire core_rsp_valid [NUM_REQS];
  wire core_rsp_ready [NUM_REQS];
  wire [DATA_W-1:0] core_rsp_data [NUM_REQS];
  wire [TAG_W-1:0] core_rsp_tag [NUM_REQS];

  wire mem_req_valid [MEM_PORTS];
  wire mem_req_ready [MEM_PORTS];
  wire mem_req_rw [MEM_PORTS];
  wire [ADDR_W-1:0] mem_req_addr [MEM_PORTS];
  wire [LINE_BYTES*8-1:0] mem_req_data [MEM_PORTS];
  wire [LINE_BYTES-1:0] mem_req_byteen [MEM_PORTS];
  wire [MEM_TAG_W-1:0] mem_req_tag [MEM_PORTS];
  wire mem_rsp_valid [MEM_PORTS];
  wire mem_rsp_ready [MEM_PORTS];
  wire [LINE_BYTES*8-1:0] mem_rsp_data [MEM_PORTS];
  wire [MEM_TAG_W-1:0] mem_rsp_tag [MEM_PORTS];

  assign core0_if.reset=reset; assign core1_if.reset=reset; assign mem_if.reset=reset;

  assign core_req_valid[0]=core0_if.req_valid; assign core_req_rw[0]=core0_if.req_rw;
  assign core_req_flush[0]=core0_if.req_flush;
  assign core_req_addr[0]=core0_if.req_addr; assign core_req_data[0]=core0_if.req_data;
  assign core_req_byteen[0]=core0_if.req_byteen; assign core_req_tag[0]=core0_if.req_tag;
  assign core0_if.req_ready=core_req_ready[0]; assign core0_if.rsp_valid=core_rsp_valid[0];
  assign core0_if.rsp_data=core_rsp_data[0]; assign core0_if.rsp_tag=core_rsp_tag[0];
  assign core_rsp_ready[0]=core0_if.rsp_ready;

  assign core_req_valid[1]=core1_if.req_valid; assign core_req_rw[1]=core1_if.req_rw;
  assign core_req_flush[1]=core1_if.req_flush;
  assign core_req_addr[1]=core1_if.req_addr; assign core_req_data[1]=core1_if.req_data;
  assign core_req_byteen[1]=core1_if.req_byteen; assign core_req_tag[1]=core1_if.req_tag;
  assign core1_if.req_ready=core_req_ready[1]; assign core1_if.rsp_valid=core_rsp_valid[1];
  assign core1_if.rsp_data=core_rsp_data[1]; assign core1_if.rsp_tag=core_rsp_tag[1];
  assign core_rsp_ready[1]=core1_if.rsp_ready;

  assign mem_if.req_valid=mem_req_valid[0]; assign mem_if.req_rw=mem_req_rw[0];
  assign mem_if.req_addr=mem_req_addr[0]; assign mem_if.req_data=mem_req_data[0];
  assign mem_if.req_byteen=mem_req_byteen[0]; assign mem_if.req_tag=mem_req_tag[0];
  assign mem_req_ready[0]=mem_if.req_ready;
  assign mem_rsp_valid[0]=mem_if.rsp_valid; assign mem_rsp_data[0]=mem_if.rsp_data;
  assign mem_rsp_tag[0]=mem_if.rsp_tag; assign mem_if.rsp_ready=mem_rsp_ready[0];

  l2_cache_dut_wrapper #(
    .NUM_REQS(NUM_REQS), .MEM_PORTS(MEM_PORTS), .CACHE_SIZE(256*1024),
    .LINE_SIZE(64), .SECTOR_SIZE(64), .NUM_BANKS(4), .NUM_WAYS(4),
    .WORD_SIZE(8), .MSHR_SIZE(8), .MRSQ_SIZE(8), .LATENCY(2),
    .CORE_TAG_W(TAG_W), .MEM_ADDR_W(ADDR_W), .MEM_TAG_W(MEM_TAG_W)
  ) dut (.*);

  l2_core_assertions a_core0(core0_if);
  l2_core_assertions a_core1(core1_if);
  l2_mem_assertions  a_mem(mem_if);

  initial begin
    repeat(8) @(posedge clk);
    reset <= 0;
  end

  initial begin
    uvm_config_db#(virtual l2_core_if)::set(null,"uvm_test_top","core0_vif",core0_if);
    uvm_config_db#(virtual l2_core_if)::set(null,"uvm_test_top","core1_vif",core1_if);
    uvm_config_db#(virtual l2_mem_if)::set(null,"uvm_test_top","mem_vif",mem_if);
    run_test();
  end
endmodule
