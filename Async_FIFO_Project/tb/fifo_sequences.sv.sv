class fifo_write_seq extends uvm_sequence #(fifo_seq_item);
    `uvm_object_utils(fifo_write_seq)

    int unsigned num_items;
    bit [DATA_WIDTH-1:0] start_data;
    bit random_data;
    bit wait_for_ready;

    function new(string name = "fifo_write_seq");
        super.new(name);
        num_items = 8;
        start_data = 8'h10;
        random_data = 1'b0;
        wait_for_ready = 1'b1;

    endfunction
    virtual task body();
        fifo_seq_item tr;

        for(int unsigned i=0;i<num_items;i++)begin
            tr=fifo_write_seq::type_id::create("tr");

            start_item(tr);
            if(random_data) begin
                if(!tr.randomize())begin
                    `uvm_fatal("WR_SEQ","Transaction randomization failed")
                end
            end
            else begin  
                tr.data = start_data + 1;
            end

            tr.op = fifo_seq_item::FIFO_WRITE;
            tr,wait_for_ready = wait_for_ready;

            finish_item(tr);
            `uvm_info("WR_SEQ",$sformatf("WRITE item %0d data = 0x%0h wait_for_ready = %0b",i,tr.data,tr.wait_for_ready),UVM_MEDIUM)
        end
    endtask