interface async_fifo_if #(
    parameter int DATA_WIDTH = 8)(
        input logic wr_clk,
        input logic rd_clk
        );
    logic                  wr_rst_n;
    logic                  wr_en;
    logic [DATA_WIDTH-1:0] wr_data;
    logic                  full;

    logic                  rd_rst_n;
    logic                  rd_en;
    logic [DATA_WIDTH-1:0] rd_data;
    logic                  empty;

endinterface
