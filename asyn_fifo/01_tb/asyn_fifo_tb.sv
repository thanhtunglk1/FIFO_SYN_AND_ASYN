module asyn_fifo_tb;
    parameter ENDTIME = 5000;
    parameter DEPTH = 16;
    parameter WIDTH = 8 ;
    localparam ADDR_WIDTH = $clog2(DEPTH);

//GLOBAL
    logic i_clk_wr;
    logic i_clk_rd;
    logic i_rst_n ;

//CONTROL SIGNAL
    logic i_wr_en;
    logic i_rd_en;

//IN_OUT DATA
    logic [WIDTH - 1:0] i_data_in;
    logic [WIDTH - 1:0] o_data_out;

//STATUS
    logic o_full;
    logic o_empty;

    afifo #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH)
    ) uut (
        .i_clk_wr(i_clk_wr),
        .i_clk_rd(i_clk_rd),
        .i_rst_n(i_rst_n),
        .i_wr_en(i_wr_en),
        .i_rd_en(i_rd_en),
        .i_data_in(i_data_in),
        .o_data_out(o_data_out),
        .o_full(o_full),
        .o_empty(o_empty)
    );

    initial begin 
        $shm_open("waves.shm");
        $shm_probe("ASM");
    end

    always #5 i_clk_wr = ~i_clk_wr;
    always #7 i_clk_rd = ~i_clk_rd;

    initial begin
        $display("--------------------[TEST] Simulation Started--------------------");
        // Initialize signals
        i_clk_wr  = 0;
        i_clk_rd  = 0;
        i_rst_n   = 0;
        i_wr_en   = 0;
        i_rd_en   = 0;
        i_data_in = 0;

        // Reset sequence
        #10 i_rst_n = 1;
        $display("[TEST] Reset completed");

        // Test writing to FIFO until full
        $display("--------------------[TEST] Writing to FIFO until full--------------------");
        for (int i = 0; i <= DEPTH; i++) begin
            @(posedge i_clk_wr);
            if (!o_full) begin
                #1
                i_wr_en = 1;
                i_data_in = i;
            end else begin
                #1
                i_wr_en = 0;
            end
        end

        // Test reading from FIFO until empty
        $display("--------------------[TEST] Reading from FIFO until empty--------------------");
        for (int j = 0; j < DEPTH; j++) begin
            @(posedge i_clk_rd);
            if (!o_empty) begin
                #1
                i_rd_en = 1;
            end else begin
                #1
                i_rd_en = 0;
            end
        end

        $display("[TEST] Simulation Completed");

        #ENDTIME;
        $finish;
    end

endmodule