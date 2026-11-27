`timescale 1ns/1ps

module tb_async_fifo;

    import fifo_tb_pkg::*;

    localparam int TB_DATA_WIDTH = DATA_WIDTH;
    localparam int ADDR_WIDTH    = 4;
    localparam int DEPTH         = (1 << ADDR_WIDTH);

    localparam time WR_CLK_PERIOD = 10ns;
    localparam time RD_CLK_PERIOD = 14ns;

    async_fifo_if #(TB_DATA_WIDTH) vif();

    int unsigned tb_errors;
    int unsigned assertion_errors;

    mailbox #(fifo_transaction) wr_mbx;
    mailbox #(fifo_transaction) rd_mbx;

    fifo_scoreboard    scb;
    fifo_write_driver  wr_drv;
    fifo_read_driver   rd_drv;
    fifo_write_monitor wr_mon;
    fifo_read_monitor  rd_mon;

    async_fifo #(
        .DATA_WIDTH(TB_DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wr_clk  (vif.wr_clk),
        .wr_rst_n(vif.wr_rst_n),
        .wr_en   (vif.wr_en),
        .wr_data (vif.wr_data),
        .full    (vif.full),

        .rd_clk  (vif.rd_clk),
        .rd_rst_n(vif.rd_rst_n),
        .rd_en   (vif.rd_en),
        .rd_data (vif.rd_data),
        .empty   (vif.empty)
    );

    fifo_assertions #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_assertions (
        .wr_clk          (vif.wr_clk),
        .wr_rst_n        (vif.wr_rst_n),
        .wr_en           (vif.wr_en),
        .full            (vif.full),
        .wr_bin          (dut.wr_bin),
        .wr_gray         (dut.wr_gray),

        .rd_clk          (vif.rd_clk),
        .rd_rst_n        (vif.rd_rst_n),
        .rd_en           (vif.rd_en),
        .empty           (vif.empty),
        .rd_bin          (dut.rd_bin),
        .rd_gray         (dut.rd_gray),

        .assertion_errors(assertion_errors)
    );

    fifo_coverage #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_coverage (
        .wr_clk  (vif.wr_clk),
        .wr_rst_n(vif.wr_rst_n),
        .wr_en   (vif.wr_en),
        .full    (vif.full),
        .wr_bin  (dut.wr_bin),

        .rd_clk  (vif.rd_clk),
        .rd_rst_n(vif.rd_rst_n),
        .rd_en   (vif.rd_en),
        .empty   (vif.empty),
        .rd_bin  (dut.rd_bin)
    );

    // ------------------------------------------------------------
    // Clock generation
    // ------------------------------------------------------------

    initial begin
        vif.wr_clk = 1'b0;
        forever #(WR_CLK_PERIOD/2) vif.wr_clk = ~vif.wr_clk;
    end

    initial begin
        vif.rd_clk = 1'b0;
        forever #(RD_CLK_PERIOD/2) vif.rd_clk = ~vif.rd_clk;
    end

    // ------------------------------------------------------------
    // Wave dump
    // ------------------------------------------------------------

`ifdef VCS
    initial begin
        $vcdplusfile("async_fifo.vpd");
        $vcdpluson(0, tb_async_fifo);
    end
