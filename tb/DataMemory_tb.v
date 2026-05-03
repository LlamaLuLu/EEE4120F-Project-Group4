// =============================================================================
// StarCore-1+ — DataMemory Testbench
// =============================================================================
//
// File        : DataMemory_tb.v
// Owner       : Alpha (Pontsho Mbizo, MBZPON001)
// Description : Verifies the 32-word RAM + memory-mapped I/O decode logic.
//               Beta's INT_EN/INT_FLAG outputs are stubbed by testbench regs.
//               GPIO read-mux inputs are likewise stubbed.
//
// Run:
//   make dmem
//   (or: cd test && ../build/dm_sim)
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module DataMemory_tb;

    // -------------------------------------------------------------------------
    // DUT ports
    // -------------------------------------------------------------------------
    reg        clk;
    reg        rst;
    reg  [`WORD_WIDTH-1:0] addr;
    reg  [`WORD_WIDTH-1:0] write_data;
    reg        mem_rd;
    reg        mem_wr;
    wire [`WORD_WIDTH-1:0] read_data;

    // GPIO stubs (testbench acts as GPIO.v)
    wire        gpio_out_we;
    wire [`WORD_WIDTH-1:0] gpio_out_din;
    reg  [`WORD_WIDTH-1:0] gpio_in_data_stub;
    reg  [`WORD_WIDTH-1:0] gpio_out_data_stub;

    // Beta stubs (testbench acts as InterruptStateMachine)
    wire        int_en_we;
    wire        int_flag_clr;
    wire [`WORD_WIDTH-1:0] int_bus_din;
    reg  [`WORD_WIDTH-1:0] int_en_data_stub;
    reg  [`WORD_WIDTH-1:0] int_flag_data_stub;

    DataMemory uut (
        .clk           (clk),
        .rst           (rst),
        .addr          (addr),
        .write_data    (write_data),
        .mem_rd        (mem_rd),
        .mem_wr        (mem_wr),
        .read_data     (read_data),
        .gpio_out_we   (gpio_out_we),
        .gpio_out_din  (gpio_out_din),
        .gpio_in_data  (gpio_in_data_stub),
        .gpio_out_data (gpio_out_data_stub),
        .int_en_we     (int_en_we),
        .int_flag_clr  (int_flag_clr),
        .int_bus_din   (int_bus_din),
        .int_en_data   (int_en_data_stub),
        .int_flag_data (int_flag_data_stub)
    );

    // -------------------------------------------------------------------------
    // Clock: 10 ns period
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    initial begin
        $dumpfile("../waves/dm_tb.vcd");
        $dumpvars(0, DataMemory_tb);
    end

    // -------------------------------------------------------------------------
    // Bus helpers
    // -------------------------------------------------------------------------
    integer fail_count;
    integer test_id;

    task bus_write;
        input [`WORD_WIDTH-1:0] a;
        input [`WORD_WIDTH-1:0] d;
        begin
            addr       = a;
            write_data = d;
            mem_wr     = 1'b1;
            @(posedge clk); #1;
            mem_wr     = 1'b0;
        end
    endtask

    // Combinational read: addr + mem_rd, settle, sample, leave mem_rd asserted.
    // Caller de-asserts mem_rd when done.
    task bus_read;
        input  [`WORD_WIDTH-1:0] a;
        output [`WORD_WIDTH-1:0] result;
        begin
            addr   = a;
            mem_rd = 1'b1;
            #2;
            result = read_data;
        end
    endtask

    task check_eq;
        input [`WORD_WIDTH-1:0] got;
        input [`WORD_WIDTH-1:0] exp;
        begin
            if (got !== exp) begin
                $display("FAIL [T%0d]: got=0x%04h  exp=0x%04h", test_id, got, exp);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d]", test_id);
            test_id = test_id + 1;
        end
    endtask

    task check_bit;
        input actual;
        input expected;
        input [255:0] label;
        begin
            if (actual !== expected) begin
                $display("FAIL [T%0d] %s: got=%b  exp=%b", test_id, label, actual, expected);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d] %s", test_id, label);
            test_id = test_id + 1;
        end
    endtask

    // -------------------------------------------------------------------------
    // Test sequence
    // -------------------------------------------------------------------------
    reg [`WORD_WIDTH-1:0] got;
    integer i;

    initial begin
        fail_count         = 0;
        test_id            = 1;
        rst                = 1'b1;
        mem_rd             = 1'b0;
        mem_wr             = 1'b0;
        addr               = 16'd0;
        write_data         = 16'd0;
        gpio_in_data_stub  = 16'h0000;
        gpio_out_data_stub = 16'h0000;
        int_en_data_stub   = 16'h0000;
        int_flag_data_stub = 16'h0000;

        @(posedge clk); #1;
        rst = 1'b0;

        $display("=== DataMemory_tb ===");

        // ------------------------------------------------------------------
        // GROUP 1: $readmemb initialisation — RAM words 0–3
        // ------------------------------------------------------------------
        $display("--- Group 1: $readmemb initialisation (words 0-3) ---");

        bus_read(16'd0, got); check_eq(got, 16'h0001); mem_rd = 1'b0;
        bus_read(16'd1, got); check_eq(got, 16'h0002); mem_rd = 1'b0;
        bus_read(16'd2, got); check_eq(got, 16'h0003); mem_rd = 1'b0;
        bus_read(16'd3, got); check_eq(got, 16'h0004); mem_rd = 1'b0;
        bus_read(16'd8, got); check_eq(got, 16'h0000); mem_rd = 1'b0;  // above init data

        // ------------------------------------------------------------------
        // GROUP 2: Write/read all RAM addresses (skip I/O shadow 4–7)
        // ------------------------------------------------------------------
        $display("--- Group 2: Write/read all RAM addresses ---");

        for (i = 0; i < 32; i = i + 1) begin
            if (i < 4 || i > 7) begin
                bus_write(i[15:0], 16'hA000 | i[15:0]);
                bus_read(i[15:0], got);
                check_eq(got, 16'hA000 | i[15:0]);
                mem_rd = 1'b0;
            end
        end

        // ------------------------------------------------------------------
        // GROUP 3: mem_rd = 0 forces read_data to 0
        // ------------------------------------------------------------------
        $display("--- Group 3: mem_rd=0 forces read_data to 0 ---");

        addr = 16'd2; mem_rd = 1'b0; #2;
        check_eq(read_data, 16'h0000);

        int_en_data_stub = 16'hF0F0;
        addr = 16'd5; mem_rd = 1'b0; #2;
        check_eq(read_data, 16'h0000);
        int_en_data_stub = 16'h0000;

        // ------------------------------------------------------------------
        // GROUP 4: mem_wr = 0 must not alter memory
        // ------------------------------------------------------------------
        $display("--- Group 4: mem_wr=0 must not overwrite memory ---");

        bus_write(16'd10, 16'hCAFE);          // write a known value
        addr = 16'd10; write_data = 16'hDEAD; // attempt disabled write
        mem_wr = 1'b0;
        @(posedge clk); #1;
        bus_read(16'd10, got); check_eq(got, 16'hCAFE); mem_rd = 1'b0;

        // ------------------------------------------------------------------
        // GROUP 5: Address decode — write-enable outputs (combinational)
        // ------------------------------------------------------------------
        $display("--- Group 5: Address decode write-enables ---");

        // ST → INT_FLAG (addr 4): int_flag_clr only
        addr = 16'd4; write_data = 16'h0001; mem_wr = 1'b1; #1;
        check_bit(int_flag_clr, 1'b1, "int_flag_clr @ addr 4");
        check_bit(int_en_we,    1'b0, "int_en_we    @ addr 4");
        check_bit(gpio_out_we,  1'b0, "gpio_out_we  @ addr 4");
        @(posedge clk); #1; mem_wr = 1'b0;

        // ST → INT_EN (addr 5): int_en_we only
        addr = 16'd5; write_data = 16'h0001; mem_wr = 1'b1; #1;
        check_bit(int_en_we,    1'b1, "int_en_we    @ addr 5");
        check_bit(int_flag_clr, 1'b0, "int_flag_clr @ addr 5");
        check_bit(gpio_out_we,  1'b0, "gpio_out_we  @ addr 5");
        @(posedge clk); #1; mem_wr = 1'b0;

        // ST → GPIO_IN (addr 6): silently dropped — no enables
        addr = 16'd6; write_data = 16'hDEAD; mem_wr = 1'b1; #1;
        check_bit(gpio_out_we,  1'b0, "gpio_out_we  @ addr 6 (GPIO_IN)");
        check_bit(int_en_we,    1'b0, "int_en_we    @ addr 6 (GPIO_IN)");
        check_bit(int_flag_clr, 1'b0, "int_flag_clr @ addr 6 (GPIO_IN)");
        @(posedge clk); #1; mem_wr = 1'b0;

        // ST → GPIO_OUT (addr 7): gpio_out_we only
        addr = 16'd7; write_data = 16'hAABB; mem_wr = 1'b1; #1;
        check_bit(gpio_out_we,  1'b1, "gpio_out_we  @ addr 7 (GPIO_OUT)");
        check_bit(int_en_we,    1'b0, "int_en_we    @ addr 7 (GPIO_OUT)");
        check_bit(int_flag_clr, 1'b0, "int_flag_clr @ addr 7 (GPIO_OUT)");
        @(posedge clk); #1; mem_wr = 1'b0;

        // ------------------------------------------------------------------
        // GROUP 6: I/O reads return the correct stub value
        // ------------------------------------------------------------------
        $display("--- Group 6: I/O reads return stub values ---");

        int_flag_data_stub = 16'hF001;
        bus_read(16'd4, got); check_eq(got, 16'hF001); mem_rd = 1'b0;
        int_flag_data_stub = 16'h0000;

        int_en_data_stub = 16'hF002;
        bus_read(16'd5, got); check_eq(got, 16'hF002); mem_rd = 1'b0;
        int_en_data_stub = 16'h0000;

        gpio_in_data_stub = 16'hBEEF;
        bus_read(16'd6, got); check_eq(got, 16'hBEEF); mem_rd = 1'b0;
        gpio_in_data_stub = 16'h0000;

        gpio_out_data_stub = 16'hCAFE;
        bus_read(16'd7, got); check_eq(got, 16'hCAFE); mem_rd = 1'b0;
        gpio_out_data_stub = 16'h0000;

        // ------------------------------------------------------------------
        // GROUP 7: ST to GPIO_IN silently ignored
        //   Write 0xDEAD to addr 6; LD from addr 6 must still return stub.
        // ------------------------------------------------------------------
        $display("--- Group 7: ST to GPIO_IN silently ignored ---");

        gpio_in_data_stub = 16'h1234;
        bus_write(16'd6, 16'hDEAD);
        bus_read(16'd6, got); check_eq(got, 16'h1234); mem_rd = 1'b0;
        gpio_in_data_stub = 16'h0000;

        // ------------------------------------------------------------------
        // Summary
        // ------------------------------------------------------------------
        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);

        $finish;
    end

endmodule
