// =============================================================================
// StarCore-2 — DataMemory Testbench
// =============================================================================
//
// File        : DataMemory_tb.v
// Owner       : Pontsho Mbizo, MBZPON001
// Description : Verifies the 16-word read-only RAM + memory-mapped I/O decode.
//               Address map: 0–12 read-only RAM, 13 reserved, 14 GPIO_OUT,
//               15 GPIO_IN.  GPIO inputs are stubbed by testbench regs.
//
// Run:
//   make dmem
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
        .gpio_out_data (gpio_out_data_stub)
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

        @(posedge clk); #1;
        rst = 1'b0;

        $display("=== DataMemory_tb ===");

        // ------------------------------------------------------------------
        // GROUP 1: $readmemb initialisation — RAM words 0–3
        // ------------------------------------------------------------------
        $display("--- Group 1: $readmemb initialisation (words 0-3) ---");

        bus_read(16'd0, got); check_eq(got, 16'h0008); mem_rd = 1'b0;
        bus_read(16'd1, got); check_eq(got, 16'h0001); mem_rd = 1'b0;
        bus_read(16'd2, got); check_eq(got, 16'h000f); mem_rd = 1'b0;
        bus_read(16'd3, got); check_eq(got, 16'h0000); mem_rd = 1'b0;
        bus_read(16'd4, got); check_eq(got, 16'h0000); mem_rd = 1'b0;

        // ------------------------------------------------------------------
        // GROUP 2: RAM is read-only — writes to RAM addresses are ignored
        // ------------------------------------------------------------------
        $display("--- Group 2: Writes to RAM (0-12) are silently ignored ---");

        bus_read(16'd2, got);                          // capture original value
        bus_write(16'd2, 16'hDEAD);                   // attempt write to RAM
        bus_read(16'd2, got); check_eq(got, 16'h000f); mem_rd = 1'b0;  // must be unchanged

        for (i = 0; i <= 12; i = i + 1) begin
            bus_write(i[15:0], 16'hBEEF);             // write to every RAM slot
            bus_read(i[15:0], got);
            // value should never be 0xBEEF — RAM is pre-loaded or 0x0000
            check_bit((got !== 16'hBEEF), 1'b1, "RAM word unmodified after write");
            mem_rd = 1'b0;
        end

        // ------------------------------------------------------------------
        // GROUP 3: mem_rd = 0 forces read_data to 0
        // ------------------------------------------------------------------
        $display("--- Group 3: mem_rd=0 forces read_data to 0 ---");

        addr = 16'd2; mem_rd = 1'b0; #2;
        check_eq(read_data, 16'h0000);

        gpio_in_data_stub = 16'hF0F0;
        addr = 16'd15; mem_rd = 1'b0; #2;
        check_eq(read_data, 16'h0000);
        gpio_in_data_stub = 16'h0000;

        // ------------------------------------------------------------------
        // GROUP 4: mem_wr = 0 must not trigger gpio_out_we
        // ------------------------------------------------------------------
        $display("--- Group 4: mem_wr=0 must not assert gpio_out_we ---");

        addr = 16'd14; write_data = 16'hAABB; mem_wr = 1'b0; #2;
        check_bit(gpio_out_we, 1'b0, "gpio_out_we=0 when mem_wr=0");

        // ------------------------------------------------------------------
        // GROUP 5: Address decode write-enables (combinational)
        // ------------------------------------------------------------------
        $display("--- Group 5: Address decode write-enables ---");

        // ST → reserved (addr 13): all enables must remain low
        addr = 16'd13; write_data = 16'h0001; mem_wr = 1'b1; #1;
        check_bit(gpio_out_we, 1'b0, "gpio_out_we=0 @ addr 13 (reserved)");
        @(posedge clk); #1; mem_wr = 1'b0;

        // ST → GPIO_OUT (addr 14): gpio_out_we only
        addr = 16'd14; write_data = 16'hAABB; mem_wr = 1'b1; #1;
        check_bit(gpio_out_we, 1'b1, "gpio_out_we=1 @ addr 14 (GPIO_OUT)");
        @(posedge clk); #1; mem_wr = 1'b0;

        // ST → GPIO_IN (addr 15): silently dropped — gpio_out_we must stay low
        addr = 16'd15; write_data = 16'hDEAD; mem_wr = 1'b1; #1;
        check_bit(gpio_out_we, 1'b0, "gpio_out_we=0 @ addr 15 (GPIO_IN, read-only)");
        @(posedge clk); #1; mem_wr = 1'b0;

        // ------------------------------------------------------------------
        // GROUP 6: I/O reads return the correct stub value
        // ------------------------------------------------------------------
        $display("--- Group 6: I/O reads return stub values ---");

        // addr 13: reserved — must return 0 regardless
        bus_read(16'd13, got); check_eq(got, 16'h0000); mem_rd = 1'b0;

        // addr 14: GPIO_OUT stub
        gpio_out_data_stub = 16'hCAFE;
        bus_read(16'd14, got); check_eq(got, 16'hCAFE); mem_rd = 1'b0;
        gpio_out_data_stub = 16'h0000;

        // addr 15: GPIO_IN stub
        gpio_in_data_stub = 16'hBEEF;
        bus_read(16'd15, got); check_eq(got, 16'hBEEF); mem_rd = 1'b0;
        gpio_in_data_stub = 16'h0000;

        // ------------------------------------------------------------------
        // GROUP 7: ST to GPIO_IN silently ignored
        //   Write 0xDEAD to addr 15; LD from addr 15 must still return stub.
        // ------------------------------------------------------------------
        $display("--- Group 7: ST to GPIO_IN silently ignored ---");

        gpio_in_data_stub = 16'h1234;
        bus_write(16'd15, 16'hDEAD);
        bus_read(16'd15, got); check_eq(got, 16'h1234); mem_rd = 1'b0;
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
