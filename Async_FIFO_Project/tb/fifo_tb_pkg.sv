package fifo_tb_pkg;

    parameter int DATA_WIDTH = 8;

    `include "fifo_transaction.sv"
    `include "fifo_scoreboard.sv"
    `include "fifo_driver.sv"
    `include "fifo_monitor.sv"

endpackage
