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
    input  logic [ADDR_WIDTH:0] rd_gray
);
    logic wr_past_valid;
    logic rd_past_valid;

    always_ff@(posedge wr_clk or negedge wr_rst_n)begin
        if(!wr_rst_n)
            wr_past_valid <= 1'b0;
        else
            wr_past_valid <= 1'b1;
    end

    always_ff@(posedge rd_clk or negedge rd_rst_n)begin
        if(!rd_rst_n)
            rd_past_valid <= 1'b0;
        else
            rd_past_valid <= 1'b1;
    end

    property p_wr_ptr_increment;
        @(posedge wr_clk)
        disable iff (!wr_rst_n || !wr_past_valid)
        (wr_en && !full) |=> (wr_bin == ($past(wr_bin) + 1'b1));
    endproperty

    a_wr_ptr_increment:
        assert property (p_wr_ptr_increment)
        else begin
            $error("[%0t][SVA] wr_bin did not increment after accepted write", $time);
        end

    // Blocked write -> write pointer must not move.
    property p_wr_ptr_hold_when_full;
        @(posedge wr_clk)
        disable iff (!wr_rst_n || !wr_past_valid)
        (wr_en && full) |=> (wr_bin == $past(wr_bin));
    endproperty

    a_wr_ptr_hold_when_full:
        assert property (p_wr_ptr_hold_when_full)
        else begin
            $error("[%0t][SVA] wr_bin moved while FIFO was full", $time);
        end

    // Gray pointer changes by zero or one bit per source-clock step.
    property p_wr_gray_onebit;
        @(posedge wr_clk)
        disable iff (!wr_rst_n || !wr_past_valid)
        (wr_en && !full) |=> $onehot(wr_gray ^ $past(wr_gray));
    endproperty

    a_wr_gray_onebit:
        assert property (p_wr_gray_onebit)
        else begin
            $error("[%0t][SVA] wr_gray changed by more than one bit", $time);
        end

    property p_wr_gray_encoding;
        @(posedge wr_clk)
        disable iff (!wr_rst_n)
        wr_gray == (wr_bin ^ (wr_bin>>1));
    endproperty

    a_wr_gray_encoding:
        assert property(p_wr_gray_encoding)else begin   
            $error("SVA_FAIL:wr_gray does not match wr_bin gray encoding");
        end

    property p_full_reset;
        @(posedge wr_clk)
        (!wr_rst_n |->!full);
    endproperty

    a_full_reset:
        assert property (p_full_reset)else begin
        $error("SVA_FAIL:full is not 0 during write reset");
        end

    property p_wr_no_unknown;
        @(posedge wr_clk)
        disable iff(!wr_rst_n)
        !$isunknown({wr_bin,wr_gray,full});
    endproperty

    a_wr_no_unknown:
        assert property(p_wr_no_unknown)else begin
        $error("SVA_FAIL: X/Z detected in write-domain FIFO state");
    end

    // Accepted read -> binary read pointer increments exactly once.
    property p_rd_ptr_increment;
        @(posedge rd_clk)
        disable iff (!rd_rst_n || !rd_past_valid)
        (rd_en && !empty) |=> (rd_bin == ($past(rd_bin) + 1'b1));
    endproperty

    a_rd_ptr_increment:
        assert property (p_rd_ptr_increment)
        else begin
            $error("[%0t][SVA] rd_bin did not increment after accepted read", $time);
        end

    // Blocked read -> read pointer must not move.
    property p_rd_ptr_hold_when_empty;
        @(posedge rd_clk)
        disable iff (!rd_rst_n || !rd_past_valid)
        (rd_en && empty) |=> (rd_bin == $past(rd_bin));
    endproperty

    a_rd_ptr_hold_when_empty:
        assert property (p_rd_ptr_hold_when_empty)
        else begin
            $error("[%0t][SVA] rd_bin moved while FIFO was empty", $time);
        end

    property p_rd_gray_onebit;
        @(posedge rd_clk)
        disable iff (!rd_rst_n || !rd_past_valid)
        (rd_en && !empty) |=> $onehot(rd_gray ^ $past(rd_gray));
    endproperty

    a_rd_gray_onebit:
        assert property (p_rd_gray_onebit)
        else begin
            $error("[%0t][SVA] rd_gray changed by more than one bit", $time);
        end

    property p_rd_gray_encoding;
        @(posedge rd_clk)
        disable iff (!rd_rst_n)
        rd_gray == (rd_bin ^ (rd_bin>>1));
    endproperty

    a_rd_gray_encoding:
        assert property(p_rd_gray_encoding)else begin   
            $error("SVA_FAIL:rd_gray does not match rd_bin gray encoding");
        end

    property p_empty_reset;
        @(posedge rd_clk)
        (!rd_rst_n |-> empty);
    endproperty

    a_empty_reset:
        assert property (p_empty_reset)else begin
        $error("SVA_FAIL:empty is not 0 during read reset");
        end

    property p_rd_no_unknown;
        @(posedge rd_clk)
        disable iff(!rd_rst_n)
        !$isunknown({rd_bin,rd_gray,empty});
    endproperty

    a_rd_no_unknown:
        assert property(p_rd_no_unknown)else begin
        $error("SVA_FAIL: X/Z detected in read-domain FIFO state");
    end

    c_valid_write:
        cover property (
            @(posedge wr_clk)
            disable iff(!wr_rst_n)
            wr_en && !full
        );

    c_block_write:
        cover property (
            @(posedge wr_clk)
            disable iff(!wr_rst_n)
            wr_en && full
        );

    c_valid_read:
        cover property (
            @(posedge rd_clk)
            disable iff(!rd_rst_n)
            rd_en && !empty
        );

    c_block_read:
        cover property (
            @(posedge rd_clk)
            disable iff(!rd_rst_n)
            rd_en && empty
        );
endmodule
