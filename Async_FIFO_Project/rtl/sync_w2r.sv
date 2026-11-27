module sync_w2r #(
    parameter int ADDR_WIDTH = 4
) (
    input  logic                  rd_clk,
    input  logic                  rd_rst_n,
    input  logic [ADDR_WIDTH:0]   wr_gray,
    output logic [ADDR_WIDTH:0]   wr_gray_sync
);

    logic [ADDR_WIDTH:0] wr_gray_sync_ff1;

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_gray_sync_ff1 <= '0;
            wr_gray_sync     <= '0;
        end else begin
            wr_gray_sync_ff1 <= wr_gray;
            wr_gray_sync     <= wr_gray_sync_ff1;
        end
    end

endmodule
