# EEE4120F HPES Project — StarCore-1 Interrupt Extension

**Course:** EEE4120F High Performance Embedded Systems | UCT 2026

## Group 4

| Name | Student No. | Tasks |
|---|---|---|
| Lulama Lingela | LNGLUL002 | Gamma — PC save & integration |
| Pontsho Mbizo | MBZPON001 | Alpha — Memory-mapped GPIO |
| Neo Vorsatz | VRSNEO001 | Beta — Control unit & RETI |

## Project Overview

Extends the StarCore-1 (Practical 4) with:
- Memory-mapped digital I/O (GPIO in/out)
- Single hardware interrupt triggered by a rising edge on an external pin
- PC save/restore via a dedicated `EPC` register
- New `RETI` instruction (opcode *TBC (`1111`)) to return from the handler

## Key Design Decisions

| | Choice |
|---|---|
| Handler address | Hardcoded to `0x01` |
| RETI opcode | `1111` |
| EPC location | Inside `InterruptController.v`, not in R0–R7 |
| Nested interrupts | Not supported |
| Context save | Programmer's responsibility |
| Instruction memory | 128 words |
| Data memory | 64 words |

## Folder Structure

```
HPES-Project/
├── src/
│   ├── Parameter.v
│   ├── ALU.v
│   ├── GPR.v
│   ├── InstructionMemory.v
│   ├── DataMemory.v
│   ├── ALU_Control.v
│   ├── ControlUnit.v          # extended with RETI + interrupt stall
│   ├── InterruptController.v  # edge detector, start/active FFs, EPC
│   ├── GPIO.v                 # memory-mapped I/O registers
│   ├── Datapath.v
│   └── StarCore1.v
├── tb/
│   ├── ...                    # one testbench per module
│   └── StarCore1_int_tb.v     # full integration testbench
├── test/
│   ├── test.prog
│   └── test.data
├── build/
└── waves/
```

## Running Simulations

```bash
# Install dependencies
sudo apt install iverilog gtkwave

# Run all testbenches
make all

# Run integration test only
make integration

# View waveforms
make waves
```

## Milestones

| | Due | Deliverable |
|---|---|---|
| MS1 | 4 May | Status report |
| MS2 | 12 May | Technical demo |
| MS3 | 15 May | Final report |