`else
    initial begin
        $dumpfile("async_fifo.vcd");
        $dumpvars(0, tb_async_fifo);
    end
`endif

    // ------------------------------------------------------------
    // Helper tasks
    // ------------------------------------------------------------

    task automatic reset_dut(bit clear_statistics = 1'b0);
        $display("\n[%0t][TEST] Reset DUT", $time);

        vif.wr_en    <= 1'b0;
        vif.wr_data  <= '0;
        vif.rd_en    <= 1'b0;
        vif.wr_rst_n <= 1'b0;
        vif.rd_rst_n <= 1'b0;

        scb.reset_model(clear_statistics);

        // Deassert each reset away from its active clock edge.
        fork
            begin
                repeat (4) @(negedge vif.wr_clk);
                vif.wr_rst_n <= 1'b1;
            end
            begin
                repeat (4) @(negedge vif.rd_clk);
                vif.rd_rst_n <= 1'b1;
            end
        join

        repeat (3) @(posedge vif.rd_clk);

        if (vif.empty !== 1'b1) begin
            tb_errors++;
            $error("[%0t][TEST] FIFO should be empty after reset", $time);
        end

        if (vif.full !== 1'b0) begin
            tb_errors++;
            $error("[%0t][TEST] FIFO should not be full after reset", $time);
        end
    endtask


    task automatic send_write(bit [TB_DATA_WIDTH-1:0] data);
        fifo_transaction tr;
        tr = new(FIFO_WRITE, data);
        wr_mbx.put(tr);
    endtask


    task automatic send_read();
        fifo_transaction tr;
        tr = new(FIFO_READ, '0);
        rd_mbx.put(tr);
    endtask


    task automatic basic_test();
        int unsigned start_writes;
        int unsigned start_reads;
        int i;

        $display("\n======================================================");
        $display("[TEST] BASIC WRITE/READ");
        $display("======================================================");

        start_writes = scb.write_count;
        start_reads  = scb.read_count;

        for (i = 0; i < 8; i++) begin
            send_write(8'h10 + i);
        end

        wait (scb.write_count >= (start_writes + 8));

        // Let synchronized write pointer reach read domain.
        repeat (4) @(posedge vif.rd_clk);

        for (i = 0; i < 8; i++) begin
            send_read();
        end

        wait (scb.read_count >= (start_reads + 8));
        repeat (3) @(posedge vif.rd_clk);

        if (scb.pending_count() != 0) begin
            tb_errors++;
            $error("[%0t][TEST] BASIC test ended with %0d pending entries",
                   $time, scb.pending_count());
        end
    endtask


    task automatic full_boundary_test();
        int unsigned start_writes;
        int unsigned accepted;
        int i;

        $display("\n======================================================");
        $display("[TEST] FULL BOUNDARY / OVERFLOW PROTECTION");
        $display("======================================================");

        start_writes = scb.write_count;

        // Continuous write request deliberately continues beyond full.
        for (i = 0; i < DEPTH + 4; i++) begin
            @(negedge vif.wr_clk);
            vif.wr_en   <= 1'b1;
            vif.wr_data <= i;
        end

        @(negedge vif.wr_clk);
        vif.wr_en <= 1'b0;

        repeat (2) @(posedge vif.wr_clk);

        accepted = scb.write_count - start_writes;

        if (accepted != DEPTH) begin
            tb_errors++;
            $error("[%0t][TEST] Expected exactly %0d accepted writes, got %0d",
                   $time, DEPTH, accepted);
        end

        if (vif.full !== 1'b1) begin
            tb_errors++;
            $error("[%0t][TEST] full did not assert after filling FIFO", $time);
        end

        // Drain the FIFO with a continuous read request.
        wait (vif.empty === 1'b0);

        @(negedge vif.rd_clk);
        vif.rd_en <= 1'b1;

        wait (vif.empty === 1'b1);

        @(negedge vif.rd_clk);
        vif.rd_en <= 1'b0;

        repeat (3) @(posedge vif.rd_clk);

        if (scb.pending_count() != 0) begin
            tb_errors++;
            $error("[%0t][TEST] FULL test drain left %0d pending entries",
                   $time, scb.pending_count());
        end
    endtask


    task automatic random_stress_test(
        int unsigned wr_cycles = 3000,
        int unsigned rd_cycles = 2400
    );
        int i;
        int stable_empty_cycles;

        $display("\n======================================================");
        $display("[TEST] RANDOM ASYNC STRESS");
        $display("       wr_clk=%0t rd_clk=%0t", WR_CLK_PERIOD, RD_CLK_PERIOD);
        $display("======================================================");

        scb.set_verbose(1'b0);

        fork
            begin : random_writer
                for (i = 0; i < wr_cycles; i++) begin
                    @(negedge vif.wr_clk);

                    if (vif.wr_rst_n) begin
                        vif.wr_en   <= $urandom_range(0, 1);
                        vif.wr_data <= $urandom;
                    end
                end

                @(negedge vif.wr_clk);
                vif.wr_en <= 1'b0;
            end

            begin : random_reader
                int j;

                for (j = 0; j < rd_cycles; j++) begin
                    @(negedge vif.rd_clk);

                    if (vif.rd_rst_n) begin
                        vif.rd_en <= $urandom_range(0, 1);
                    end
                end

                @(negedge vif.rd_clk);
                vif.rd_en <= 1'b0;
            end
        join

        // Allow the final write pointer to propagate through the read-domain CDC.
        repeat (5) @(posedge vif.rd_clk);

        // Drain all remaining data. Keep requesting reads until empty is stable.
        @(negedge vif.rd_clk);
        vif.rd_en <= 1'b1;

        stable_empty_cycles = 0;
        while (stable_empty_cycles < 3) begin
            @(posedge vif.rd_clk);

            if (vif.empty)
                stable_empty_cycles++;
            else
                stable_empty_cycles = 0;
        end

        @(negedge vif.rd_clk);
        vif.rd_en <= 1'b0;

        repeat (2) @(posedge vif.rd_clk);

        scb.set_verbose(1'b1);

        if (scb.pending_count() != 0) begin
            tb_errors++;
            $error("[%0t][TEST] RANDOM test ended with %0d pending entries",
                   $time, scb.pending_count());
        end
    endtask


    task automatic reset_recovery_test();
        int unsigned start_writes;
        int unsigned start_reads;
        int i;

        $display("\n======================================================");
        $display("[TEST] MID-RUN RESET + RECOVERY");
        $display("======================================================");

        start_writes = scb.write_count;

        for (i = 0; i < 6; i++)
            send_write(8'hA0 + i);

        wait (scb.write_count >= (start_writes + 6));

        // Reset intentionally discards queued FIFO content.
        reset_dut(1'b0);

        if (scb.pending_count() != 0) begin
            tb_errors++;
            $error("[%0t][TEST] Reference queue not empty after reset", $time);
        end

        // Verify that FIFO still works after reset.
        start_writes = scb.write_count;
        start_reads  = scb.read_count;

        for (i = 0; i < 4; i++)
            send_write(8'hC0 + i);

        wait (scb.write_count >= (start_writes + 4));
        repeat (4) @(posedge vif.rd_clk);

        for (i = 0; i < 4; i++)
            send_read();

        wait (scb.read_count >= (start_reads + 4));
        repeat (3) @(posedge vif.rd_clk);

        if (scb.pending_count() != 0) begin
            tb_errors++;
            $error("[%0t][TEST] RESET recovery left %0d pending entries",
                   $time, scb.pending_count());
        end
    endtask

    // ------------------------------------------------------------
    // Test program
    // ------------------------------------------------------------

    initial begin
        tb_errors = 0;

        vif.wr_rst_n = 1'b0;
        vif.rd_rst_n = 1'b0;
        vif.wr_en    = 1'b0;
        vif.rd_en    = 1'b0;
        vif.wr_data  = '0;

        wr_mbx = new();
        rd_mbx = new();

        scb    = new();
        wr_drv = new(vif, wr_mbx);
        rd_drv = new(vif, rd_mbx);
        wr_mon = new(vif, scb);
        rd_mon = new(vif, scb);

        fork
            wr_drv.run();
            rd_drv.run();
            wr_mon.run();
            rd_mon.run();
        join_none

        reset_dut(1'b1);

        basic_test();
        full_boundary_test();
        random_stress_test();
        reset_recovery_test();

        repeat (5) @(posedge vif.rd_clk);

        scb.report();

        $display("Assertion errors : %0d", assertion_errors);
        $display("TB control errors: %0d", tb_errors);
        $display("");

        if ((scb.get_error_count() == 0) &&
            (assertion_errors == 0) &&
            (tb_errors == 0) &&
            (scb.pending_count() == 0)) begin

            $display("######################################################");
            $display("#              ASYNC FIFO TEST PASS                  #");
            $display("######################################################");
            $finish;
        end else begin
            $fatal(1,
                "ASYNC FIFO TEST FAIL: scb=%0d sva=%0d tb=%0d pending=%0d",
                scb.get_error_count(),
                assertion_errors,
                tb_errors,
                scb.pending_count());
        end
    end

endmodule
