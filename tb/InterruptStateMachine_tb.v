// =============================================================================
// EEE4120F Project — Specialised StarCore-1 Processor
// File        : DataMemory_tb.v
// Description : Testbench for the Data Interrupt State Machine.
//               Verifies the correct sequential jumping between states.
//
// Run:
//   iverilog -Wall -I ../src -o ../build/ism_sim ../src/InterruptStateMachine.v InterruptStateMachine_tb.v
//   cd ../test && ../build/ism_sim
//   gtkwave ../waves/ism_tb.vcd &
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module InterruptStateMachine_tb;

    reg         clk;
    reg         interrupt_pin;
    reg         interrupt_reset;
    reg         interrupt_en;
    wire        request_interrupt;

    InterruptStateMachine uut (
        .clk                (clk),
        .interrupt_pin      (interrupt_pin),
        .interrupt_reset    (interrupt_reset),
        .interrupt_en       (interrupt_en),
        .request_interrupt  (request_interrupt)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    integer fail_count;
    integer test_id;

    initial begin
        fail_count      = 0;
        test_id         = 1;
        interrupt_pin   = 1'b0;
        interrupt_reset = 1'b0;
        interrupt_en    = 1'b0;

        $display("=== InterruptStateMachine Testbench ===");

        // ------------------------------------------------------------------
        // TEST GROUP 1: The state machine does not initially request an interrupt
        // ------------------------------------------------------------------
        $display("--- Group 1: The state machine doesn't initially request interrupt ---");

        // Test initial state
        if (request_interrupt !== 1'b0) begin
            $display("FAIL [T%0d]: initially requests an interrupt", test_id);
            fail_count = fail_count + 1;
        end
        else
            $display("PASS [T%0d]", test_id);
        test_id = test_id + 1;

        // Test that a clock cycle doesn't request an interrupt
        @(posedge clk); #1;
        if (request_interrupt !== 1'b0) begin
            $display("FAIL [T%0d]: clock cycles request an interrupt", test_id);
            fail_count = fail_count + 1;
        end
        else
            $display("PASS [T%0d]", test_id);
        test_id = test_id + 1;

        // Test that the reset pin doesn't request an interrupt
        interrupt_reset = 1'b1;
        @(posedge clk); #1;
        if (request_interrupt !== 1'b0) begin
            $display("FAIL [T%0d]: reset signal requests an interrupt", test_id);
            fail_count = fail_count + 1;
        end
        else
            $display("PASS [T%0d]", test_id);
        test_id = test_id + 1;
        interrupt_reset = 1'b0;

        // Test that the enabling interrupts doesn't request an interrupt
        interrupt_en = 1'b1;
        @(posedge clk); #1;
        if (request_interrupt !== 1'b0) begin
            $display("FAIL [T%0d]: enable signal requests an interrupt", test_id);
            fail_count = fail_count + 1;
        end
        else
            $display("PASS [T%0d]", test_id);
        test_id = test_id + 1;
        interrupt_en = 1'b0;

        // ------------------------------------------------------------------
        // TEST GROUP 2: The state machine jumps between states correctly
        // ------------------------------------------------------------------
        $display("--- Group 2: States jump between correctly ---");

        // Test that interrupts can't be triggered while disabled
        interrupt_pin = 1'b1; #1;
        if (request_interrupt !== 1'b0) begin
            $display("FAIL [T%0d]: interrupt triggered while disabled", test_id);
            fail_count = fail_count + 1;
        end
        else
            $display("PASS [T%0d]", test_id);
        test_id = test_id + 1;
        interrupt_pin = 1'b0;

        // Trigger an interrupt
        interrupt_en = 1'b1; #1; // Enable interrupt
        interrupt_pin = 1'b1; #1;
        if (request_interrupt !== 1'b1) begin
            $display("FAIL [T%0d]: interrupt failed to trigger", test_id);
            fail_count = fail_count + 1;
        end
        else
            $display("PASS [T%0d]", test_id);
        test_id = test_id + 1;

        // Check that falling edge of interrupt doesn't disable the request
        interrupt_pin = 1'b0;
        if (request_interrupt !== 1'b1) begin
            $display("FAIL [T%0d]: falling edge of pin disabled interrupt", test_id);
            fail_count = fail_count + 1;
        end
        else
            $display("PASS [T%0d]", test_id);
        test_id = test_id + 1;

        // Check automatic transition to "active" state
        @(posedge clk); #1;
        if (request_interrupt !== 1'b0) begin
            $display("FAIL [T%0d]: state did not transfer away from 'requesting'", test_id);
            fail_count = fail_count + 1;
        end
        else
            $display("PASS [T%0d]", test_id);
        test_id = test_id + 1;

        // Check that clock cycle does not request interrupt
        @(posedge clk); #1;
        if (request_interrupt !== 1'b0) begin
            $display("FAIL [T%0d]: clock cycle triggered interrupt from 'active'", test_id);
            fail_count = fail_count + 1;
        end
        else
            $display("PASS [T%0d]", test_id);
        test_id = test_id + 1;

        // Check that interrupts can no longer be triggered
        interrupt_pin = 1; #1;
        interrupt_pin = 0;
        if (request_interrupt !== 1'b0) begin
            $display("FAIL [T%0d]: interrupt re-triggered", test_id);
            fail_count = fail_count + 1;
        end
        else
            $display("PASS [T%0d]", test_id);
        test_id = test_id + 1;

        // ------------------------------------------------------------------
        // TEST GROUP 3: Reset works allows interrupts to be triggered again
        // ------------------------------------------------------------------
        $display("--- Group 3: Reset allows re-triggering interrupts ---");

        // Reset allows interrupts to be triggered again
        // Reset
        interrupt_reset = 1'b1;
        @(posedge clk); #1;
        interrupt_reset = 1'b0;
        // Trigger new interrupt
        interrupt_pin = 1'b1; #1;
        interrupt_pin = 1'b0;
        // Testing
        if (request_interrupt !== 1'b1) begin
            $display("FAIL [T%0d]: interrupt failed to trigger", test_id);
            fail_count = fail_count + 1;
        end
        else
            $display("PASS [T%0d]", test_id);
        test_id = test_id + 1;

        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);
        $finish;
    end

endmodule
