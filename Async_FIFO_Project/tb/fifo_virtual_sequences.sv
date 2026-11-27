class fifo_base_vesq extends uvm_sequence #(uvm_sequence_item);
    `uvm_object_utils(fifo_base_vesq)
    `uvm_declare_p_sequencer(fifo_virtual_sequencer)

    function new(string name = "fifo_base_vesq");
        super.new();
    endfunction

    virtual task pre_body();
        super.pre_body();

        if(p_sequencer == null)begin
            `uvm_fatal("VSEQ","p_sequencer is null")
        end

        if(p_sequencer.wr_sqr == null)begin
            `uvm_fatal("VSEQ","wr_sqr is null")
        end

        if(p_sequencer.rd_sqr == null)begin
            `uvm_fatal("VSEQ","rd_sqr is null")
        end

        wait(p_sequencer.vif.wr_rst_n === 1'b1 && p_sequencer.vif.rd_rst_n === 1'b1);

        fork
            @(posedge p_sequencer.vif.wr_clk);
            @(posedge p_sequencer.vif.rd_clk);
        join

        `uvm_info("VSEQ",$sformatf("both reset domains ready, wr_rstn = %0b rd_rstn=%0b",p_sequencer.vif.wr_rst_n,p_sequencer.vif.rd_rst_n),UVM_LOW)

    endtask

    task automatic wait_for_full(int unsigned max_cycles=100);
        bit full_seen;
        full_seen = 1'b0;

        fork
            begin
                wait(p_sequencer.vif.full === 1'b1);
                full_seen = 1'b1;
            end
            begin
                repeat (max_cycles)
                    @(posedge p_sequencer.vif.wr_clk);
            end 
        join_any

        disable fork;

        if(!full_seen)begin
            `uvm_fatal("VSEQ_FULL_TIMEOUT",$sformatf("FULL did not assert within %0d wr_clk max_cycles",max_cycles))
        end
    endtask

        task automatic wait_for_empty(int unsigned max_cycles=100);
        bit empty_seen;
        empty_seen = 1'b0;

        fork
            begin
                wait(p_sequencer.vif.empty === 1'b1);
                empty_seen = 1'b1;
            end
            begin
                repeat (max_cycles)
                    @(posedge p_sequencer.vif.rd_clk);
            end 
        join_any

        disable fork;

        if(!empty_seen)begin
           `uvm_fatal("VSEQ_EMPTY_TIMEOUT",$sformatf("EMPTY did not assert within %0d rd_clk max_cycles",max_cycles))
        end
    endtask

    task automatic apply_midrun_reset();
        `uvm_info("VSEQ_RESET","Assertion mid_run reset",UVM_LOW)

        @(negedge p_sequencer.vif.wr_clk);

        p_sequencer.vif.wr_rst_n = 1'b0;
        p_sequencer.vif.rd_rst_n = 1'b0;

        fork    
            begin
                repeat(4)
                    @(posedge p_sequencer.vif.wr_clk);
                p_sequencer.vif.wr_rst_n <= 1'b1;
            end

            begin
                repeat(4)
                    @(posedge p_sequencer.vif.rd_clk);
                p_sequencer.vif.rd_rst_n <= 1'b1;
            end
        join
        `uvm_info("VSEQ","MID-RUN reset released",UVM_LOW)

    endtask
endclass

class fifo_basic_vseq extends fifo_base_vesq;
    `uvm_object_utils(fifo_basic_vseq)

    function new(string name = "fifo_basic_vseq");
        super.new(name);
    endfunction

    virtual task body();
        fifo_write_seq  wr_seq;
        fifo_read_seq   rd_seq;

        `uvm_info("BASIC_VESQ","starting basic virtual sequence",UVM_LOW)

        wr_seq = fifo_write_seq::type_id::create("wr_seq");

        wr_seq.num_items = 8;
        wr_seq.start_data = 8'h10;
        wr_seq.random_data = 1'b0;
        wr_seq.wait_for_ready = 1'b1;

        rd_seq = fifo_read_seq::type_id::create("rd_seq");

        rd_seq.num_items = 8;
        rd_seq.wait_for_ready = 1'b1;       

        wr_seq.start(p_sequencer.wr_sqr);
        rd_seq.start(p_sequencer.rd_sqr);

        `uvm_info("BASIC_VESQ","basic virtual sequence completed",UVM_LOW)
    endtask
endclass


class fifo_full_vseq extends fifo_base_vesq;
    `uvm_object_utils(fifo_full_vseq)

    function new(string name = "fifo_full_vseq");
        super.new(name);
    endfunction

    virtual task body();
        fifo_write_seq  fill_seq;
        fifo_write_seq  overflow_seq;
        fifo_read_seq   drain_seq;

        `uvm_info("FULL_VESQ","starting full virtual sequence",UVM_LOW)

        fill_seq = fifo_write_seq::type_id::create("fill_seq");

        fill_seq.num_items = FIFO_DEPTH;
        fill_seq.start_data = 8'h00;
        fill_seq.random_data = 1'b0;
        fill_seq.wait_for_ready = 1'b1;

        fill_seq.start(p_sequencer.wr_sqr);
        wait_for_full(100);

        overflow_seq = fifo_write_seq::type_id::create("overflow_seq");
        overflow_seq.num_items = 3;
        overflow_seq.start_data = 8'hE0;
        overflow_seq.random_data = 1'b0;
        overflow_seq.wait_for_ready = 1'b0;
        
        overflow_seq.start(p_sequencer.wr_sqr);

        drain_seq = fifo_read_seq::type_id::create("drain_seq");

        drain_seq.num_items = FIFO_DEPTH;
        drain_seq.wait_for_ready = 1'b1;       

        drain_seq.start(p_sequencer.rd_sqr);

        `uvm_info("FULL_VESQ","full virtual sequence completed",UVM_LOW)
    endtask
endclass    

class fifo_empty_vseq extends fifo_base_vesq;
    `uvm_object_utils(fifo_empty_vseq)

    function new(string name = "fifo_empty_vseq");
        super.new(name);
    endfunction

    virtual task body();
        fifo_read_seq   underflow_seq;
        fifo_write_seq  wr_seq;
        fifo_read_seq   rd_seq;

        `uvm_info("EMPTY_VESQ","starting empty virtual sequence",UVM_LOW)

        underflow_seq = fifo_read_seq::type_id::create("underflow_seq");

        underflow_seq.num_items = 3;
        underflow_seq.wait_for_ready = 1'b0;

        underflow_seq.start(p_sequencer.rd_sqr);

        wr_seq = fifo_write_seq::type_id::create("wr_seq");
        wr_seq.num_items = 3;
        wr_seq.start_data = 8'hAA;
        wr_seq.random_data = 1'b0;
        wr_seq.wait_for_ready = 1'b1;
        
        wr_seq.start(p_sequencer.wr_sqr);

        rd_seq = fifo_read_seq::type_id::create("rd_seq");

        rd_seq.num_items = 3;
        rd_seq.wait_for_ready = 1'b1;       

        rd_seq.start(p_sequencer.rd_sqr);
        wait_for_empty(100);

        `uvm_info("EMPTY_VESQ","empty virtual sequence completed",UVM_LOW)
    endtask
endclass    

class fifo_random_vseq extends fifo_base_vesq;
    `uvm_object_utils(fifo_random_vseq)

    function new(string name = "fifo_random_vseq");
        super.new(name);
    endfunction

    virtual task body();
        fifo_read_seq   rd_seq;
        fifo_write_seq  wr_seq;

        `uvm_info("RANDOM_VESQ","starting random virtual sequence",UVM_LOW)

        wr_seq = fifo_write_seq::type_id::create("wr_seq");

        wr_seq.num_items = 1000;
        wr_seq.random_data = 1'b1;
        wr_seq.wait_for_ready = 1'b1;

        rd_seq = fifo_read_seq::type_id::create("rd_seq");

        rd_seq.num_items = 1000;
        rd_seq.wait_for_ready = 1'b1;

        fork
            wr_seq.start(p_sequencer.wr_sqr);
            rd_seq.start(p_sequencer.rd_sqr);
        join
    
        `uvm_info("RANDOM_VESQ","random virtual sequence completed",UVM_LOW)
    endtask
endclass    


class fifo_reset_vseq extends fifo_base_vesq;
    `uvm_object_utils(fifo_reset_vseq)

    function new(string name = "fifo_reset_vseq");
        super.new(name);
    endfunction

    virtual task body();
        fifo_write_seq  before_reset_seq;
        fifo_write_seq  after_reset_seq;
        fifo_read_seq   rd_seq;

        `uvm_info("reset_VESQ","starting reset virtual sequence",UVM_LOW)

        before_reset_seq = fifo_write_seq::type_id::create("before_reset_seq");

        before_reset_seq.num_items = 6 ;
        before_reset_seq.start_data = 8'hA0;
        before_reset_seq.random_data = 1'b0;
        before_reset_seq.wait_for_ready = 1'b1;

        before_reset_seq.start(p_sequencer.wr_sqr);

        apply_midrun_reset();

        after_reset_seq = fifo_write_seq::type_id::create("after_reset_seq");

        after_reset_seq.num_items = 4;
        after_reset_seq.start_data = 8'hC0;
        after_reset_seq.random_data = 1'b0;
        after_reset_seq.wait_for_ready = 1'b1;

        after_reset_seq.start(p_sequencer.wr_sqr);

        rd_seq = fifo_read_seq::type_id::create("rd_seq");

        rd_seq.num_items = 4;
        rd_seq.wait_for_ready = 1'b1;
        rd_seq.start(p_sequencer.rd_sqr);
    
        `uvm_info("RESET_VESQ","reset virtual sequence completed",UVM_LOW)
    endtask
endclass    