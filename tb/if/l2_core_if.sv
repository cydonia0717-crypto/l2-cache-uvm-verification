interface l2_core_if #(
    parameter int ADDR_W = 64,
    parameter int DATA_W = 64,
    parameter int TAG_W  = 16
) (input logic clk);
    localparam int STRB_W = DATA_W/8;

    logic              reset;
    logic              req_valid;
    logic              req_ready;
    logic              req_rw;
    logic [ADDR_W-1:0] req_addr;
    logic [DATA_W-1:0] req_data;
    logic [STRB_W-1:0] req_byteen;
    logic [TAG_W-1:0]  req_tag;

    logic              rsp_valid;
    logic              rsp_ready;
    logic [DATA_W-1:0] rsp_data;
    logic [TAG_W-1:0]  rsp_tag;

    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        input  reset, req_ready, rsp_valid, rsp_data, rsp_tag;
        output req_valid, req_rw, req_addr, req_data, req_byteen, req_tag, rsp_ready;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input reset, req_valid, req_ready, req_rw, req_addr, req_data, req_byteen, req_tag;
        input rsp_valid, rsp_ready, rsp_data, rsp_tag;
    endclocking
endinterface
