module sync_r2w #(
    parameter int ADDR_WIDTH = 4
) (
    input  logic                  wr_clk,
    input  logic                  wr_rst_n,
    input  logic [ADDR_WIDTH:0]   rd_gray,
    output logic [ADDR_WIDTH:0]   rd_gray_sync
);

    logic [ADDR_WIDTH:0] rd_gray_sync_ff1;

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_gray_sync_ff1 <= '0;
            rd_gray_sync     <= '0;
        end else begin
            rd_gray_sync_ff1 <= rd_gray;
            rd_gray_sync     <= rd_gray_sync_ff1;
        end
    end

endmodule
