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
- New `RETI` instruction (opcode *TBC (`1010`)) to return from the handler

## Key Design Decisions

| | Choice |
|---|---|
| Handler address | Hardcoded to `0x01` |
| RETI opcode | `1010` |
| EPC location | Inside `ProgramCounter.v`, not in R0–R7 |
| Nested interrupts | Not supported |
| Context save | Programmer's responsibility |
| Instruction memory | 32 words |
| Data memory | 16 words |

## Folder Structure

```
EEE4120F-Project-Group4/
├── src/
│   ├── ALU_Control.v
│   ├── ALU.v
│   ├── ControlUnit.v           # extended with RETI & interrupt stall
│   ├── DataMemory.v            # extended, and includes I/O
│   ├── Datapath.v              # modified to include new modules
│   ├── GPR.v
│   ├── InstructionMemory.v     # extended to have space for interrupt handler
│   ├── InterruptStateMachine.v # detects interrupts, and controls state
│   ├── Parameter.v
│   ├── ProgramCounterLogic.v   # controls Program Counter, and has EPC
│   └── StarCore1.v             # modified to include new control signals
├── tb/
│   ├── ...                     # one testbench per module, except Datapath
│   └── StarCore1_tb.v          # full integration testbench
├── assembly/
│   └── ...                     # assembly programs
├── test/
│   ├── test.prog
│   └── test.data
├── build/
└── waves/
```

## Assembler
The assembler takes the name of the desired program. This checks in `assembly/` for a directory with this name. The file `program.s` stores the assembly program, `interrupt.s` stores the interrupt handler, and `data_memory` stores the data that'll be loaded into the data memory.
```
...
├── assembly/
│   ├── triangular/
│   │   ├── data_memory     # initial data
│   │   ├── interrupt.s     # interrupt handler
│   │   └── program.s       # main program
│   └── ...                 # other programs
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
| MS3 | ~~15~~ 20 May | Final report |