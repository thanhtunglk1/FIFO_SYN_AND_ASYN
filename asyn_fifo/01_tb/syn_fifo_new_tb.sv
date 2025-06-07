`timescale 1ns / 1ps

module syn_fifo_new_tb;

// Parameters
localparam DEPTH = 16;
localparam WIDTH = 8;
localparam CLK_PERIOD = 10; // 10ns clock period

// Signals
logic i_clk;
logic i_rst_n;
logic i_wr_en;
logic i_rd_en;
logic [WIDTH-1:0] i_data_in;
logic [WIDTH-1:0] o_data_out;
logic o_full;
logic o_empty;

// Test variables
logic [WIDTH-1:0] expected_data;
integer error_count;
integer pass_count;

// Instantiate the FIFO
syn_fifo_new #(
    .DEPTH(DEPTH),
    .WIDTH(WIDTH)
) dut (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_wr_en(i_wr_en),
    .i_rd_en(i_rd_en),
    .i_data_in(i_data_in),
    .o_data_out(o_data_out),
    .o_full(o_full),
    .o_empty(o_empty)
);

// Clock generation
initial begin
    i_clk = 0;
    forever #(CLK_PERIOD/2) i_clk = ~i_clk;
end

// Pass/Fail reporting
task report_test_result;
    input string test_name;
    input integer errors;
    begin
        if (errors == 0) begin
            $display("[PASS] %s: No errors detected.", test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %s: %d errors detected.", test_name, errors);
        end
        error_count = error_count + errors;
    end
endtask

// Test stimulus
initial begin
    // Initialize signals
    i_rst_n = 0;
    i_wr_en = 0;
    i_rd_en = 0;
    i_data_in = 0;
    expected_data = 0;
    error_count = 0;
    pass_count = 0;
    
    // Test 0: Reset
    $display("Test 0: Reset FIFO");
    #20;
    i_rst_n = 1;
    @(posedge i_clk);
    assert (o_empty == 1) else begin
        $error("Reset failed: o_empty != 1");
        error_count = error_count + 1;
    end
    assert (o_full == 0) else begin
        $error("Reset failed: o_full != 0");
        error_count = error_count + 1;
    end
    report_test_result("Reset Test", error_count);
    error_count = 0;
    
    // Test 1: Write until FIFO is full
    $display("Test 1: Writing until FIFO is full");
    repeat (DEPTH) begin
        @(posedge i_clk);
        i_wr_en = 1;
        i_data_in = i_data_in + 1;
        #1;
        assert (o_full == 0 || i_data_in == DEPTH) else begin
            $error("Write failed: o_full set too early at data %d", i_data_in);
            error_count = error_count + 1;
        end
        assert (o_empty == 0 || i_data_in == 1) else begin
            $error("Write failed: o_empty not cleared after first write");
            error_count = error_count + 1;
        end
    end
    @(posedge i_clk);
    i_wr_en = 1;
    i_data_in = i_data_in + 1;
    #1;
    assert (o_full == 1) else begin
        $error("Write failed: o_full != 1 after DEPTH writes");
        error_count = error_count + 1;
    end
    i_wr_en = 0;
    report_test_result("Write Until Full Test", error_count);
    error_count = 0;
    
    // Test 2: Read until FIFO is empty
    $display("Test 2: Reading until FIFO is empty");
    expected_data = 1;
    repeat (DEPTH) begin
        @(posedge i_clk);
        i_rd_en = 1;
        #1;
        assert (o_data_out == expected_data) else begin
            $error("Read failed: o_data_out (%d) != expected_data (%d)", o_data_out, expected_data);
            error_count = error_count + 1;
        end
        assert (o_empty == 0 || expected_data == DEPTH) else begin
            $error("Read failed: o_empty set too early at data %d", expected_data);
            error_count = error_count + 1;
        end
        expected_data = expected_data + 1;
    end
    @(posedge i_clk);
    i_rd_en = 1;
    #1;
    assert (o_empty == 1) else begin
        $error("Read failed: o_empty != 1 after DEPTH reads");
        error_count = error_count + 1;
    end
    i_rd_en = 0;
    report_test_result("Read Until Empty Test", error_count);
    error_count = 0;
    
    // Test 3: Simultaneous read and write
    $display("Test 3: Simultaneous read and write");
    expected_data = 0;
    i_data_in = 0;
    repeat (5) begin
        @(posedge i_clk);
        i_wr_en = 1;
        i_rd_en = 1;
        i_data_in = i_data_in + 1;
        #1;
        assert (o_data_out == expected_data + 1) else begin
            $error("Simultaneous read/write failed: o_data_out (%d) != expected_data (%d)", o_data_out, expected_data + 1);
            error_count = error_count + 1;
        end
        assert (o_full == 0) else begin
            $error("Simultaneous read/write failed: o_full set unexpectedly");
            error_count = error_count + 1;
        end
        assert (o_empty == 0) else begin
            $error("Simultaneous read/write failed: o_empty set unexpectedly");
            error_count = error_count + 1;
        end
        expected_data = expected_data + 1;
    end
    i_wr_en = 0;
    i_rd_en = 0;
    report_test_result("Simultaneous Read/Write Test", error_count);
    error_count = 0;
    
    // Test 4: Random write and read
    $display("Test 4: Random write and read");
    repeat (10) begin
        @(posedge i_clk);
        i_wr_en = $random % 2;
        i_rd_en = $random % 2 && !o_empty; // Avoid reading when empty
        if (i_wr_en && !o_full) i_data_in = i_data_in + 1;
        #1;
        if (i_rd_en && !o_empty) begin
            assert (o_data_out == expected_data + 1) else begin
                $error("Random read/write failed: o_data_out (%d) != expected_data (%d)", o_data_out, expected_data + 1);
                error_count = error_count + 1;
            end
            expected_data = expected_data + 1;
        end
    end
    i_wr_en = 0;
    i_rd_en = 0;
    report_test_result("Random Read/Write Test", error_count);
    
    // Final report
    $display("\n=== Test Summary ===");
    $display("Total Tests: 5");
    $display("Tests Passed: %d", pass_count);
    $display("Total Errors: %d", error_count);
    if (error_count == 0) begin
        $display("[FINAL RESULT] All tests PASSED!");
    end else begin
        $display("[FINAL RESULT] Some tests FAILED!");
    end
    
    // End simulation
    #100;
    $finish;
end

endmodule