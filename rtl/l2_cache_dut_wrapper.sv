`include "VX_cache_define.vh"

module l2_cache_dut_wrapper import VX_gpu_pkg::*; #(
    parameter int NUM_REQS      = 2,
    parameter int MEM_PORTS     = 1,
    parameter int CACHE_SIZE    = 256 * 1024,
    parameter int LINE_SIZE     = 64,
    parameter int SECTOR_SIZE   = 64,
    parameter int NUM_BANKS     = 4,
    parameter int NUM_WAYS      = 4,
    parameter int WORD_SIZE     = 8,
    parameter int MSHR_SIZE     = 8,
    parameter int MRSQ_SIZE     = 8,
    parameter int LATENCY       = 2,
    parameter int CORE_TAG_W    = 16,
    parameter int MEM_ADDR_W    = 64,
    parameter int MEM_TAG_W     = `CACHE_MEM_TAG_WIDTH(MSHR_SIZE, NUM_BANKS, MEM_PORTS, UUID_WIDTH)
) (
    input  wire                         clk,
    input  wire                         reset,

    input  wire                         core_req_valid  [NUM_REQS],
    output wire                         core_req_ready  [NUM_REQS],
    input  wire                         core_req_rw     [NUM_REQS],
    input  wire [MEM_ADDR_W-1:0]        core_req_addr   [NUM_REQS], // byte address
    input  wire [WORD_SIZE*8-1:0]       core_req_data   [NUM_REQS],
    input  wire [WORD_SIZE-1:0]         core_req_byteen [NUM_REQS],
    input  wire [CORE_TAG_W-1:0]        core_req_tag    [NUM_REQS],

    output wire                         core_rsp_valid  [NUM_REQS],
    input  wire                         core_rsp_ready  [NUM_REQS],
    output wire [WORD_SIZE*8-1:0]       core_rsp_data   [NUM_REQS],
    output wire [CORE_TAG_W-1:0]        core_rsp_tag    [NUM_REQS],

    output wire                         mem_req_valid   [MEM_PORTS],
    input  wire                         mem_req_ready   [MEM_PORTS],
    output wire                         mem_req_rw      [MEM_PORTS],
    output wire [MEM_ADDR_W-1:0]        mem_req_addr    [MEM_PORTS], // byte address
    output wire [SECTOR_SIZE*8-1:0]     mem_req_data    [MEM_PORTS],
    output wire [SECTOR_SIZE-1:0]       mem_req_byteen  [MEM_PORTS],
    output wire [MEM_TAG_W-1:0]         mem_req_tag     [MEM_PORTS],

    input  wire                         mem_rsp_valid   [MEM_PORTS],
    output wire                         mem_rsp_ready   [MEM_PORTS],
    input  wire [SECTOR_SIZE*8-1:0]     mem_rsp_data    [MEM_PORTS],
    input  wire [MEM_TAG_W-1:0]         mem_rsp_tag     [MEM_PORTS]
);

    localparam int WORD_LSB   = $clog2(WORD_SIZE);
    localparam int SECTOR_LSB = $clog2(SECTOR_SIZE);

    VX_mem_bus_if #(
        .DATA_SIZE (WORD_SIZE),
        .TAG_WIDTH (CORE_TAG_W)
    ) core_bus_if[NUM_REQS]();

    VX_mem_bus_if #(
        .DATA_SIZE (SECTOR_SIZE),
        .TAG_WIDTH (MEM_TAG_W)
    ) mem_bus_if[MEM_PORTS]();

    for (genvar i = 0; i < NUM_REQS; ++i) begin : g_core
        assign core_bus_if[i].req_valid      = core_req_valid[i];
        assign core_bus_if[i].req_data.rw    = core_req_rw[i];
        assign core_bus_if[i].req_data.addr  = core_req_addr[i] >> WORD_LSB;
        assign core_bus_if[i].req_data.data  = core_req_data[i];
        assign core_bus_if[i].req_data.byteen= core_req_byteen[i];
        assign core_bus_if[i].req_data.attr  = '0;
        assign core_bus_if[i].req_data.tag   = core_req_tag[i];
        assign core_req_ready[i]             = core_bus_if[i].req_ready;

        assign core_rsp_valid[i]             = core_bus_if[i].rsp_valid;
        assign core_rsp_data[i]              = core_bus_if[i].rsp_data.data;
        assign core_rsp_tag[i]               = core_bus_if[i].rsp_data.tag;
        assign core_bus_if[i].rsp_ready      = core_rsp_ready[i];
    end

    for (genvar i = 0; i < MEM_PORTS; ++i) begin : g_mem
        assign mem_req_valid[i]              = mem_bus_if[i].req_valid;
        assign mem_req_rw[i]                 = mem_bus_if[i].req_data.rw;
        assign mem_req_addr[i]               = MEM_ADDR_W'(mem_bus_if[i].req_data.addr) << SECTOR_LSB;
        assign mem_req_data[i]               = mem_bus_if[i].req_data.data;
        assign mem_req_byteen[i]             = mem_bus_if[i].req_data.byteen;
        assign mem_req_tag[i]                = mem_bus_if[i].req_data.tag;
        assign mem_bus_if[i].req_ready       = mem_req_ready[i];

        assign mem_bus_if[i].rsp_valid       = mem_rsp_valid[i];
        assign mem_bus_if[i].rsp_data.data   = mem_rsp_data[i];
        assign mem_bus_if[i].rsp_data.tag    = mem_rsp_tag[i];
        assign mem_rsp_ready[i]              = mem_bus_if[i].rsp_ready;
    end

    VX_cache_wrap #(
        .INSTANCE_ID   ("student-l2"),
        .NUM_REQS      (NUM_REQS),
        .MEM_PORTS     (MEM_PORTS),
        .CACHE_SIZE    (CACHE_SIZE),
        .LINE_SIZE     (LINE_SIZE),
        .SECTOR_SIZE   (SECTOR_SIZE),
        .NUM_BANKS     (NUM_BANKS),
        .NUM_WAYS      (NUM_WAYS),
        .WORD_SIZE     (WORD_SIZE),
        .MSHR_SIZE     (MSHR_SIZE),
        .MRSQ_SIZE     (MRSQ_SIZE),
        .LATENCY       (LATENCY),
        .WRITE_ENABLE  (1),
        .WRITEBACK     (1),
        .DIRTY_BYTES   (0),
        .REPL_POLICY   (`CS_REPL_PLRU),
        .TAG_WIDTH     (CORE_TAG_W),
        .NC_ENABLE     (0),
        .PASSTHRU      (0),
        .CORE_OUT_BUF  (3),
        .MEM_OUT_BUF   (3),
        .IS_LLC        (0),
        .AMO_ENABLE    (0)
    ) dut (
        .clk         (clk),
        .reset       (reset),
        .core_bus_if (core_bus_if),
        .mem_bus_if  (mem_bus_if)
    );

endmodule
