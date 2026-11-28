bind async_fifo fifo_assertions #(
    .ADDR_WIDTH(ADDR_WIDTH)
)
u_fifo_assertions
(
    .wr_clk(wr_clk),
    .wr_rst_n(wr_rst_n),
    .wr_en(wr_en),
    .full(full),

    .wr_bin(wr_bin),
    .wr_gray(wr_gray),

    .rd_clk(rd_clk),
    .rd_rst_n(rd_rst_n),
    .rd_en(rd_en),
    .empty(empty),

    .rd_bin(rd_bin),
    .rd_gray(rd_gray)
);