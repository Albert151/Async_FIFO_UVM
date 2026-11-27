module fifo_assertions #(
    parameter int ADDR_WIDTH = 4
) (
    input  logic                wr_clk,
    input  logic                wr_rst_n,
    input  logic                wr_en,
    input  logic                full,
    input  logic [ADDR_WIDTH:0] wr_bin,
    input  logic [ADDR_WIDTH:0] wr_gray,

    input  logic                rd_clk,
    input  logic                rd_rst_n,
    input  logic                rd_en,
    input  logic                empty,
    input  logic [ADDR_WIDTH:0] rd_bin,
    input  logic [ADDR_WIDTH:0] rd_gray,

    output int unsigned         assertion_errors
);

    initial assertion_errors = 0;

    // Accepted write -> binary write pointer increments exactly once.
    property p_wr_ptr_increment;
        @(posedge wr_clk)
        disable iff (!wr_rst_n)
        (wr_en && !full) |=> (wr_bin == ($past(wr_bin) + 1'b1));
    endproperty

    a_wr_ptr_increment:
        assert property (p_wr_ptr_increment)
        else begin
            assertion_errors++;
            $error("[%0t][SVA] wr_bin did not increment after accepted write", $time);
        end

    // Blocked write -> write pointer must not move.
    property p_wr_ptr_hold_when_full;
        @(posedge wr_clk)
        disable iff (!wr_rst_n)
        (wr_en && full) |=> (wr_bin == $past(wr_bin));
    endproperty

    a_wr_ptr_hold_when_full:
        assert property (p_wr_ptr_hold_when_full)
        else begin
            assertion_errors++;
            $error("[%0t][SVA] wr_bin moved while FIFO was full", $time);
        end

    // Gray pointer changes by zero or one bit per source-clock step.
    property p_wr_gray_onebit;
        @(posedge wr_clk)
        disable iff (!wr_rst_n)
        $onehot0(wr_gray ^ $past(wr_gray));
    endproperty

    a_wr_gray_onebit:
        assert property (p_wr_gray_onebit)
        else begin
            assertion_errors++;
            $error("[%0t][SVA] wr_gray changed by more than one bit", $time);
        end

    // Accepted read -> binary read pointer increments exactly once.
    property p_rd_ptr_increment;
        @(posedge rd_clk)
        disable iff (!rd_rst_n)
        (rd_en && !empty) |=> (rd_bin == ($past(rd_bin) + 1'b1));
    endproperty

    a_rd_ptr_increment:
        assert property (p_rd_ptr_increment)
        else begin
            assertion_errors++;
            $error("[%0t][SVA] rd_bin did not increment after accepted read", $time);
        end

    // Blocked read -> read pointer must not move.
    property p_rd_ptr_hold_when_empty;
        @(posedge rd_clk)
        disable iff (!rd_rst_n)
        (rd_en && empty) |=> (rd_bin == $past(rd_bin));
    endproperty

    a_rd_ptr_hold_when_empty:
        assert property (p_rd_ptr_hold_when_empty)
        else begin
            assertion_errors++;
            $error("[%0t][SVA] rd_bin moved while FIFO was empty", $time);
        end

    property p_rd_gray_onebit;
        @(posedge rd_clk)
        disable iff (!rd_rst_n)
        $onehot0(rd_gray ^ $past(rd_gray));
    endproperty

    a_rd_gray_onebit:
        assert property (p_rd_gray_onebit)
        else begin
            assertion_errors++;
            $error("[%0t][SVA] rd_gray changed by more than one bit", $time);
        end

    // Reset-state checks.
    property p_wr_reset_state;
        @(posedge wr_clk)
        !wr_rst_n |-> (!full && (wr_bin == '0) && (wr_gray == '0));
    endproperty

    a_wr_reset_state:
        assert property (p_wr_reset_state)
        else begin
            assertion_errors++;
            $error("[%0t][SVA] write-domain reset state incorrect", $time);
        end

    property p_rd_reset_state;
        @(posedge rd_clk)
        !rd_rst_n |-> (empty && (rd_bin == '0) && (rd_gray == '0));
    endproperty

    a_rd_reset_state:
        assert property (p_rd_reset_state)
        else begin
            assertion_errors++;
            $error("[%0t][SVA] read-domain reset state incorrect", $time);
        end

endmodule
