class fifo_write_monitor;

    virtual async_fifo_if #(DATA_WIDTH) vif;
    fifo_scoreboard                      scb;

    function new(
        virtual async_fifo_if #(DATA_WIDTH) vif,
        fifo_scoreboard                      scb
    );
        this.vif = vif;
        this.scb = scb;
    endfunction

    task run();
        forever begin
            @(posedge vif.wr_clk);

            // Sample only accepted DUT writes.
            if (vif.wr_rst_n && vif.wr_en && !vif.full) begin
                scb.observe_write(vif.wr_data);
            end
        end
    endtask

endclass


class fifo_read_monitor;

    virtual async_fifo_if #(DATA_WIDTH) vif;
    fifo_scoreboard                      scb;

    function new(
        virtual async_fifo_if #(DATA_WIDTH) vif,
        fifo_scoreboard                      scb
    );
        this.vif = vif;
        this.scb = scb;
    endfunction

    task run();
        forever begin
            @(posedge vif.rd_clk);

            // With asynchronous RAM read, rd_data corresponds to current rd_addr
            // in the active region before rd_ptr advances in NBA.
            if (vif.rd_rst_n && vif.rd_en && !vif.empty) begin
                scb.observe_read(vif.rd_data);
            end
        end
    endtask

endclass
