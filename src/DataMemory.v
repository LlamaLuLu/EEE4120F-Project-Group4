// =========================================================================
// StarCore-2 — Data Memory with Memory-Mapped I/O
// =========================================================================
//
// File        : DataMemory.v
// Owner       : Pontsho Mbizo, MBZPON001
// Description : 16-word × 16-bit read-only data RAM with address-decoded
//               memory-mapped I/O at the top of the address space.
//               Words 0–12 are pre-loaded RAM (read-only at runtime).
//               Words 13–15 are I/O registers; the RAM array entries at
//               those indices are physically unused.
//
// Bus interface
// -------------
//   addr[3:0] selects one of 16 word slots.  All accesses are 16-bit aligned
//   (word addressing).  Upper address bits are ignored.
//
// I/O address map  (word address)
// --------------------------------
//   13  reserved  reads return 0; writes silently dropped
//   14  GPIO_OUT  R/W
//   15  GPIO_IN   R only; writes silently dropped
//   All other addresses (0–12) are read-only RAM
//
// =========================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module DataMemory (
    input  wire        clk,
    input  wire        rst,             // unused in RAM logic; included for bus compat

    // ----- Bus from Datapath -----
    input  wire [`WORD_WIDTH-1:0] addr,
    input  wire [`WORD_WIDTH-1:0] write_data,
    input  wire        mem_rd,
    input  wire        mem_wr,
    output wire [`WORD_WIDTH-1:0] read_data,

    // ----- GPIO bus (to/from GPIO.v) -----
    output wire        gpio_out_we,                 // pulse: latch write_data into GPIO_OUT
    output wire [`WORD_WIDTH-1:0] gpio_out_din,     // write_data (GPIO gates on gpio_out_we)
    input  wire [`WORD_WIDTH-1:0] gpio_in_data,     // combinational mirror of io_in_pins
    input  wire [`WORD_WIDTH-1:0] gpio_out_data     // read-back of GPIO_OUT register
);

    // -------------------------------------------------------------------------
    // RAM array — 16 words, pre-loaded; words 13–15 shadowed by I/O.
    // RAM is read-only at runtime (no write path to ram[]).
    // -------------------------------------------------------------------------
    reg [`WORD_WIDTH-1:0] ram [`DMEM_DEPTH-1:0];

    initial begin
        $readmemb("../test/test.data", ram, 0, `DMEM_DEPTH-1);
    end

    // -------------------------------------------------------------------------
    // Address decode — use lower DMEM_ADDR_BITS of the 16-bit bus address.
    // -------------------------------------------------------------------------
    wire [`DMEM_ADDR_BITS-1:0] word_addr = addr[`DMEM_ADDR_BITS-1:0];

    wire is_gpio_out = (word_addr == `GPIO_OUT_ADDR);   // 14
    wire is_gpio_in  = (word_addr == `GPIO_IN_ADDR);    // 15
    wire is_io       = (word_addr >= 4'd13);

    // -------------------------------------------------------------------------
    // Write path
    //   RAM is read-only — no write path to ram[].
    //   Only GPIO_OUT accepts writes; GPIO_IN and reserved addr 13 drop writes.
    // -------------------------------------------------------------------------
    assign gpio_out_we  = mem_wr & is_gpio_out;
    assign gpio_out_din = write_data;

    // -------------------------------------------------------------------------
    // Read path — combinational mux, gated by mem_rd.
    // -------------------------------------------------------------------------
    wire [`WORD_WIDTH-1:0] read_mux =
        is_gpio_out ? gpio_out_data            :
        is_gpio_in  ? gpio_in_data             :
        is_io       ? {`WORD_WIDTH{1'b0}}      :   // addr 13: reserved
                      ram[word_addr];

    assign read_data = mem_rd ? read_mux : {`WORD_WIDTH{1'b0}};

endmodule
