// =============================================================================
// EEE4120F Practical 4 — StarCore-1 Processor
// File        : ControlUnit_tb.v
// Description : Testbench for the Main Control Unit.
//
// HOW THIS TESTBENCH WORKS
// ------------------------
// The ControlUnit is purely combinational (always @(*), blocking =).
// It takes a 4-bit opcode and produces 10 control signals.
// No clock is needed — we set the opcode and check outputs after #10.
//
// THE 10 CONTROL SIGNALS (what each one does in the datapath)
// -----------------------------------------------------------
// alu_op    [1:0] — sent to ALU_Control to determine operation class:
//                   2'b10 = memory (always ADD for address calc)
//                   2'b01 = branch (always SUB for comparison)
//                   2'b00 = R-type (decode from opcode)
//
// jump            — mux select: replace PC with jump target address
// beq             — enable branch if ALU zero_flag == 1 (RS1 == RS2)
// bne             — enable branch if ALU zero_flag == 0 (RS1 != RS2)
//
// mem_read        — enable DataMemory read output (combinational gate)
// mem_write       — enable DataMemory write on posedge clk
//
// alu_src         — ALU B operand mux:
//                   0 = register RS2 value
//                   1 = sign-extended immediate (for LD/ST)
//
// reg_dst         — write-back register address mux:
//                   0 = instr[8:6] (I-type WS field, used for LD)
//                   1 = instr[5:3] (R-type WS field)
//
// mem_to_reg      — write-back data mux:
//                   0 = ALU result (R-type)
//                   1 = DataMemory read data (LD)
//
// reg_write       — enable GPR write on posedge clk
//
// check_ctrl() checks ALL 10 signals at once. If any mismatch, it prints
// which signal failed and what values were expected vs received.
//
// Run from tb/:
//   iverilog -Wall -I ../src -o ../build/cu_sim ../src/ControlUnit.v ControlUnit_tb.v
//   ../build/cu_sim
//   gtkwave ../waves/cu_tb.vcd &
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module ControlUnit_tb;

    reg  [3:0] opcode;

    wire [1:0] alu_op;
    wire       jump;
    wire       beq;
    wire       bne;
    wire       mem_read;
    wire       mem_write;
    wire       alu_src;
    wire       reg_dst;
    wire       mem_to_reg;
    wire       reg_write;
    wire       interrupt_reset;

    ControlUnit uut (
        .opcode          (opcode),
        .alu_op          (alu_op),
        .jump            (jump),
        .beq             (beq),
        .bne             (bne),
        .mem_read        (mem_read),
        .mem_write       (mem_write),
        .alu_src         (alu_src),
        .reg_dst         (reg_dst),
        .mem_to_reg      (mem_to_reg),
        .reg_write       (reg_write),
        .interrupt_reset (interrupt_reset)
    );

    initial begin
        $dumpfile("../waves/cu_tb.vcd");
        $dumpvars(0, ControlUnit_tb);
    end

    integer fail_count;
    integer test_id;

    // -------------------------------------------------------------------------
    // check_ctrl: verify all 10 signals simultaneously.
    // Parameter order: alu_op, jump, beq, bne, mem_read, mem_write,
    //                  alu_src, reg_dst, mem_to_reg, reg_write, test_id
    // -------------------------------------------------------------------------
    task check_ctrl;
        input [1:0] e_alu_op;
        input       e_jump, e_beq, e_bne;
        input       e_mem_read, e_mem_write;
        input       e_alu_src, e_reg_dst;
        input       e_mem_to_reg, e_reg_write;
        input       e_interrupt_reset;
        input [63:0] id;

        reg failed;
        begin
            failed = 1'b0;

            if (alu_op !== e_alu_op) begin
                $display("  MISMATCH alu_op:          got %b exp %b", alu_op, e_alu_op);
                failed = 1;
            end
            if (jump !== e_jump) begin
                $display("  MISMATCH jump:            got %b exp %b", jump, e_jump);
                failed = 1;
            end
            if (beq !== e_beq) begin
                $display("  MISMATCH beq:             got %b exp %b", beq, e_beq);
                failed = 1;
            end
            if (bne !== e_bne) begin
                $display("  MISMATCH bne:             got %b exp %b", bne, e_bne);
                failed = 1;
            end
            if (mem_read !== e_mem_read) begin
                $display("  MISMATCH mem_read:        got %b exp %b", mem_read, e_mem_read);
                failed = 1;
            end
            if (mem_write !== e_mem_write) begin
                $display("  MISMATCH mem_write:       got %b exp %b", mem_write, e_mem_write);
                failed = 1;
            end
            if (alu_src !== e_alu_src) begin
                $display("  MISMATCH alu_src:         got %b exp %b", alu_src, e_alu_src);
                failed = 1;
            end
            if (reg_dst !== e_reg_dst) begin
                $display("  MISMATCH reg_dst:         got %b exp %b", reg_dst, e_reg_dst);
                failed = 1;
            end
            if (mem_to_reg !== e_mem_to_reg) begin
                $display("  MISMATCH mem_to_reg:      got %b exp %b", mem_to_reg, e_mem_to_reg);
                failed = 1;
            end
            if (reg_write !== e_reg_write) begin
                $display("  MISMATCH reg_write:       got %b exp %b", reg_write, e_reg_write);
                failed = 1;
            end
            if (interrupt_reset !== e_interrupt_reset) begin
                $display("  MISMATCH interrupt_reset: got %b exp %b", interrupt_reset, e_interrupt_reset);
                failed = 1;
            end

            if (failed) begin
                $display("FAIL [T%0d]: opcode=%b", id, opcode);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d]: opcode=%b all signals correct", id, opcode);
        end
    endtask

    initial begin
        fail_count = 0;
        test_id    = 1;
        $display("=== ControlUnit Testbench ===");
        $display("    columns: alu_op jump beq bne mem_read mem_write alu_src reg_dst mem_to_reg reg_write");

        // -----------------------------------------------------------------
        // LD (0000): load word from memory into a register
        //   alu_src=1   -> ALU adds RS1 + sign_ext_imm (address calc)
        //   alu_op=10   -> ALU_Control selects ADD
        //   mem_read=1  -> DataMemory output is enabled
        //   mem_to_reg=1-> write-back data comes from memory, not ALU
        //   reg_write=1 -> result written to register file
        //   reg_dst=0   -> WS = instr[8:6] (I-type format)
        // -----------------------------------------------------------------
        $display("--- LD (0000) ---");
        opcode = 4'b0000; #10;
        //        alu_op  jump  beq   bne   mr    mw    as    rd    mtr   rw    ireset
        check_ctrl(2'b10, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0, test_id);
        test_id = test_id + 1;

        // -----------------------------------------------------------------
        // ST (0001): store a register value to memory
        //   alu_src=1   -> ALU adds RS1 + sign_ext_imm (address calc)
        //   alu_op=10   -> ADD
        //   mem_write=1 -> DataMemory writes RS2 on posedge clk
        //   reg_write=0 -> nothing written to register file
        //   mem_read=0  -> read output stays at 0 (no read needed)
        // -----------------------------------------------------------------
        $display("--- ST (0001) ---");
        opcode = 4'b0001; #10;
        check_ctrl(2'b10, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
        test_id = test_id + 1;

        // -----------------------------------------------------------------
        // R-type (0010–1001): ADD, SUB, INV, SHL, SHR, AND, OR, SLT
        //   reg_dst=1   -> WS = instr[5:3] (R-type format)
        //   alu_src=0   -> ALU B operand = register RS2 (not immediate)
        //   alu_op=00   -> ALU_Control decodes from opcode
        //   reg_write=1 -> result written back to register file
        //   mem_*=0     -> no memory access at all
        // -----------------------------------------------------------------
        $display("--- R-type: ADD (0010) ---");
        opcode = 4'b0010; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, test_id);
        test_id = test_id + 1;

        $display("--- R-type: SUB (0011) ---");
        opcode = 4'b0011; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, test_id);
        test_id = test_id + 1;

        $display("--- R-type: INV (0100) ---");
        opcode = 4'b0100; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, test_id);
        test_id = test_id + 1;

        $display("--- R-type: SHL (0101) ---");
        opcode = 4'b0101; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, test_id);
        test_id = test_id + 1;

        $display("--- R-type: SHR (0110) ---");
        opcode = 4'b0110; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, test_id);
        test_id = test_id + 1;

        $display("--- R-type: AND (0111) ---");
        opcode = 4'b0111; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, test_id);
        test_id = test_id + 1;

        $display("--- R-type: OR (1000) ---");
        opcode = 4'b1000; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, test_id);
        test_id = test_id + 1;

        $display("--- R-type: SLT (1001) ---");
        opcode = 4'b1001; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, test_id);
        test_id = test_id + 1;

        // -----------------------------------------------------------------
        // RETI (1010): return from interrupt
        //   interrupt_reset=1 -> PCL restores epc; ISM clears active state
        //   All other signals 0: no register write, no memory, no branch/jump.
        // -----------------------------------------------------------------
        $display("--- RETI (1010) ---");
        opcode = 4'b1010; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, test_id);
        test_id = test_id + 1;

        // -----------------------------------------------------------------
        // BEQ (1011): branch if RS1 == RS2
        //   alu_op=01   -> ALU_Control uses SUB so ALU computes RS1-RS2
        //   beq=1       -> PC mux: if zero_flag==1, PC = PC+2 + offset<<1
        //   Everything else 0 (no register or memory side-effects)
        // -----------------------------------------------------------------
        $display("--- BEQ (1011) ---");
        opcode = 4'b1011; #10;
        check_ctrl(2'b01, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
        test_id = test_id + 1;

        // -----------------------------------------------------------------
        // BNE (1100): branch if RS1 != RS2
        //   Same as BEQ but bne=1 instead of beq=1.
        //   PC mux: if zero_flag==0, PC = PC+2 + offset<<1
        // -----------------------------------------------------------------
        $display("--- BNE (1100) ---");
        opcode = 4'b1100; #10;
        check_ctrl(2'b01, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
        test_id = test_id + 1;

        // -----------------------------------------------------------------
        // JMP (1101): unconditional jump
        //   jump=1      -> PC = {PC[15:13], instr[11:0], 1'b0}
        //   alu_op=00, all others 0 (no computation or memory needed)
        // -----------------------------------------------------------------
        $display("--- JMP (1101) ---");
        opcode = 4'b1101; #10;
        check_ctrl(2'b00, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
        test_id = test_id + 1;

        // -----------------------------------------------------------------
        // Undefined opcodes (1110, 1111): default case in the case statement
        //   All outputs stay at their safe defaults (all 0).
        // -----------------------------------------------------------------
        $display("--- Undefined (1110) ---");
        opcode = 4'b1110; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
        test_id = test_id + 1;

        $display("--- Undefined (1111) ---");
        opcode = 4'b1111; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
        test_id = test_id + 1;

        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);
        $finish;
    end

endmodule