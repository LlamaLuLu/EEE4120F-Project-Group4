// =============================================================================
// EEE4120F Practical 4 — StarCore-1 Processor
// File        : InstructionMemory_tb.v
// Description : Testbench for the Instruction Memory module (Task 3).
//               Walks the PC through all valid addresses and verifies the
//               correct instruction word is output combinationally.
//
// Run:
//   iverilog -Wall -I ../src -o ../build/im_sim ../src/InstructionMemory.v InstructionMemory_tb.v
//   cd ../test && ../build/im_sim
//   gtkwave ../waves/im_tb.vcd &
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module InstructionMemory_tb;

    reg  [15:0] pc;
    wire [15:0] instruction;

    InstructionMemory uut (.pc(pc), .instruction(instruction));

    initial begin
        $dumpfile("../waves/im_tb.vcd");
        $dumpvars(0, InstructionMemory_tb);
    end

    integer fail_count;
    integer test_id;
    // Expected instruction words — these must match the contents of test.prog.
    // Update these values after you finalise your test.prog file.
    reg [15:0] expected [0:14];

    initial begin
        fail_count = 0;
        test_id    = 1;

        $display("=== InstructionMemory Testbench ===");

        // TODO: Load the expected values to match your test.prog file.
        //       For example, if your first instruction is ADD R2,R0,R1 (0010000001010000):
        //           expected[0]  = 16'b0010000001010000;
        //       Fill in all 15 entries to match your test.prog exactly.
        //
        //       expected[0]  = 16'bXXXXXXXXXXXXXXXX;
        //       expected[1]  = 16'bXXXXXXXXXXXXXXXX;
        //       ... (fill all 15)

        expected[0]  = 16'b1101000000011101;
        expected[1]  = 16'b0000000100001111;
        expected[2]  = 16'b0001000000001110;
        expected[3]  = 16'b0001000101000011;
        expected[4]  = 16'b0010100000101000;
        expected[5]  = 16'b0010001000110000;
        expected[6]  = 16'b0111101001111000;
        expected[7]  = 16'b1011111000000001;
        expected[8]  = 16'b0100110000110000;
        expected[9]  = 16'b0110101001101000;
        expected[10] = 16'b0111101001111000;
        expected[11] = 16'b1011111000000001;
        expected[12] = 16'b0100110000110000;
        expected[13] = 16'b0110010001010000;
        expected[14] = 16'b1100010000111010;


        // TODO: Walk PC through addresses 0, 2, 4, ... 28 (14 instructions).
        //       At each address, verify instruction == expected[rom_index].
        //       Verify also that the output is combinational (no clock needed).
        //
        //       For each address:
        //           pc = 16'd0; #5;  // set PC, wait for combinational output
        //           if (instruction !== expected[0])
        //               $display("FAIL [T%0d]: PC=0 got %b exp %b",
        //                        test_id, instruction, expected[0]);
        //           else
        //               $display("PASS [T%0d]: PC=0 instr=%b", test_id, instruction);
        //           test_id = test_id + 1;
        //
        //           pc = 16'd2; #5;
        //           ... and so on.

        pc = 16'd0;  #5;
        if (instruction !== expected[0]) begin
            $display("FAIL [T%0d]: PC=0  got %b exp %b", test_id, instruction, expected[0]);
            fail_count = fail_count + 1;
        end else
            $display("PASS [T%0d]: PC=0  instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd2;  #5;
        if (instruction !== expected[1]) begin
            $display("FAIL [T%0d]: PC=2  got %b exp %b", test_id, instruction, expected[1]);
            fail_count = fail_count + 1;
        end else
            $display("PASS [T%0d]: PC=2  instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd4;  #5;
        if (instruction !== expected[2]) begin
            $display("FAIL [T%0d]: PC=4  got %b exp %b", test_id, instruction, expected[2]);
            fail_count = fail_count + 1;
        end else
            $display("PASS [T%0d]: PC=4  instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd6;  #5;
        if (instruction !== expected[3]) begin
            $display("FAIL [T%0d]: PC=6  got %b exp %b", test_id, instruction, expected[3]);
            fail_count = fail_count + 1;
        end else
            $display("PASS [T%0d]: PC=6  instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd8;  #5;
        if (instruction !== expected[4]) begin
            $display("FAIL [T%0d]: PC=8  got %b exp %b", test_id, instruction, expected[4]);
            fail_count = fail_count + 1;
        end else
            $display("PASS [T%0d]: PC=8  instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd10; #5;
        if (instruction !== expected[5]) begin
            $display("FAIL [T%0d]: PC=10 got %b exp %b", test_id, instruction, expected[5]);
            fail_count = fail_count + 1;
        end else
            $display("PASS [T%0d]: PC=10 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd12; #5;
        if (instruction !== expected[6]) begin
            $display("FAIL [T%0d]: PC=12 got %b exp %b", test_id, instruction, expected[6]);
            fail_count = fail_count + 1;
        end else
            $display("PASS [T%0d]: PC=12 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd14; #5;
        if (instruction !== expected[7]) begin
            $display("FAIL [T%0d]: PC=14 got %b exp %b", test_id, instruction, expected[7]);
            fail_count = fail_count + 1;
        end else
            $display("PASS [T%0d]: PC=14 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd16; #5;
        if (instruction !== expected[8]) begin
            $display("FAIL [T%0d]: PC=16 got %b exp %b", test_id, instruction, expected[8]);
            fail_count = fail_count + 1;
        end else
            $display("PASS [T%0d]: PC=16 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd18; #5;
        if (instruction !== expected[9]) begin
            $display("FAIL [T%0d]: PC=18 got %b exp %b", test_id, instruction, expected[9]);
            fail_count = fail_count + 1;
        end else
            $display("PASS [T%0d]: PC=18 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd20; #5;
        if (instruction !== expected[10]) begin
            $display("FAIL [T%0d]: PC=20 got %b exp %b", test_id, instruction, expected[10]);
            fail_count = fail_count + 1;
        end else
            $display("PASS [T%0d]: PC=20 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd22; #5;
        if (instruction !== expected[11]) begin
            $display("FAIL [T%0d]: PC=22 got %b exp %b", test_id, instruction, expected[11]);
            fail_count = fail_count + 1;
        end else
            $display("PASS [T%0d]: PC=22 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd24; #5;
        if (instruction !== expected[12]) begin
            $display("FAIL [T%0d]: PC=24 got %b exp %b", test_id, instruction, expected[12]);
            fail_count = fail_count + 1;
        end else
            $display("PASS [T%0d]: PC=24 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd26; #5;
        if (instruction !== expected[13]) begin
            $display("FAIL [T%0d]: PC=26 got %b exp %b", test_id, instruction, expected[13]);
            fail_count = fail_count + 1;
        end else
            $display("PASS [T%0d]: PC=26 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd28; #5;
        if (instruction !== expected[14]) begin
            $display("FAIL [T%0d]: PC=28 got %b exp %b", test_id, instruction, expected[14]);
            fail_count = fail_count + 1;
        end else
            $display("PASS [T%0d]: PC=28 instr=%b", test_id, instruction);
        test_id = test_id + 1;


        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);
        $finish;
    end

endmodule
