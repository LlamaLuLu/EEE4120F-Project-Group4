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
    // These signals connect the ControlUnit outputs to the Datapath inputs,
    // and the Datapath opcode output back to the ControlUnit input.
    // =========================================================================

    // TODO: Declare all internal control wires here.
    //
    //       wire        jump;
    //       wire        beq;
    //       wire        bne;
    //       wire        mem_read;
    //       wire        mem_write;
    //       wire        alu_src;
    //       wire        reg_dst;
    //       wire        mem_to_reg;
    //       wire        reg_write;
    //       wire [1:0]  alu_op;
    //       wire [3:0]  opcode;

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

    // Interrupt wires
    wire        request_interrupt; // ISM → Datapath/PCL: interrupt pending for one cycle
    wire        interrupt_reset;   // ControlUnit → ISM + PCL: RETI is executing
    wire        irq_pin;           // GPIO → ISM: raw interrupt source (io_in_pins[0])

    // GPIO bus wires (between Datapath/DataMemory and GPIO module)
    wire        gpio_out_we;
    wire [15:0] gpio_out_din;
    wire [15:0] gpio_in_data;
    wire [15:0] gpio_out_data;


    // =========================================================================
    // DATAPATH INSTANTIATION
    // =========================================================================

    // TODO: Instantiate the Datapath module using named port connections.
    //       All control inputs come from the ControlUnit wires declared above.
    //       The opcode output goes to the ControlUnit input.
    //
    //       Datapath DU (
    //           .clk        (clk),
    //           .jump       (jump),
    //           .beq        (beq),
    //           .bne        (bne),
    //           .mem_read   (mem_read),
    //           .mem_write  (mem_write),
    //           .alu_src    (alu_src),
    //           .reg_dst    (reg_dst),
    //           .mem_to_reg (mem_to_reg),
    //           .reg_write  (reg_write),
    //           .alu_op     (alu_op),
    //           .opcode     (opcode)
    //       );

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
    // =========================================================================

    // TODO: Instantiate the ControlUnit module.
    //       Its single input is the opcode from the Datapath.
    //       Its outputs drive all the Datapath control inputs.
    //
    //       ControlUnit CU (
    //           .opcode     (opcode),
    //           .alu_op     (alu_op),
    //           .jump       (jump),
    //           .beq        (beq),
    //           .bne        (bne),
    //           .mem_read   (mem_read),
    //           .mem_write  (mem_write),
    //           .alu_src    (alu_src),
    //           .reg_dst    (reg_dst),
    //           .mem_to_reg (mem_to_reg),
    //           .reg_write  (reg_write)
    //       );

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
