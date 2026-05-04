// =============================================================================
// EEE4120F Project — Specialised StarCore-1 Processor
// File        : ProgramCounterLogic_tb.v
// Description : Unit testbench for ProgramCounterLogic.
//               Tests all PC update paths in priority order:
//               RETI > interrupt > jump > branch > sequential.
//
// Run from project root:
//   iverilog -Wall -I src/ -o build/pcl_sim \
//       src/Parameter.v src/ProgramCounterLogic.v tb/ProgramCounterLogic_tb.v
//   cd test && ../build/pcl_sim
//   gtkwave ../waves/pcl_tb.vcd &
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module ProgramCounterLogic_tb;

    // -------------------------------------------------------------------------
    // Inputs
    // -------------------------------------------------------------------------
    reg        clk;
    reg        request_interrupt;
    reg        interrupt_reset;
    reg        jump;
    reg        beq;
    reg        bne;
    reg        zero_flag;
    reg [11:0] instr_jump_field;
    reg [15:0] ext_im;

    // -------------------------------------------------------------------------
    // Output
    // -------------------------------------------------------------------------
    wire [15:0] pc_current;

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    ProgramCounterLogic uut (
        .clk              (clk),
        .request_interrupt(request_interrupt),
        .interrupt_reset  (interrupt_reset),
        .jump             (jump),
        .beq              (beq),
        .bne              (bne),
        .zero_flag        (zero_flag),
        .instr_jump_field (instr_jump_field),
        .ext_im           (ext_im),
        .pc_current       (pc_current)
    );

    // -------------------------------------------------------------------------
    // Clock: 10 ns period
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Waveform dump
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("../waves/pcl_tb.vcd");
        $dumpvars(0, ProgramCounterLogic_tb);
    end

    integer fail_count;
    integer test_id;

    // -------------------------------------------------------------------------
    // check16: compare 16-bit observed vs expected.
    // Uses !== so it catches X and Z as failures.
    // -------------------------------------------------------------------------
    task check16;
        input [15:0] got;
        input [15:0] expected;
        input [63:0] id;
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d]: pc=0x%h, expected=0x%h", id, got, expected);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d]: pc=0x%h", id, got);
        end
    endtask

    // -------------------------------------------------------------------------
    // safe_defaults: deassert all control signals
    // -------------------------------------------------------------------------
    task safe_defaults;
        begin
            request_interrupt = 1'b0;
            interrupt_reset   = 1'b0;
            jump              = 1'b0;
            beq               = 1'b0;
            bne               = 1'b0;
            zero_flag         = 1'b0;
            instr_jump_field  = 12'd0;
            ext_im            = 16'd0;
        end
    endtask

    // =========================================================================
    // MAIN STIMULUS
    // =========================================================================
    initial begin
        fail_count = 0;
        test_id    = 1;

        safe_defaults;

        $display("=== ProgramCounterLogic Testbench ===");

        // ------------------------------------------------------------------
        // T1: Initial state — PC must be 0x0000 before any clock edge
        // ------------------------------------------------------------------
        $display("--- T1: Initial state ---");
        #1;
        check16(pc_current, 16'h0000, test_id);
        test_id = test_id + 1;

        // ------------------------------------------------------------------
        // T2–T3: Sequential advance — PC += 2 each cycle
        // ------------------------------------------------------------------
        $display("--- T2-T3: Sequential ---");

        // PC: 0x0000 → 0x0002
        @(posedge clk); #1;
        check16(pc_current, 16'h0002, test_id);
        test_id = test_id + 1;

        // PC: 0x0002 → 0x0004
        @(posedge clk); #1;
        check16(pc_current, 16'h0004, test_id);
        test_id = test_id + 1;

        // ------------------------------------------------------------------
        // T4: Jump
        //   PC=0x0004, pc2=0x0006
        //   instr_jump_field=12'd5 → jump_target={5,0}=10 → pc_jump={pc2[15:13],10}=10
        //   Expected: PC = 0x000A (10)
        // ------------------------------------------------------------------
        $display("--- T4: Jump ---");
        jump             = 1'b1;
        instr_jump_field = 12'd5;

        @(posedge clk); #1;
        check16(pc_current, 16'h000A, test_id);
        test_id = test_id + 1;
        safe_defaults;

        // ------------------------------------------------------------------
        // T5: BEQ taken (beq=1, zero_flag=1)
        //   PC=0x000A, pc2=0x000C (12)
        //   ext_im=16'd5 → branch offset = {5[14:0], 0} = 10
        //   pc_branch = 12 + 10 = 22 = 0x0016
        // ------------------------------------------------------------------
        $display("--- T5: BEQ taken ---");
        beq       = 1'b1;
        zero_flag = 1'b1;
        ext_im    = 16'd5;

        @(posedge clk); #1;
        check16(pc_current, 16'h0016, test_id);
        test_id = test_id + 1;
        safe_defaults;

        // ------------------------------------------------------------------
        // T6: BEQ not taken (beq=1, zero_flag=0) — falls through to sequential
        //   PC=0x0016, pc2=0x0018 (24)
        //   Expected: PC = 0x0018
        // ------------------------------------------------------------------
        $display("--- T6: BEQ not taken ---");
        beq       = 1'b1;
        zero_flag = 1'b0;
        ext_im    = 16'd5;

        @(posedge clk); #1;
        check16(pc_current, 16'h0018, test_id);
        test_id = test_id + 1;
        safe_defaults;

        // ------------------------------------------------------------------
        // T7: BNE taken (bne=1, zero_flag=0)
        //   PC=0x0018, pc2=0x001A (26)
        //   ext_im=16'd2 → branch offset = {2[14:0], 0} = 4
        //   pc_branch = 26 + 4 = 30 = 0x001E
        // ------------------------------------------------------------------
        $display("--- T7: BNE taken ---");
        bne       = 1'b1;
        zero_flag = 1'b0;
        ext_im    = 16'd2;

        @(posedge clk); #1;
        check16(pc_current, 16'h001E, test_id);
        test_id = test_id + 1;
        safe_defaults;

        // ------------------------------------------------------------------
        // T8: BNE not taken (bne=1, zero_flag=1) — falls through to sequential
        //   PC=0x001E, pc2=0x0020 (32)
        //   Expected: PC = 0x0020
        // ------------------------------------------------------------------
        $display("--- T8: BNE not taken ---");
        bne       = 1'b1;
        zero_flag = 1'b1;
        ext_im    = 16'd2;

        @(posedge clk); #1;
        check16(pc_current, 16'h0020, test_id);
        test_id = test_id + 1;
        safe_defaults;

        // ------------------------------------------------------------------
        // T9–T10: Interrupt then RETI
        //   PC=0x0020
        //   On interrupt: PC → 0x0002, epc ← 0x0020 (re-execute on return)
        //   On RETI:      PC → epc = 0x0020
        // ------------------------------------------------------------------
        $display("--- T9: Interrupt fires ---");
        request_interrupt = 1'b1;

        @(posedge clk); #1;
        check16(pc_current, 16'h0002, test_id);
        test_id = test_id + 1;
        safe_defaults;

        $display("--- T10: RETI restores PC ---");
        interrupt_reset = 1'b1;

        @(posedge clk); #1;
        check16(pc_current, 16'h0020, test_id);
        test_id = test_id + 1;
        safe_defaults;

        // ------------------------------------------------------------------
        // T11–T12: Interrupt priority over jump
        //   PC=0x0020
        //   Both request_interrupt and jump asserted — interrupt must win.
        //   Expected: PC → 0x0002, epc ← 0x0020 (not the jump target)
        //   Then RETI restores to 0x0020.
        // ------------------------------------------------------------------
        $display("--- T11: Interrupt priority over jump ---");
        request_interrupt = 1'b1;
        jump              = 1'b1;
        instr_jump_field  = 12'd100;

        @(posedge clk); #1;
        check16(pc_current, 16'h0002, test_id);
        test_id = test_id + 1;
        safe_defaults;

        $display("--- T12: RETI after priority test restores correct epc ---");
        interrupt_reset = 1'b1;

        @(posedge clk); #1;
        check16(pc_current, 16'h0020, test_id);
        test_id = test_id + 1;
        safe_defaults;

        // ------------------------------------------------------------------
        // T13: Sequential resumes correctly after RETI
        //   PC=0x0020 → 0x0022
        // ------------------------------------------------------------------
        $display("--- T13: Sequential after RETI ---");
        @(posedge clk); #1;
        check16(pc_current, 16'h0022, test_id);
        test_id = test_id + 1;

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
