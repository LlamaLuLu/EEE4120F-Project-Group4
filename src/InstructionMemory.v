// =========================================================================
// Practical 4: StarCore-1 — Single-Cycle Processor in Verilog
// =========================================================================
//
// GROUP NUMBER: 4
//
// MEMBERS:
//   - Lulama Lingela, LNGLUL002
//   - Pontsho Mbizo, MBZPON001

// File        : InstructionMemory.v
// Description : Instruction Memory (ROM).
//               IMEM_DEPTH words × 16 bits (64 words, 128-byte address space).
//               Contents loaded at simulation start from test/test.prog using
//               $readmemb. Purely combinational — instruction output updates
//               immediately when the PC changes. No clock input.
//
// Task 3 — Student Implementation Required
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module InstructionMemory (
    input  [15:0] pc,           // Program Counter (byte address)
    output [15:0] instruction   // Fetched 16-bit instruction word
);

    // 64-entry ROM array, one 16-bit word per instruction slot.
    reg [`COL-1:0] memory [`IMEM_DEPTH-1:0];

    // PC is a byte address; each instruction is 2 bytes wide, so the word
    // index is pc >> 1. Using pc[6:1] gives 6 bits, addressing all 64 words
    // (byte addresses 0x0000–0x007E). pc[0] is always 0 for aligned accesses.
    //   PC=0x0000 → rom_addr=0,  PC=0x0002 → rom_addr=1,  etc.
    wire [5:0] rom_addr = pc[6:1];

    // Load program from binary file at simulation start.
    // Each line of test.prog is one 16-bit instruction in binary.
    // Indices 0–35 cover the 36-word CubeSat demo program; slots 36–63
    // are left uninitialised (unreachable under normal execution).
    initial begin
        $readmemb("../test/test.prog", memory, 0, 35);
    end

    // Combinational read: output follows rom_addr with no clock delay.
    assign instruction = memory[rom_addr];

endmodule