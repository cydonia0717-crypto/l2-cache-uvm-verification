interface l2_mem_if #(
    parameter int ADDR_W     = 64,
    parameter int LINE_BYTES = 64,
    parameter int TAG_W      = 6
) (input logic clk);
    localparam int DATA_W = LINE_BYTES*8;

    logic                  reset;
    logic                  req_valid;
    logic                  req_ready;
    logic                  req_rw;
    logic [ADDR_W-1:0]     req_addr;
    logic [DATA_W-1:0]     req_data;
    logic [LINE_BYTES-1:0] req_byteen;
    logic [TAG_W-1:0]      req_tag;

    logic                  rsp_valid;
    logic                  rsp_ready;
    logic [DATA_W-1:0]     rsp_data;
    logic [TAG_W-1:0]      rsp_tag;

    clocking rsp_cb @(posedge clk);
        default input #1step output #0;
        input  reset, req_valid, req_rw, req_addr, req_data, req_byteen, req_tag, rsp_ready;
        output req_ready, rsp_valid, rsp_data, rsp_tag;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input reset, req_valid, req_ready, req_rw, req_addr, req_data, req_byteen, req_tag;
        input rsp_valid, rsp_ready, rsp_data, rsp_tag;
    endclocking
endinterface
