class fifo_seq_item extends uvm_sequence_item;
    typedef enum bit{
        FIFO_WRITE = 1'b0,
        FIFO_READ = 1'b1
    }fifo_op_e;

    rand fifo_op_e op;
    rand bit [DATA_WIDTH-1:0] data;
    bit wait_for_ready;

    `uvm_object_utils_begin(fifo_seq_item)
        `uvm_field_enum(
            fifo_op_e,
            op,
            UVM_ALL_ON
        )
        `uvm_field_int(
            data,
            wait_for_ready,
            UVM_ALL_ON
        )
    `uvm_object_utils_end   

    function new(string name = "fifo_seq_item");
        super.new(name);
        wait_for_ready = 1'b1;
    endfunction
endclass