class fifo_write_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_write_monitor)

    virtual async_fifo_if #(DATA_WIDTH) vif;
    uvm_analysis_port #(fifo_seq_item)  ap;

    function new(string name = "fifo_write_monitor",uvm_component parent = null);
        super.new(name,parent);
        ap = new("ap",this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual async_fifo_if #(DATA_WIDTH))::get(this,"","vif",vif))begin
            `uvm_fatal("WR_MON","cannot get vif")
        end
    endfunction

    task run_phase(uvm_phase phase);
        fifo_seq_item tr;
        forever begin
            @(posedge vif.wr_clk);
            if (vif.wr_rst_n && vif.wr_en && !vif.full) begin
                tr = fifo_seq_item::type_id::create("tr");
                tr.op = fifo_seq_item::FIFO_WRITE;
                tr.data = vif.wr_data;
                `uvm_info("WR_MON",$sformatf("observed write data = 0x%0h",tr.data),UVM_MEDIUM)
                ap.write(tr);
            end
        end
    endtask
endclass


class fifo_read_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_read_monitor)

    virtual async_fifo_if #(DATA_WIDTH) vif;
    uvm_analysis_port #(fifo_seq_item)  ap;

    function new(string name = "fifo_read_monitor",uvm_component parent = null);
        super.new(name,parent);
        ap = new("ap",this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual async_fifo_if #(DATA_WIDTH))::get(this,"","vif",vif))begin
            `uvm_fatal("RD_MON","cannot get vif")
        end
    endfunction

    task run_phase(uvm_phase phase);
        fifo_seq_item tr;
        forever begin
            @(posedge vif.rd_clk);
            if (vif.rd_rst_n && vif.rd_en && !vif.empty) begin
                tr = fifo_seq_item::type_id::create("tr");
                tr.op = fifo_seq_item::FIFO_READ;
                tr.data = vif.rd_data;
                `uvm_info("RD_MON",$sformatf("observed read data = 0x%0h",tr.data),UVM_MEDIUM)
                ap.write(tr);
            end
        end
    endtask
endclass
