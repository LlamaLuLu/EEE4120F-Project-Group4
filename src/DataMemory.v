// =========================================================================
// StarCore-1+ — Data Memory with Memory-Mapped I/O
// =========================================================================
//
// File        : DataMemory.v
// Owner       : Pontsho Mbizo, MBZPON001
// Description : 32-word × 16-bit data RAM with address-decoded memory-mapped
//               I/O.  Word addresses 4–7 are shadowed by I/O registers; the
//               RAM array entries at those indices are physically unused.
//
// Bus interface
// -------------
//   addr[4:0] selects one of 32 word slots.  All accesses are 16-bit aligned
//   (word addressing).  The upper address bits are ignored.
//
// I/O address map  (word address)
// --------------------------------
//   4  INT_FLAG  R, write-1-to-clear  (storage in Beta's ISM)
//   5  INT_EN    R/W                  (storage in Beta's ISM)
//   6  GPIO_IN   R only; writes silently dropped
//   7  GPIO_OUT  R/W                  (storage in Alpha's GPIO.v)
//   All other addresses → RAM
//
// Write-enable outputs are *combinational* (asserted while mem_wr is high).
// The RAM write is synchronous (registered on posedge clk).
// Read output is combinational and gated by mem_rd.
// =============================================================================

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
    output wire [`WORD_WIDTH-1:0] gpio_out_din,     // = write_data (GPIO gates on gpio_out_we)
    input  wire [`WORD_WIDTH-1:0] gpio_in_data,     // combinational mirror of io_in_pins
    input  wire [`WORD_WIDTH-1:0] gpio_out_data,    // read-back of GPIO_OUT register

    // ----- Interrupt bus (to/from Beta's InterruptStateMachine) -----
    output wire        int_en_we,                   // pulse: Beta latches write_data → INT_EN
    output wire        int_flag_clr,                // pulse: Beta applies write-1-to-clear
    output wire [`WORD_WIDTH-1:0] int_bus_din,      // = write_data (Beta gates on *_we / *_clr)
    input  wire [`WORD_WIDTH-1:0] int_en_data,      // current INT_EN value from Beta
    input  wire [`WORD_WIDTH-1:0] int_flag_data     // current INT_FLAG value from Beta
);

    // -------------------------------------------------------------------------
    // RAM array — 32 words; words 4–7 are shadowed by I/O and never written.
    // -------------------------------------------------------------------------
    reg [`WORD_WIDTH-1:0] ram [`DMEM_DEPTH-1:0];

    initial begin
        $readmemb("../test/test.data", ram, 0, `DMEM_DEPTH-1);
    end

    // -------------------------------------------------------------------------
    // Address decode — use lower DMEM_ADDR_BITS of the 16-bit bus address.
    // -------------------------------------------------------------------------
    wire [`DMEM_ADDR_BITS-1:0] word_addr = addr[`DMEM_ADDR_BITS-1:0];

    wire is_int_flag = (word_addr == `INT_FLAG_ADDR);
    wire is_int_en   = (word_addr == `INT_EN_ADDR);
    wire is_gpio_in  = (word_addr == `GPIO_IN_ADDR);
    wire is_gpio_out = (word_addr == `GPIO_OUT_ADDR);
    wire is_io       = is_int_flag | is_int_en | is_gpio_in | is_gpio_out;
    wire is_ram      = ~is_io;

    // -------------------------------------------------------------------------
    // Write path
    //   RAM write: synchronous, skips I/O shadow addresses.
    //   I/O write-enables: combinational, asserted while mem_wr is high.
    //   gpio_out_din / int_bus_din are just write_data — downstream modules
    //   gate on their own write-enable.
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (mem_wr & is_ram)
            ram[word_addr] <= write_data;
    end

    assign gpio_out_we  = mem_wr & is_gpio_out;
    assign int_en_we    = mem_wr & is_int_en;
    assign int_flag_clr = mem_wr & is_int_flag;
    assign gpio_out_din = write_data;
    assign int_bus_din  = write_data;

    // -------------------------------------------------------------------------
    // Read path — combinational mux, gated by mem_rd.
    // -------------------------------------------------------------------------
    wire [`WORD_WIDTH-1:0] read_mux =
        is_int_flag ? int_flag_data  :
        is_int_en   ? int_en_data    :
        is_gpio_in  ? gpio_in_data   :
        is_gpio_out ? gpio_out_data  :
                      ram[word_addr];

    assign read_data = mem_rd ? read_mux : {`WORD_WIDTH{1'b0}};

endmodule
