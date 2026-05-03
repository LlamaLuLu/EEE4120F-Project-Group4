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
//
// File        : Parameter.v
// Description : Shared compile-time parameters used across all modules.
//               Include this file at the top of every .v file:
//                   `include "../src/Parameter.v"
//
// =============================================================================

`ifndef PARAMETER_H_
`define PARAMETER_H_

// ---------------------------------------------------------------------------
// Shared data widths
// ---------------------------------------------------------------------------
`define WORD_WIDTH      16          // All data and instruction words width
`define COL             16          // All data and instruction words width
`define OPCODE_WIDTH     4
`define REG_ADDR_WIDTH   3

// ---------------------------------------------------------------------------
// Instruction memory
// ---------------------------------------------------------------------------
`define IMEM_DEPTH      64          // 64-word instruction space (128 bytes) new depth
`define ROW_I           16          // BCE depth

// ---------------------------------------------------------------------------
// [Alpha] Data memory
//   DMEM_DEPTH — total word slots including I/O mirror at words 4–7
//   DMEM_ADDR_BITS — address bits needed to index DMEM_DEPTH words
//   ROW_D — updated from BCE value of 8
// ---------------------------------------------------------------------------
`define DMEM_DEPTH      32
`define DMEM_ADDR_BITS   5          // ceil(log2(32))
`define ROW_D            8          // BCE alias — kept for backward compat

// ---------------------------------------------------------------------------
//   Memory-mapped I/O word addresses
// ---------------------------------------------------------------------------
`define INT_FLAG_ADDR   5'd4        // R, write-1-to-clear
`define INT_EN_ADDR     5'd5        // R/W
`define GPIO_IN_ADDR    5'd6        // R only
`define GPIO_OUT_ADDR   5'd7        // R/W                   (GPIO.v)

// ---------------------------------------------------------------------------
//   Interrupt handler vector
//   Byte address of ISR entry point in instruction memory.
//   PC Logic should load this on interrupt acknowledgement.
// ---------------------------------------------------------------------------
`define HANDLER_VEC     16'h0008    // word 4 of IMEM (byte address 8)

// ---------------------------------------------------------------------------
// Simulation control
// ---------------------------------------------------------------------------
`define SIM_TIME        #640        // Total simulation time for integration testbench
`define DMEM_LOG        "./waves/dmem_log.txt"

`endif  // PARAMETER_H_
