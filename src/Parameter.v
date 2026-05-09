// =========================================================================
// Practical 4: StarCore-2 — Single-Cycle Processor in Verilog
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
//   DMEM_DEPTH     — total word slots (0–12 read-only RAM, 13–15 I/O)
//   DMEM_ADDR_BITS — address bits needed to index DMEM_DEPTH words
//   ROW_D — updated from BCE value of 8
// ---------------------------------------------------------------------------
`define DMEM_DEPTH      16
`define DMEM_ADDR_BITS   4          // ceil(log2(16))
`define ROW_D            8          // BCE alias — kept for backward compat

// ---------------------------------------------------------------------------
//   Memory-mapped I/O word addresses (13–15)
//   13: reserved
//   14: GPIO_OUT  R/W
//   15: GPIO_IN   R only
// ---------------------------------------------------------------------------
`define GPIO_OUT_ADDR   4'd14       // R/W                   (GPIO.v)
`define GPIO_IN_ADDR    4'd15       // R only

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
