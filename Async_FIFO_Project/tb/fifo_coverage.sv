`uvm_analysis_imp_decl(_cov_wr)
`uvm_analysis_imp_decl(_cov_rd)

class fifo_coverage extends uvm_component;
    `uvm_component_utils(fifo_coverage)
    virtual async_fifo_if #(DATA_WIDTH) vif;

    uvm_analysis_imp_cov_wr #(fifo_seq_item,fifo_coverage)  wr_imp;
    uvm_analysis_imp_cov_rd #(fifo_seq_item,fifo_coverage)  rd_imp;

    localparam int FIFO_DEPTH = (1<<ADDR_WIDTH); //ADDR_WIDTH = 4深度为16
    int unsigned wr_accept_count;
    int unsigned rd_accept_count;

    covergroup wr_state_cg with function sample(
        bit wr_rst_n,
        bit wr_en,
        bit full
    );
        option.per_instance = 1;
        
        cp_full : coverpoint full iff (wr_rst_n)
        {
            bins not_full = {0};
            bins full ={1};

            bins full_assert = (0 => 1);
             bins full_deassert = (1 => 0);
        } 

         cp_wr_request : coverpoint {wr_en,full} iff (wr_rst_n)
        {
            bins idle_not_full = {2'b00};
            bins full_no_request ={2'b01};

            bins accepted_write = {2'b10};
            bins overflow_attempt = {2'b11};
        } 
    endgroup


    covergroup rd_state_cg with function sample(
        bit rd_rst_n,
        bit rd_en,
        bit empty
    );
        option.per_instance = 1;
        
        cp_empty : coverpoint empty iff (rd_rst_n)
        {
            bins not_empty = {0};
            bins empty ={1};

            bins empty_assert = (0 => 1);
            bins empty_deassert = (1 => 0);
        } 

         cp_rd_request : coverpoint {rd_en,empty} iff (rd_rst_n)
        {
            bins idle_not_empty = {2'b00};
            bins empty_no_request ={2'b01};

            bins accepted_read = {2'b10};
            bins underflow_attempt = {2'b11};
        } 
    endgroup

    covergroup process_cg with function sample(
        bit dir,
        bit wrap_event
    );
        option.per_instance = 1;

        cp_dir : coverpoint dir{
            bins write = {0};
            bins read = {1};
        }

        cp_wrap : coverpoint wrap_event{
            bins normal = {0};
            bins wrap = {1};
        }       

        dir_x_wrap : cross cp_dir,cp_wrap;
    endgroup

    covergroup reset_cg with function sample(
        bit wr_rst_n,
        bit rd_rst_n
    );
        option.per_instance = 1;

        cp_wr_reset : coverpoint wr_rst_n{
            bins assert_reset = (1=>0);
            bins deassert_reset = (0=>1);
        }

        cp_rd_reset : coverpoint rd_rst_n{
            bins assert_reset = (1=>0);
            bins deassert_reset = (0=>1);
        }     

        cp_reset_state : coverpoint{wr_rst_n,rd_rst_n}
        {
            bins both_reset = {2'b00};
            bins both_released = {2'b11};
        }      
    endgroup

    function new(string name = "fifo_coverage",uvm_component parent = null);
        super.new(name,parent);   

        wr_imp = new("wr_imp",this); 
        rd_imp = new("rd_imp",this); 

        wr_state_cg = new();
        rd_state_cg = new();
        process_cg = new();
        reset_cg = new();

        wr_accept_count = 0;
        rd_accept_count = 0;
    endfunction

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual async_fifo_if #(DATA_WIDTH))::get(this,"","vif",vif))begin
            `uvm_fatal("FIFO_COV","cannot get vif")
        end
    endfunction

    function void write_cov_wr(fifo_seq_item tr);
        bit wrap_event;

        if(tr.op != fifo_seq_item::FIFO_WRITE)
        return;

        wr_accept_count++;

        wrap_event = ((wr_accept_count % FIFO_DEPTH)==0);
        process_cg.sample(1'b0,wrap_event);
    endfunction

    function void write_cov_rd(fifo_seq_item tr);
        bit wrap_event;

        if(tr.op != fifo_seq_item::FIFO_READ)
        return;

        rd_accept_count++;

        wrap_event = ((rd_accept_count % FIFO_DEPTH)==0);
        process_cg.sample(1'b1,wrap_event);
    endfunction

    task run_phase(uvm_phase phase);
        fork
            forever begin
                @(negedge vif.wr_rst_n);
                wr_accept_count = 0;
            end

            forever begin
                @(negedge vif.rd_rst_n);
                rd_accept_count = 0;
            end

            forever begin
                @(posedge vif.wr_clk);
                wr_state_cg.sample(vif.wr_rst_n,vif.wr_en,vif.full);
            end

            forever begin
                @(posedge vif.rd_clk);
                rd_state_cg.sample(vif.rd_rst_n,vif.rd_en,vif.empty);
            end

            forever begin
                @(vif.wr_rst_n or vif.rd_rst_n);
                reset_cg.sample(vif.wr_rst_n,vif.rd_rst_n);
            end
        join
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV_REPORT",$sformatf("WR = %0.2f%% RD = %0.2f%%  PROGRESS = %0.2f%% RESET = %0.2f%%",
            wr_state_cg.get_inst_coverage(),
            rd_state_cg.get_inst_coverage(),
            process_cg.get_inst_coverage(),
            reset_cg.get_inst_coverage()
        ),UVM_NONE)
    endfunction
endclass
            