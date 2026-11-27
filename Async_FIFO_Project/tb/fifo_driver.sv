class fifo_write_driver extends uvm_driver #(fifo_seq_item);
    `uvm_component_utils(fifo_write_driver)
    virtual async_fifo_if   vif;

    function new(string name = "fifo_write_driver",uvm_component parent = null);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual async_fifo_if)::get(this,"","vif",vif))begin
            `uvm_fatal("WR_DRV","cannot get vif")
        end
    endfunction

    task run_phase(uvm_phase phase);
        fifo_seq_item   tr;

        vif.wr_en <= 1'b0;
        vif.wr_data <= '0;

        forever begin
            seq_item_port.get_next_item(tr);
            if(tr.op==fifo_seq_item::FIFO_WRITE)begin
                drive_write(tr);
            end
            else begin
                `uvm_warning("WR_DRV","write driver received none-write tr")
            end
            seq_item_port.item_done();
        end
    endtask

    task drive_write(fifo_seq_item tr);
        if(tr.wait_for_ready)begin
        do begin
            @(negedge vif.wr_clk);
            end
        while(!vif.wr_rst_n || vif.full);
        end

        else begin
            do begin
                @(negedge vif.wr_clk);
                end
                while(!vif.wr_rst_n);
        end

        vif.wr_data <= tr.data;
        vif.wr_en <= 1'b1;
        `uvm_info("WR_DRV",$sformatf("WRITE data = 0x%0h wait_ready = %0b full = %0b",tr.data,tr.wait_for_ready,vif.full),UVM_MEDIUM)

        @(negedge vif.wr_clk);
        vif.wr_en <= 1'b0;
    endtask
endclass


class fifo_read_driver extends uvm_driver #(fifo_seq_item);
    `uvm_component_utils(fifo_read_driver)
    virtual async_fifo_if   vif;

    function new(string name = "fifo_read_driver",uvm_component parent = null);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual async_fifo_if)::get(this,"","vif",vif))begin
            `uvm_fatal("RD_DRV","cannot get vif")
        end
    endfunction

    task run_phase(uvm_phase phase);
        fifo_seq_item   tr;

        vif.rd_en <= 1'b0;

        forever begin
            seq_item_port.get_next_item(tr);
            if(tr.op==fifo_seq_item::FIFO_READ)begin
                drive_read(tr);
            end
            else begin
                `uvm_warning("RD_DRV","read driver received none-read tr")
            end
            seq_item_port.item_done();
        end
    endtask

    task drive_read(fifo_seq_item tr);
        if(tr.wait_for_ready)begin
        do begin
            @(negedge vif.rd_clk);
            end
        while(!vif.rd_rst_n || vif.empty);
        end

        else begin
            do begin
                @(negedge vif.rd_clk);
                end
                while(!vif.rd_rst_n);
        end

        vif.rd_en <= 1'b1;
        `uvm_info("RD_DRV",$sformatf(" wait_ready = %0b empty = %0b",tr.wait_for_ready,vif.empty),UVM_MEDIUM)

        @(negedge vif.rd_clk);
        vif.rd_en <= 1'b0;
    endtask
endclass
    