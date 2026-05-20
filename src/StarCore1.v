// =========================================================================
// Practical 4: StarCore-1 — Single-Cycle Processor in Verilog
// =========================================================================
//
// GROUP NUMBER: 4
//
// MEMBERS:
//   - Lulama Lingela, LNGLUL002
//   - Pontsho Mbizo, MBZPON001
//   - Neo Vorsatz, VRSNEO001

// File        : StarCore1.v
// Description : Top-level StarCore-1 processor module.
//               Connects the Datapath and ControlUnit together.
//               The only external input is the clock signal; all internal
//               signals flow between the two sub-modules via wires.
//
// Task 8 — Student Implementation Required
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module StarCore1 (
    input        clk,                    // System clock
    input  [15:0] io_in_pins,           // Physical input pins (io_in_pins[0] = IRQ source)
    output [15:0] io_out_pins           // Physical output pins (driven by GPIO_OUT register)
);

    // =========================================================================
    // INTERNAL CONTROL WIRES
    // ControlUnit drives these from the decoded opcode; Datapath consumes them.
    // opcode flows the other way: Datapath fetches the instruction and exposes
    // the top 4 bits back to ControlUnit for decoding.
    // =========================================================================
    wire        jump;
    wire        beq;
    wire        bne;
    wire        mem_read;
    wire        mem_write;
    wire        alu_src;
    wire        reg_dst;
    wire        mem_to_reg;
    wire        reg_write;
    wire [1:0]  alu_op;
    wire [3:0]  opcode;

    // =========================================================================
    // INTERRUPT WIRES
    // request_interrupt: ISM asserts this for exactly one cycle when the IRQ
    //   fires. Connected to both PCL (to vector the PC) and ControlUnit (to
    //   suppress all control outputs so no register/memory side-effects occur
    //   on the cycle the interrupt is accepted).
    // interrupt_reset: ControlUnit asserts this when opcode 1010 (RETI) is
    //   fetched. Connected to both PCL (to restore PC from epc) and ISM (to
    //   clear active_reg so a new interrupt can be accepted).
    // irq_pin: raw IRQ source extracted from io_in_pins[0] by the GPIO module.
    // =========================================================================
    wire        request_interrupt;
    wire        interrupt_reset;
    wire        irq_pin;

    // =========================================================================
    // GPIO BUS WIRES
    // DataMemory decodes ST/LD to addresses 14-15 and drives these signals.
    // GPIO is instantiated here (not inside Datapath) so it sits at the same
    // level as ISM and ControlUnit — a clean peer rather than a buried sub-module.
    // =========================================================================
    wire        gpio_out_we;
    wire [15:0] gpio_out_din;
    wire [15:0] gpio_in_data;
    wire [15:0] gpio_out_data;


    // =========================================================================
    // DATAPATH INSTANTIATION
    // Receives all control signals from CU; exposes opcode back to CU.
    // GPIO bus ports are pass-throughs: DataMemory drives them internally
    // and they are routed up here to connect to the GPIO module.
    // =========================================================================
    Datapath DU (
        .clk               (clk),
        .jump              (jump),
        .beq               (beq),
        .bne               (bne),
        .mem_read          (mem_read),
        .mem_write         (mem_write),
        .alu_src           (alu_src),
        .reg_dst           (reg_dst),
        .mem_to_reg        (mem_to_reg),
        .reg_write         (reg_write),
        .alu_op            (alu_op),
        .opcode            (opcode),
        .request_interrupt (request_interrupt),
        .interrupt_reset   (interrupt_reset),
        .gpio_out_we       (gpio_out_we),
        .gpio_out_din      (gpio_out_din),
        .gpio_in_data      (gpio_in_data),
        .gpio_out_data     (gpio_out_data)
    );


    // =========================================================================
    // CONTROL UNIT INSTANTIATION
    // Decodes opcode each cycle and drives all Datapath control signals.
    // request_interrupt gates every output to safe defaults for the one cycle
    // the interrupt is being accepted, preventing spurious register/memory writes.
    // =========================================================================
    ControlUnit CU (
        .opcode              (opcode),
        .request_interrupt   (request_interrupt),
        .alu_op              (alu_op),
        .jump                (jump),
        .beq                 (beq),
        .bne                 (bne),
        .mem_read            (mem_read),
        .mem_write           (mem_write),
        .alu_src             (alu_src),
        .reg_dst             (reg_dst),
        .mem_to_reg          (mem_to_reg),
        .reg_write           (reg_write),
        .interrupt_reset     (interrupt_reset)
    );


    // =========================================================================
    // INTERRUPT STATE MACHINE INSTANTIATION
    // =========================================================================

    InterruptStateMachine ISM (
        .clk               (clk),
        .interrupt_pin     (irq_pin),
        .interrupt_reset   (interrupt_reset),
        .interrupt_en      (1'b1),           // always enabled until INT_EN register is implemented
        .request_interrupt (request_interrupt)
    );

    // =========================================================================
    // GPIO INSTANTIATION
    // =========================================================================

    GPIO gpio_inst (
        .clk          (clk),
        .rst          (1'b0),
        .gpio_out_we  (gpio_out_we),
        .gpio_out_din (gpio_out_din),
        .io_in_pins   (io_in_pins),
        .io_out_pins  (io_out_pins),
        .gpio_in_data (gpio_in_data),
        .gpio_out_data(gpio_out_data),
        .irq_pin      (irq_pin)
    );

endmodule
