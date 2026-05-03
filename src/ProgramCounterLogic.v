// =========================================================================
// Project: Specialised StarCore-1 — Single-Cycle Processor in Verilog
// =========================================================================
//
// GROUP NUMBER: 4
//
// MEMBERS:
//   - Lulama Lingela, LNGLUL002
//   - Pontsho Mbizo, MBZPON001
//   - Neo Vorsatz, VRSNEO001

// File        : ProgramCounterLogic.v
// Description : Program Counter Logic with hardware interrupt support.
//               Manages the PC register and a dedicated exception PC (epc)
//               register used to save and restore the return address across
//               interrupt service routines.
//
//               Priority (highest first):
//                 1. RETI (interrupt_reset) — restore PC from epc
//                 2. Interrupt (request_interrupt) — save pc+2 to epc, jump to handler
//                 3. Jump (jump)
//                 4. Branch (beq_taken | bne_taken)
//                 5. Sequential (pc + 2)
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module ProgramCounterLogic (
    input        clk,

    // --- Interrupt signals ---------------------------------------------------
    input        request_interrupt, // From ISM: high for exactly one cycle when interrupt fires
    input        interrupt_reset,   // From ControlUnit: high when RETI (opcode 1010) executes

    // --- Normal PC control signals from ControlUnit -------------------------
    input        jump,              // Assert to select jump target
    input        beq,               // Assert to enable branch-on-equal
    input        bne,               // Assert to enable branch-on-not-equal
    input        zero_flag,         // From ALU: 1 when ALU result == 0

    // --- Instruction fields for address computation -------------------------
    input [11:0] instr_jump_field,  // instr[11:0]: 12-bit jump offset
    input [15:0] ext_im,            // Sign-extended 6-bit immediate (for branch offset)

    // --- Output -------------------------------------------------------------
    output reg [15:0] pc_current    // Current PC value — drives InstructionMemory
);

    // =========================================================================
    // EXCEPTION PC REGISTER
    // Saves the return address (pc+2) when an interrupt is accepted.
    // Restored to pc on RETI. Lives here, not in the GPR.
    // =========================================================================
    reg [15:0] epc;

    // =========================================================================
    // COMBINATIONAL ADDRESS COMPUTATIONS
    // All of these are wires — they update instantly whenever pc_current changes.
    // =========================================================================

    wire [15:0] pc2          = pc_current + 16'd2;

    // Branch target: pc2 + sign-extended offset shifted left by 1 (word-aligns it)
    wire [15:0] pc_branch    = pc2 + {ext_im[14:0], 1'b0};

    // Jump target: replace pc2[12:0] with {instr[11:0], 1'b0}, keep pc2[15:13]
    wire [12:0] jump_target  = {instr_jump_field, 1'b0};
    wire [15:0] pc_jump      = {pc2[15:13], jump_target};

    // Branch condition flags
    wire beq_taken = beq & zero_flag;
    wire bne_taken = bne & ~zero_flag;

    // =========================================================================
    // INITIALISATION
    // =========================================================================
    initial begin
        pc_current = 16'd0;
        epc        = 16'd0;
    end

    // =========================================================================
    // PC UPDATE — synchronous, priority-encoded
    //
    // interrupt_reset and request_interrupt are mutually exclusive in practice:
    //   - interrupt_reset fires only during RETI, which runs only while active_reg=1
    //   - request_interrupt is blocked while active_reg=1 (ISM guarantees this)
    // The if-else ordering still encodes a safe priority for completeness.
    // =========================================================================
    always @(posedge clk) begin
        if (interrupt_reset)
            // RETI: restore saved return address, re-enabling normal execution
            pc_current <= epc;

        else if (request_interrupt) begin
            // Interrupt accepted: save return address, jump to handler at word 1
            epc        <= pc2;           // pc+2 is where execution resumes after RETI
            pc_current <= 16'h0002;      // handler is at byte address 2 (word index 1)
        end

        else if (jump)
            pc_current <= pc_jump;

        else if (beq_taken | bne_taken)
            pc_current <= pc_branch;

        else
            pc_current <= pc2;
    end

endmodule
