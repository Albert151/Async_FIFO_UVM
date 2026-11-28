class fifo_write_sequencer extends uvm_sequencer #(fifo_seq_item);
    `uvm_component_utils(fifo_write_sequencer)
    function new(srting name  = "fifo_write_sequencer",uvm_component parent = null);
        super.new(name,parent);
    endfunction
endclass

class fifo_read_sequencer extends uvm_sequencer #(fifo_seq_item);
    `uvm_component_utils(fifo_read_sequencer)
    function new(srting name  = "fifo_read_sequencer",uvm_component parent = null);
        super.new(name,parent);
    endfunction
endclass