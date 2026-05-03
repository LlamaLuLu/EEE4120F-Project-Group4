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

// File        : InterruptStateMachine.v
// Description : State Machine storing the states.
//               Manages interrupt triggering.
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module InterruptStateMachine (
    input        clk,

    // --- Inputs --------------------------------------------------------------
    input       interrupt_pin,          // Pin connected to external input that triggers interrupts
    input       interrupt_reset,        // Used to reset the interrupt state to, active high
    input       interrupt_en,           // Enables the triggering of interrupts

    // --- Outputs -------------------------------------------------------------
    output      request_interrupt       // Disables other commands and forces a jump to 0x01
);
    // State machine
    reg start_reg; // Flag to start an interrupt
    reg active_reg; // Flag to say an interrupt is active
    initial begin
        start_reg = 1'b0;
        active_reg = 1'b0;
    end

    // Interrupt triggering
    always @(posedge interrupt_pin) begin
        if (interrupt_en && !active_reg)
            start_reg <= 1'b1;
    end

    // Clock triggered
    always @(posedge clk) begin

        // Resetting interrupt
        if (interrupt_reset) begin
            start_reg <= 1'b0;
            active_reg <= 1'b0;
        end

        // Starting interrupt
        else if (start_reg) begin
            start_reg <= 1'b0;
            active_reg <= 1'b1;
        end

    end

    // Outputs
    assign request_interrupt = start_reg;

endmodule