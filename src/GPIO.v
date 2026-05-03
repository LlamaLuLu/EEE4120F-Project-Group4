// =========================================================================
// StarCore-1+ — GPIO Module
// =========================================================================
//
// File        : GPIO.v
// Owner       : Pontsho Mbizo, MBZPON001
// Description : Two memory-mapped registers exposed through DataMemory:
//                 GPIO_OUT (word 7) — writable output register
//                 GPIO_IN  (word 6) — combinational mirror of io_in_pins
//               Also taps io_in_pins[0] as the raw IRQ source for Beta's
//               InterruptStateMachine
//
// Interface with DataMemory
// -------------------------
//   DataMemory asserts gpio_out_we for exactly one clock cycle when software
//   executes ST to GPIO_OUT_ADDR.  gpio_out_din carries write_data.
//   gpio_in_data and gpio_out_data feed the DataMemory read mux directly.
//
// Note to self: change io_in_pins on negedge clk in testbenches to avoid read-cycle
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module GPIO (
    input  wire        clk,
    input  wire        rst,

    // ----- From DataMemory (write path) -----
    input  wire        gpio_out_we,
    input  wire [`WORD_WIDTH-1:0] gpio_out_din,

    // ----- Physical pins -----
    input  wire [`WORD_WIDTH-1:0] io_in_pins,   // driven by external testbench
    output wire [`WORD_WIDTH-1:0] io_out_pins,  // drives external pins

    // ----- To DataMemory read mux -----
    output wire [`WORD_WIDTH-1:0] gpio_in_data,   // combinational mirror of io_in_pins
    output wire [`WORD_WIDTH-1:0] gpio_out_data,  // read-back of GPIO_OUT register

    // ----- To InterruptStateMachine -----
    output wire        irq_pin                    // raw (unsynchronized) IRQ source
);

    reg [`WORD_WIDTH-1:0] gpio_out_r;

    always @(posedge clk) begin
        if (rst)
            gpio_out_r <= {`WORD_WIDTH{1'b0}};
        else if (gpio_out_we)
            gpio_out_r <= gpio_out_din;
    end

    assign io_out_pins   = gpio_out_r;
    assign gpio_out_data = gpio_out_r;
    assign gpio_in_data  = io_in_pins;
    assign irq_pin       = io_in_pins[0];

endmodule
