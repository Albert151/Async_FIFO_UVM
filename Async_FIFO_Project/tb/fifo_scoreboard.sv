`uvm_analysis_imp_decl(_wr)
`uvm_analysis_imp_decl(_rd)

class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)
    uvm_analysis_imp_wr #(fifo_seq_item,fifo_scoreboard)    wr_imp;
    uvm_analysis_imp_rd #(fifo_seq_item,fifo_scoreboard)    rd_imp;
    virtual async_fifo_if #(DATA_WIDTH) vif;

    bit [DATA_WIDTH-1:0] expected_queue[$];

    int unsigned write_count;
    int unsigned read_count;
    int unsigned error_count;

    function new(string name = "fifo_scoreboard",uvm_component parent = null);
        super.new(name,parent);

        wr_imp = new("wr_imp",this);
        rd_imp = new("rd_imp",this);

        write_count = 0;
        read_count = 0;
        error_count = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual async_fifo_if #(DATA_WIDTH))::get(this,"","vif",vif))begin
            `uvm_fatal("SCB","cannot get vif")
        end
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            @(negedge vif.wr_rst_n or negedge vif.rd_rst_n);
        `uvm_info("SCB_RESET",$sformatf("Reset assertion detected : wr_rst_n = %0b rd_rst_n = %0b",vif.wr_rst_n,vif.rd_rst_n),UVM_LOW)
            reset_model();
            wait(vif.wr_rst_n === 1'b1 && vif.rd_rst_n === 1'b1);
        end
    endtask

    function void write_wr(fifo_seq_item tr);
        if(tr.op != fifo_seq_item::FIFO_WRITE)begin
            `uvm_warning("SCB_WR","write analysis port received non_write transaction")
            return;
        end
        expected_queue.push_back(tr.data);

        write_count++;
        `uvm_info("SCB_WR",$sformatf("PUSH data = 0x%0h queue_depth = %0d",tr.data,expected_queue.size()),UVM_MEDIUM)
    endfunction

    function void write_rd(fifo_seq_item tr);
        bit [DATA_WIDTH-1:0] expected_data;

        if(tr.op != fifo_seq_item::FIFO_READ)begin
            `uvm_warning("SCB_RD","read analysis port receiverd non_read transaction")
            return;
        end

        if(expected_queue.size() == 0)begin
            error_count++;
            `uvm_error("SCB_UNDERFLOW",$sformatf("reference queue is empty but DUT produced read data = 0x%0h",tr.data))
            return;
        end 
        expected_data = expected_queue.pop_front();
        read_count++;

        if(tr.data !== expected_data)begin
            error_count++;
            `uvm_error("SCB_MISMATCH",$sformatf("DATA MISMATCH: expected = 0x%0h actual data = 0x%0h",expected_data,tr.data))
         end
        else begin
            `uvm_info("SCB_RD",$sformatf("POP PASS data = 0x%0h queue_depth = %0d",tr.data,expected_queue.size()),UVM_MEDIUM)
            end
    endfunction

    function void reset_model();
        `uvm_info("SCB_RESET",$sformatf("CLEAR reference queue:time = %0t depth_before = %0d wr_rst_n = %0b rd_rst_n = %0b",$time,expected_queue.size(),vif.wr_rst_n,vif.rd_rst_n),UVM_LOW)
        expected_queue.delete();
    endfunction

    function void clear_statistics();
        write_count = 0;
        read_count = 0;
        error_count = 0;
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if(expected_queue.size()!=0)begin
            `uvm_error("SCB_PENDING",$sformatf("%0d expected entries remain in reference FIFO",expected_queue.size()))
        end.
        00
    endfunction
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("SCB_REPORT",$sformatf("\nasync fifo scoreboard\n  accepted writes : %0d accepted reads:%0d pending entries:%0d data error:%0d",
            write_count,
            read_count,
            expected_queue.size(),
            error_count
        ),UVM_NONE)
    endfunction
endclass


        
