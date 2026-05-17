// =============================================================================
// EEE4120F Practical 4 — StarCore-1 Processor
// File        : InstructionMemory_tb.v
// Description : Testbench for the Instruction Memory module (Task 3).
//               Walks the PC through all valid addresses and verifies the
//               correct instruction word is output combinationally.
//               Covers all 36 words in test.prog (PC = 0 to 70, step 2).
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
    // Expected instruction words — must match test.prog exactly (36 words).
    reg [15:0] expected [0:35];

    initial begin
        fail_count = 0;
        test_id    = 1;

        $display("=== InstructionMemory Testbench ===");

        // Words 0–14: main program preamble + ISR start
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
        // Words 15–24: ISR body continuation + first RETI
        expected[15] = 16'b0000000010000010;
        expected[16] = 16'b0111110001110000;
        expected[17] = 16'b1011110000000111;
        expected[18] = 16'b0000000101000011;
        expected[19] = 16'b0010001000110000;
        expected[20] = 16'b0110101010111000;
        expected[21] = 16'b1100111000000001;
        expected[22] = 16'b0011000001110000;
        expected[23] = 16'b0001000101001110;
        expected[24] = 16'b1010000000000000;  // RETI
        // Words 25–28: ISR alternate exit path + second RETI
        expected[25] = 16'b0111100010101000;
        expected[26] = 16'b0011011101101000;
        expected[27] = 16'b1101000000010011;
        expected[28] = 16'b1010000000000000;  // RETI
        // Words 29–35: main program body
        expected[29] = 16'b0000000001000001;
        expected[30] = 16'b0000000010000010;
        expected[31] = 16'b0000000011000000;
        expected[32] = 16'b1011000101111111;
        expected[33] = 16'b0010101110101000;
        expected[34] = 16'b0001000101001110;
        expected[35] = 16'b1101000000100000;

        // Walk PC through byte addresses 0, 2, 4, ... 70 (36 words total)
        pc = 16'd0;  #5;
        if (instruction !== expected[0]) begin
            $display("FAIL [T%0d]: PC=0  got %b exp %b", test_id, instruction, expected[0]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=0  instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd2;  #5;
        if (instruction !== expected[1]) begin
            $display("FAIL [T%0d]: PC=2  got %b exp %b", test_id, instruction, expected[1]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=2  instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd4;  #5;
        if (instruction !== expected[2]) begin
            $display("FAIL [T%0d]: PC=4  got %b exp %b", test_id, instruction, expected[2]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=4  instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd6;  #5;
        if (instruction !== expected[3]) begin
            $display("FAIL [T%0d]: PC=6  got %b exp %b", test_id, instruction, expected[3]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=6  instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd8;  #5;
        if (instruction !== expected[4]) begin
            $display("FAIL [T%0d]: PC=8  got %b exp %b", test_id, instruction, expected[4]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=8  instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd10; #5;
        if (instruction !== expected[5]) begin
            $display("FAIL [T%0d]: PC=10 got %b exp %b", test_id, instruction, expected[5]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=10 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd12; #5;
        if (instruction !== expected[6]) begin
            $display("FAIL [T%0d]: PC=12 got %b exp %b", test_id, instruction, expected[6]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=12 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd14; #5;
        if (instruction !== expected[7]) begin
            $display("FAIL [T%0d]: PC=14 got %b exp %b", test_id, instruction, expected[7]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=14 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd16; #5;
        if (instruction !== expected[8]) begin
            $display("FAIL [T%0d]: PC=16 got %b exp %b", test_id, instruction, expected[8]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=16 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd18; #5;
        if (instruction !== expected[9]) begin
            $display("FAIL [T%0d]: PC=18 got %b exp %b", test_id, instruction, expected[9]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=18 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd20; #5;
        if (instruction !== expected[10]) begin
            $display("FAIL [T%0d]: PC=20 got %b exp %b", test_id, instruction, expected[10]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=20 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd22; #5;
        if (instruction !== expected[11]) begin
            $display("FAIL [T%0d]: PC=22 got %b exp %b", test_id, instruction, expected[11]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=22 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd24; #5;
        if (instruction !== expected[12]) begin
            $display("FAIL [T%0d]: PC=24 got %b exp %b", test_id, instruction, expected[12]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=24 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd26; #5;
        if (instruction !== expected[13]) begin
            $display("FAIL [T%0d]: PC=26 got %b exp %b", test_id, instruction, expected[13]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=26 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd28; #5;
        if (instruction !== expected[14]) begin
            $display("FAIL [T%0d]: PC=28 got %b exp %b", test_id, instruction, expected[14]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=28 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd30; #5;
        if (instruction !== expected[15]) begin
            $display("FAIL [T%0d]: PC=30 got %b exp %b", test_id, instruction, expected[15]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=30 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd32; #5;
        if (instruction !== expected[16]) begin
            $display("FAIL [T%0d]: PC=32 got %b exp %b", test_id, instruction, expected[16]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=32 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd34; #5;
        if (instruction !== expected[17]) begin
            $display("FAIL [T%0d]: PC=34 got %b exp %b", test_id, instruction, expected[17]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=34 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd36; #5;
        if (instruction !== expected[18]) begin
            $display("FAIL [T%0d]: PC=36 got %b exp %b", test_id, instruction, expected[18]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=36 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd38; #5;
        if (instruction !== expected[19]) begin
            $display("FAIL [T%0d]: PC=38 got %b exp %b", test_id, instruction, expected[19]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=38 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd40; #5;
        if (instruction !== expected[20]) begin
            $display("FAIL [T%0d]: PC=40 got %b exp %b", test_id, instruction, expected[20]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=40 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd42; #5;
        if (instruction !== expected[21]) begin
            $display("FAIL [T%0d]: PC=42 got %b exp %b", test_id, instruction, expected[21]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=42 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd44; #5;
        if (instruction !== expected[22]) begin
            $display("FAIL [T%0d]: PC=44 got %b exp %b", test_id, instruction, expected[22]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=44 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd46; #5;
        if (instruction !== expected[23]) begin
            $display("FAIL [T%0d]: PC=46 got %b exp %b", test_id, instruction, expected[23]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=46 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd48; #5;
        if (instruction !== expected[24]) begin
            $display("FAIL [T%0d]: PC=48 got %b exp %b", test_id, instruction, expected[24]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=48 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd50; #5;
        if (instruction !== expected[25]) begin
            $display("FAIL [T%0d]: PC=50 got %b exp %b", test_id, instruction, expected[25]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=50 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd52; #5;
        if (instruction !== expected[26]) begin
            $display("FAIL [T%0d]: PC=52 got %b exp %b", test_id, instruction, expected[26]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=52 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd54; #5;
        if (instruction !== expected[27]) begin
            $display("FAIL [T%0d]: PC=54 got %b exp %b", test_id, instruction, expected[27]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=54 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd56; #5;
        if (instruction !== expected[28]) begin
            $display("FAIL [T%0d]: PC=56 got %b exp %b", test_id, instruction, expected[28]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=56 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd58; #5;
        if (instruction !== expected[29]) begin
            $display("FAIL [T%0d]: PC=58 got %b exp %b", test_id, instruction, expected[29]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=58 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd60; #5;
        if (instruction !== expected[30]) begin
            $display("FAIL [T%0d]: PC=60 got %b exp %b", test_id, instruction, expected[30]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=60 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd62; #5;
        if (instruction !== expected[31]) begin
            $display("FAIL [T%0d]: PC=62 got %b exp %b", test_id, instruction, expected[31]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=62 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd64; #5;
        if (instruction !== expected[32]) begin
            $display("FAIL [T%0d]: PC=64 got %b exp %b", test_id, instruction, expected[32]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=64 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd66; #5;
        if (instruction !== expected[33]) begin
            $display("FAIL [T%0d]: PC=66 got %b exp %b", test_id, instruction, expected[33]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=66 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd68; #5;
        if (instruction !== expected[34]) begin
            $display("FAIL [T%0d]: PC=68 got %b exp %b", test_id, instruction, expected[34]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=68 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        pc = 16'd70; #5;
        if (instruction !== expected[35]) begin
            $display("FAIL [T%0d]: PC=70 got %b exp %b", test_id, instruction, expected[35]);
            fail_count = fail_count + 1;
        end else $display("PASS [T%0d]: PC=70 instr=%b", test_id, instruction);
        test_id = test_id + 1;

        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);
        $finish;
    end

endmodule
