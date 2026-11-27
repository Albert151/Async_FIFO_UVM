module async_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4
) (
    // Write clock domain
    input  logic                  wr_clk,
    input  logic                  wr_rst_n,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,

    // Read clock domain
    input  logic                  rd_clk,
    input  logic                  rd_rst_n,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty
);

    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [ADDR_WIDTH-1:0] rd_addr;

    // Kept as named internal signals so the verification environment
    // can observe them for assertions/coverage/debug.
    logic [ADDR_WIDTH:0] wr_bin;
    logic [ADDR_WIDTH:0] wr_gray;
    logic [ADDR_WIDTH:0] rd_bin;
    logic [ADDR_WIDTH:0] rd_gray;

    logic [ADDR_WIDTH:0] wr_gray_sync;
    logic [ADDR_WIDTH:0] rd_gray_sync;

    // Write pointer synchronized into read clock domain.
    sync_w2r #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_sync_w2r (
        .rd_clk      (rd_clk),
        .rd_rst_n    (rd_rst_n),
        .wr_gray     (wr_gray),
        .wr_gray_sync(wr_gray_sync)
    );

    // Read pointer synchronized into write clock domain.
    sync_r2w #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_sync_r2w (
        .wr_clk      (wr_clk),
        .wr_rst_n    (wr_rst_n),
        .rd_gray     (rd_gray),
        .rd_gray_sync(rd_gray_sync)
    );

    wptr_full #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_wptr_full (
        .wr_clk      (wr_clk),
        .wr_rst_n    (wr_rst_n),
        .wr_en       (wr_en),
        .rd_gray_sync(rd_gray_sync),
        .wr_addr     (wr_addr),
        .wr_bin      (wr_bin),
        .wr_gray     (wr_gray),
        .full        (full)
    );

    rptr_empty #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_rptr_empty (
        .rd_clk      (rd_clk),
        .rd_rst_n    (rd_rst_n),
        .rd_en       (rd_en),
        .wr_gray_sync(wr_gray_sync),
        .rd_addr     (rd_addr),
        .rd_bin      (rd_bin),
        .rd_gray     (rd_gray),
        .empty       (empty)
    );

    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_fifo_mem (
        .wr_clk (wr_clk),
        .wr_en  (wr_en && !full),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

endmodule
