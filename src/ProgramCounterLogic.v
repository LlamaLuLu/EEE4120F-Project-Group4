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
//                 2. Interrupt (request_interrupt) — save pc to epc, jump to handler
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
    // Saves pc_current when an interrupt is accepted, so that RETI
    // re-executes the interrupted instruction rather than skipping it.
    // Restored to pc_current on RETI. Lives here, not in the GPR file.
    // =========================================================================
    reg [15:0] epc;

    // =========================================================================
    // COMBINATIONAL ADDRESS COMPUTATIONS
    // All computed as wires so they update immediately when pc_current changes.
    // The clocked always block below selects among these every rising edge.
    // =========================================================================

    // Next sequential address — used as the base for branch/jump targets and
    // as the return address saved into epc on an interrupt.
    wire [15:0] pc2          = pc_current + 16'd2;

    // Branch target: pc2 + (ext_im << 1)
    // ext_im holds a word-count offset from the instruction immediate field.
    // Shifting left by 1 converts it to a byte offset (each instruction = 2 bytes).
    wire [15:0] pc_branch    = pc2 + {ext_im[14:0], 1'b0};

    // Jump target: {pc2[15:13], instr[11:0], 1'b0}
    // The 12-bit jump field is shifted left by 1 (byte-align), forming a 13-bit
    // offset. The upper 3 bits of pc2 are kept so the jump stays within the same
    // 8 KB segment — matching the MIPS-style J-type encoding used here.
    wire [12:0] jump_target  = {instr_jump_field, 1'b0};
    wire [15:0] pc_jump      = {pc2[15:13], jump_target};

    // Branch taken flags — combine the control signal with the ALU condition.
    // BEQ branches when the ALU subtracted RS1-RS2 and the result was zero (equal).
    // BNE branches when the result was non-zero (not equal).
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
    // PC UPDATE — clocked, priority-encoded
    //
    // Evaluated in strict priority order on every rising clock edge.
    //
    // Note: interrupt_reset and request_interrupt cannot be simultaneously
    // asserted in practice — RETI only executes while the ISM active_reg=1,
    // and request_interrupt is suppressed while active_reg=1. The if-else
    // ordering still enforces a defined priority as a safety measure.
    // =========================================================================
    always @(posedge clk) begin

        if (interrupt_reset)
            // RETI executing: pop the saved return address back into PC.
            pc_current <= epc;

        else if (request_interrupt) begin
            // Interrupt accepted: snapshot the current PC then vector to handler.
            // epc = pc_current so that RETI re-executes the instruction that was
            // interrupted, rather than skipping it.
            epc        <= pc_current;
            pc_current <= `HANDLER_VEC;
        end

        else if (jump)
            pc_current <= pc_jump;

        else if (beq_taken | bne_taken)
            pc_current <= pc_branch;

        else
            // Default: advance to next instruction
            pc_current <= pc2;

    end

endmodule
