module wptr_full #(
    parameter int ADDR_WIDTH = 4
) (
    input  logic                  wr_clk,
    input  logic                  wr_rst_n,
    input  logic                  wr_en,
    input  logic [ADDR_WIDTH:0]   rd_gray_sync,

    output logic [ADDR_WIDTH-1:0] wr_addr,
    output logic [ADDR_WIDTH:0]   wr_bin,
    output logic [ADDR_WIDTH:0]   wr_gray,
    output logic                  full
);

    logic [ADDR_WIDTH:0] wr_bin_next;
    logic [ADDR_WIDTH:0] wr_gray_next;
    logic                  full_next;

    // A write is accepted only when full == 0.
    always_comb begin
        wr_bin_next = wr_bin + ((wr_en && !full) ? 1'b1 : 1'b0);
    end

    // Binary -> Gray: gray = binary ^ (binary >> 1)
    always_comb begin
        wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
    end

    /*
     * Gray-code full test.
     * For a power-of-two FIFO, full occurs when the next write pointer
     * is exactly one FIFO depth ahead of the synchronized read pointer.
     * In Gray code this is represented by inverting the two MSBs.
     *
     * This implementation assumes ADDR_WIDTH >= 2.
     */
    always_comb begin
        full_next =
            (wr_gray_next ==
             {~rd_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1],
               rd_gray_sync[ADDR_WIDTH-2:0]});
    end

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin  <= '0;
            wr_gray <= '0;
            full    <= 1'b0;
        end else begin
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
            full    <= full_next;
        end
    end

    assign wr_addr = wr_bin[ADDR_WIDTH-1:0];

endmodule
