// =============================================================================
// StarCore-1+ — GPIO Testbench
// =============================================================================
//
// File        : GPIO_tb.v
// Owner       : Alpha (Pontsho Mbizo, MBZPON001)
// Description : Isolated tests for GPIO.v.  DataMemory is not instantiated;
//               gpio_out_we is driven directly by the testbench.
//
// Run:
//   make gpio
//   (or: cd test && ../build/gpio_sim)
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module GPIO_tb;

    reg        clk;
    reg        rst;
    reg        gpio_out_we;
    reg  [`WORD_WIDTH-1:0] gpio_out_din;
    reg  [`WORD_WIDTH-1:0] io_in_pins;

    wire [`WORD_WIDTH-1:0] gpio_in_data;
    wire [`WORD_WIDTH-1:0] gpio_out_data;
    wire [`WORD_WIDTH-1:0] io_out_pins;
    wire        irq_pin;

    GPIO uut (
        .clk          (clk),
        .rst          (rst),
        .gpio_out_we  (gpio_out_we),
        .gpio_out_din (gpio_out_din),
        .io_in_pins   (io_in_pins),
        .gpio_in_data (gpio_in_data),
        .gpio_out_data(gpio_out_data),
        .io_out_pins  (io_out_pins),
        .irq_pin      (irq_pin)
    );

    initial clk = 1'b0;
    always  #5 clk = ~clk;

    initial begin
        $dumpfile("../waves/gpio_tb.vcd");
        $dumpvars(0, GPIO_tb);
    end

    integer fail_count;
    integer test_id;

    task check_eq;
        input [`WORD_WIDTH-1:0] got;
        input [`WORD_WIDTH-1:0] exp;
        input [63:0] id;
        input [127:0] label;
        begin
            if (got !== exp) begin
                $display("FAIL [T%0d] %s: got=0x%04h  exp=0x%04h", id, label, got, exp);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d] %s", id, label);
        end
    endtask

    task check_bit;
        input actual;
        input expected;
        input [63:0] id;
        input [127:0] label;
        begin
            if (actual !== expected) begin
                $display("FAIL [T%0d] %s: got=%b  exp=%b", id, label, actual, expected);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d] %s", id, label);
        end
    endtask

    initial begin
        fail_count  = 0;
        test_id     = 1;
        rst         = 1'b1;
        gpio_out_we = 1'b0;
        gpio_out_din= 16'h0000;
        io_in_pins  = 16'h0000;

        $display("=== GPIO_tb ===");

        // ------------------------------------------------------------------
        // T1: Reset clears GPIO_OUT to 0
        // ------------------------------------------------------------------
        $display("--- T1: Reset clears GPIO_OUT ---");
        gpio_out_din = 16'hFFFF;
        gpio_out_we  = 1'b1;
        rst = 1'b1;
        @(posedge clk); #1;
        gpio_out_we = 1'b0;
        check_eq(gpio_out_data, 16'h0000, test_id, "gpio_out_data after rst"); test_id = test_id + 1;
        check_eq(io_out_pins,   16'h0000, test_id, "io_out_pins after rst");   test_id = test_id + 1;
        rst = 1'b0;

        // ------------------------------------------------------------------
        // T3-T4: Sequential writes update GPIO_OUT and io_out_pins
        // ------------------------------------------------------------------
        $display("--- T3-T6: Sequential writes to GPIO_OUT ---");
        gpio_out_din = 16'hABCD;
        gpio_out_we  = 1'b1;
        @(posedge clk); #1;
        gpio_out_we  = 1'b0;
        check_eq(gpio_out_data, 16'hABCD, test_id, "gpio_out_data after write 0xABCD"); test_id = test_id + 1;
        check_eq(io_out_pins,   16'hABCD, test_id, "io_out_pins  after write 0xABCD");  test_id = test_id + 1;

        gpio_out_din = 16'h1234;
        gpio_out_we  = 1'b1;
        @(posedge clk); #1;
        gpio_out_we  = 1'b0;
        check_eq(gpio_out_data, 16'h1234, test_id, "gpio_out_data after write 0x1234"); test_id = test_id + 1;
        check_eq(io_out_pins,   16'h1234, test_id, "io_out_pins  after write 0x1234");  test_id = test_id + 1;

        // ------------------------------------------------------------------
        // T7: gpio_out_we = 0 holds the register
        // ------------------------------------------------------------------
        $display("--- T7: gpio_out_we=0 holds register ---");
        gpio_out_din = 16'hDEAD;
        gpio_out_we  = 1'b0;
        @(posedge clk); #1;
        check_eq(gpio_out_data, 16'h1234, test_id, "gpio_out_data unchanged when we=0"); test_id = test_id + 1;

        // ------------------------------------------------------------------
        // T8: gpio_in_data is a pure combinational mirror of io_in_pins
        // ------------------------------------------------------------------
        $display("--- T8-T9: gpio_in_data mirrors io_in_pins combinationally ---");
        io_in_pins = 16'hBEEF; #1;
        check_eq(gpio_in_data, 16'hBEEF, test_id, "gpio_in_data mirrors 0xBEEF"); test_id = test_id + 1;

        io_in_pins = 16'h5A5A; #1;
        check_eq(gpio_in_data, 16'h5A5A, test_id, "gpio_in_data mirrors 0x5A5A"); test_id = test_id + 1;

        // ------------------------------------------------------------------
        // T10-T11: irq_pin follows io_in_pins[0]
        // ------------------------------------------------------------------
        $display("--- T10-T11: irq_pin tracks io_in_pins[0] ---");
        io_in_pins = 16'hFFFE; #1;   // bit 0 = 0
        check_bit(irq_pin, 1'b0, test_id, "irq_pin=0 when io_in_pins[0]=0"); test_id = test_id + 1;

        io_in_pins = 16'h0001; #1;   // bit 0 = 1
        check_bit(irq_pin, 1'b1, test_id, "irq_pin=1 when io_in_pins[0]=1"); test_id = test_id + 1;

        io_in_pins = 16'h0000;

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
