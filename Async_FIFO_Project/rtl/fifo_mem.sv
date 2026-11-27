module fifo_mem #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4
) (
    input  logic                  wr_clk,
    input  logic                  wr_en,
    input  logic [ADDR_WIDTH-1:0] wr_addr,
    input  logic [DATA_WIDTH-1:0] wr_data,

    input  logic [ADDR_WIDTH-1:0] rd_addr,
    output logic [DATA_WIDTH-1:0] rd_data
);

    localparam int DEPTH = (1 << ADDR_WIDTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write port: synchronous to wr_clk.
    always_ff @(posedge wr_clk) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    /*
     * Read port: asynchronous read.
     * This is convenient for learning/ASIC-style FIFO verification.
     * If your target SRAM/FPGA BRAM requires synchronous read latency,
     * adapt the read port and scoreboard timing accordingly.
     */
    assign rd_data = mem[rd_addr];

endmodule
