module rptr_empty #(
    parameter int ADDR_WIDTH = 4
) (
    input  logic                  rd_clk,
    input  logic                  rd_rst_n,
    input  logic                  rd_en,
    input  logic [ADDR_WIDTH:0]   wr_gray_sync,

    output logic [ADDR_WIDTH-1:0] rd_addr,
    output logic [ADDR_WIDTH:0]   rd_bin,
    output logic [ADDR_WIDTH:0]   rd_gray,
    output logic                  empty
);

    logic [ADDR_WIDTH:0] rd_bin_next;
    logic [ADDR_WIDTH:0] rd_gray_next;
    logic                  empty_next;

    // A read is accepted only when empty == 0.
    always_comb begin
        rd_bin_next = rd_bin + ((rd_en && !empty) ? 1'b1 : 1'b0);
    end

    // Binary -> Gray
    always_comb begin
        rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;
    end

    // FIFO is empty when next read pointer catches synchronized write pointer.
    always_comb begin
        empty_next = (rd_gray_next == wr_gray_sync);
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin  <= '0;
            rd_gray <= '0;
            empty   <= 1'b1;
        end else begin
            rd_bin  <= rd_bin_next;
            rd_gray <= rd_gray_next;
            empty   <= empty_next;
        end
    end

    assign rd_addr = rd_bin[ADDR_WIDTH-1:0];

endmodule
