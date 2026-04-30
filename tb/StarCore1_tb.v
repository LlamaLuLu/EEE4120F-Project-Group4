// =============================================================================
// EEE4120F Practical 4 — StarCore-1 Processor
// File        : StarCore1_tb.v
// Description : Integration testbench for the full StarCore-1 processor.
//
// HOW THIS TESTBENCH WORKS
// ------------------------
// This testbench is different from all others. It does NOT drive the
// datapath signals directly. It only:
//   1. Drives the clock
//   2. Observes internal signals using HIERARCHICAL REFERENCES
//   3. After SIM_TIME, checks final state against expected values
//
// HIERARCHICAL REFERENCES
// -----------------------
// Verilog lets you reach inside any instantiated module using dot notation:
//   uut          -> StarCore1 instance
//   uut.DU       -> Datapath instance inside StarCore1
//   uut.CU       -> ControlUnit instance inside StarCore1
//   uut.DU.reg_file         -> GPR instance inside Datapath
//   uut.DU.dm               -> DataMemory instance inside Datapath
//   uut.DU.pc_current       -> PC register (reg) inside Datapath
//   uut.DU.instr            -> fetched instruction (wire) inside Datapath
//   uut.DU.alu_result       -> ALU output (wire) inside Datapath
//   uut.DU.zero_flag        -> ALU zero flag (wire) inside Datapath
//   uut.DU.reg_file.reg_array[N]  -> register RN value inside GPR
//   uut.DU.dm.memory[N]           -> data memory word N inside DataMemory
//
// The instance names (DU, CU, reg_file, dm) MUST match the names used in
// StarCore1.v and Datapath.v. If they don't match, iverilog gives an
// "Unable to bind" error at compile time.
//
// THE TEST PROGRAM (test/test.prog)
// ----------------------------------
// [0]  LD  R0, 0(R2)   -> R0 = Mem[R2+0] = Mem[0] = 0x0001
// [1]  LD  R1, 1(R2)   -> R1 = Mem[R2+1] = Mem[1] = 0x0002
// [2]  ADD R2, R0, R1  -> R2 = 0x0001 + 0x0002 = 0x0003
// [3]  ST  R2, 0(R1)   -> Mem[R1+0] = Mem[2] = 0x0003
// [4]  SUB R2, R0, R1  -> R2 = 0x0001 - 0x0002 = 0xFFFF (unsigned wrap)
// [5]  AND R2, R0, R1  -> R2 = 0x0001 & 0x0002 = 0x0000
// [6]  OR  R2, R0, R1  -> R2 = 0x0001 | 0x0002 = 0x0003
// [7]  SLT R2, R0, R1  -> R2 = (1 < 2) ? 1 : 0 = 0x0001
// [8]  ADD R0, R0, R0  -> R0 = 0x0001 + 0x0001 = 0x0002
// [9]  BEQ R0, R1, +1  -> R0==R1 (both 2), branch TAKEN; skip to JMP
// [10] BNE R0, R1, +0  -> skipped (BEQ jumped over it)
// [11] JMP 0            -> PC = 0x0000 (loops back to start)
//
// The program loops forever via JMP. After 40 cycles (400 ns SIM_TIME),
// the processor is mid-loop. Final state:
//   R0 = 0x0002, R1 = 0x0003, R2 = 0xFFFF
//   Mem[2] = 0x0003 (written on first pass)
//   Mem[3] = 0x0005 (written on second pass: R1=3, R2=R0+R1=2+3=5)
//
// CYCLE-BY-CYCLE TRACE
// --------------------
// The always @(posedge clk) block fires on every rising edge and prints
// a one-line snapshot of processor state. This is your primary debugging
// tool — you can trace exactly which instruction is executing and what
// the register file and ALU look like at each cycle.
//
// The trace shows state AFTER the clock edge (the new values written this
// cycle), because the hierarchical read of reg_file.reg_array[] returns
// the value the flip-flops hold AFTER the non-blocking assignment commits.
//
// Run from tb/:
//   iverilog -Wall -I ../src -o ../build/star_sim \
//       ../src/Parameter.v ../src/ALU.v ../src/GPR.v \
//       ../src/InstructionMemory.v ../src/DataMemory.v \
//       ../src/ALU_Control.v ../src/ControlUnit.v \
//       ../src/Datapath.v ../src/StarCore1.v StarCore1_tb.v
//   ../build/star_sim
//   gtkwave ../waves/star.vcd &
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module StarCore1_tb;

    // -------------------------------------------------------------------------
    // Clock: 10 ns period = 100 MHz
    // -------------------------------------------------------------------------
    reg clk;
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // DUT: the complete StarCore-1 processor.
    // Only the clock is driven from outside — everything else is internal.
    // -------------------------------------------------------------------------
    StarCore1 uut (.clk(clk));

    // -------------------------------------------------------------------------
    // Waveform dump: $dumpvars(0, ...) captures the entire design hierarchy.
    // Open waves/star.vcd in GTKWave to see all signals visually.
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("../waves/star.vcd");
        $dumpvars(0, StarCore1_tb);
    end

    integer fail_count;
    integer test_id;

    initial begin
        fail_count = 0;
        test_id    = 1;
    end

    // -------------------------------------------------------------------------
    // check16: compare a 16-bit observed value against expected.
    // '!==' catches X (undefined) and Z (high-impedance) — use this, not '!='.
    // -------------------------------------------------------------------------
    task check16;
        input [15:0] got;
        input [15:0] expected;
        input [63:0] id;
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d]: got = 0x%h (%0d), expected = 0x%h (%0d)",
                         id, got, got, expected, expected);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d]: value = 0x%h (%0d)", id, got, got);
        end
    endtask

    // -------------------------------------------------------------------------
    // Cycle-by-cycle execution trace.
    // Fires on every posedge clk. Shows:
    //   - Current time in ns
    //   - PC value (byte address of instruction being executed this cycle)
    //   - The 16-bit instruction word being executed
    //   - R0, R1, R2 register values (AFTER this cycle's write-back)
    //   - ALU result computed this cycle
    //   - ALU zero flag (1 = result was zero; used for BEQ/BNE)
    //
    // NOTE: because GPR writes are synchronous (non-blocking <=), the
    // register values you see here reflect the result of THIS cycle's
    // instruction already committed. PC shown is the one that was fetched
    // this cycle (the instruction that just ran), not the next PC.
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        $display("%0t ns | PC=0x%h | instr=%b | R0=0x%h R1=0x%h R2=0x%h | alu=0x%h z=%b",
            $time,
            uut.DU.pc_current,
            uut.DU.instr,
            uut.DU.reg_file.reg_array[0],
            uut.DU.reg_file.reg_array[1],
            uut.DU.reg_file.reg_array[2],
            uut.DU.alu_result,
            uut.DU.zero_flag
        );
    end

    // =========================================================================
    // MAIN STIMULUS AND VERIFICATION
    // =========================================================================
    initial begin
        $display("=== StarCore-1 Integration Testbench ===");
        $display("=== Program: ../test/test.prog | Data: ../test/test.data ===");
        $display("");

        // Let the processor run for SIM_TIME (defined in Parameter.v = #400 = 40 cycles)
        `SIM_TIME;

        // -----------------------------------------------------------------------
        // POST-SIMULATION CHECKS
        //
        // Execution trace summary (first pass through the program):
        //
        // Cy 0  PC=0x0000  LD  R0,0(R2)  R2=0 so addr=0  R0 <- Mem[0] = 0x0001
        // Cy 1  PC=0x0002  LD  R1,1(R2)  R2=0 so addr=1  R1 <- Mem[1] = 0x0002
        // Cy 2  PC=0x0004  ADD R2,R0,R1  R2 <- 1+2 = 0x0003
        // Cy 3  PC=0x0006  ST  R2,0(R1)  addr=R1+0=2  Mem[2] <- 0x0003
        // Cy 4  PC=0x0008  SUB R2,R0,R1  R2 <- 1-2 = 0xFFFF (wraps)
        // Cy 5  PC=0x000A  AND R2,R0,R1  R2 <- 1&2 = 0x0000
        // Cy 6  PC=0x000C  OR  R2,R0,R1  R2 <- 1|2 = 0x0003
        // Cy 7  PC=0x000E  SLT R2,R0,R1  R2 <- (1<2)=0x0001
        // Cy 8  PC=0x0010  ADD R0,R0,R0  R0 <- 1+1 = 0x0002
        // Cy 9  PC=0x0012  BEQ R0,R1,+1  R0==R1 (both 2), z=1 -> TAKEN
        //                                PC jumps to 0x0016 (skips BNE)
        // Cy10  PC=0x0016  JMP 0          PC <- 0x0000
        //
        // Second pass (JMP brings PC back to 0):
        // Cy11  PC=0x0000  LD  R0,0(R2)  R2=0 -> R0 <- Mem[0] = 0x0001 (wait — R2 was 0x0001 after SLT)
        //                                Actually R2=0x0001 from Cy7, so addr = R2+0 = 1 -> R0 = Mem[1] = 0x0002
        // Cy12  PC=0x0002  LD  R1,1(R2)  addr = R2+1 = 2 -> R1 = Mem[2] = 0x0003  (Mem[2] was written as 0x0003 in Cy3)
        //
        // After 40 cycles, last completed instruction was SUB.
        // Final register state: R0=0x0002, R1=0x0003, R2=0xFFFF
        // Final memory state: Mem[2]=0x0003, Mem[3]=0x0005 (second-pass ST)
        // -----------------------------------------------------------------------

        $display("");
        $display("--- Register file checks ---");

        // R0: on the second-pass LD, R2=1 so addr=1, R0 gets Mem[1]=0x0002
        $display("R0 (expect 0x0002):");
        check16(uut.DU.reg_file.reg_array[0], 16'h0002, test_id);
        test_id = test_id + 1;

        // R1: on the second-pass LD, R2=1 so addr=R2+1=2, R1 gets Mem[2]=0x0003
        $display("R1 (expect 0x0003):");
        check16(uut.DU.reg_file.reg_array[1], 16'h0003, test_id);
        test_id = test_id + 1;

        // R2: last completed instruction at end of SIM_TIME was SUB R2,R0,R1
        //     R0=2, R1=3 -> R2 = 2-3 = 0xFFFF (16-bit unsigned wrap)
        $display("R2 (expect 0xFFFF — SUB 2-3 wraps):");
        check16(uut.DU.reg_file.reg_array[2], 16'hffff, test_id);
        test_id = test_id + 1;

        // R3-R7 were never the destination of any instruction
        $display("R3 (expect 0x0000 — never written):");
        check16(uut.DU.reg_file.reg_array[3], 16'h0000, test_id);
        test_id = test_id + 1;

        $display("");
        $display("--- Data memory checks ---");

        // Mem[0]: initialised to 0x0001, never overwritten by ST
        $display("Mem[0] (expect 0x0001 — init value):");
        check16(uut.DU.dm.memory[0], 16'h0001, test_id);
        test_id = test_id + 1;

        // Mem[2]: written by ST on first pass (R2=0x0003, addr=R1+0=2)
        $display("Mem[2] (expect 0x0003 — ST on first pass):");
        check16(uut.DU.dm.memory[2], 16'h0003, test_id);
        test_id = test_id + 1;

        // Mem[3]: written by ST on second pass (R1=3 so addr=3, R2=R0+R1=2+3=5)
        $display("Mem[3] (expect 0x0005 — ST on second pass):");
        check16(uut.DU.dm.memory[3], 16'h0005, test_id);
        test_id = test_id + 1;

        // Mem[7]: initialised to 0x0008, never touched by ST
        $display("Mem[7] (expect 0x0008 — init value):");
        check16(uut.DU.dm.memory[7], 16'h0008, test_id);
        test_id = test_id + 1;

        // -----------------------------------------------------------------------
        // Print full final state (useful for the report results table)
        // -----------------------------------------------------------------------
        $display("");
        $display("--- Final Register File State ---");
        $display("R0=0x%h  R1=0x%h  R2=0x%h  R3=0x%h",
            uut.DU.reg_file.reg_array[0], uut.DU.reg_file.reg_array[1],
            uut.DU.reg_file.reg_array[2], uut.DU.reg_file.reg_array[3]);
        $display("R4=0x%h  R5=0x%h  R6=0x%h  R7=0x%h",
            uut.DU.reg_file.reg_array[4], uut.DU.reg_file.reg_array[5],
            uut.DU.reg_file.reg_array[6], uut.DU.reg_file.reg_array[7]);

        $display("");
        $display("--- Final Data Memory State ---");
        $display("Mem[0]=0x%h  Mem[1]=0x%h  Mem[2]=0x%h  Mem[3]=0x%h",
            uut.DU.dm.memory[0], uut.DU.dm.memory[1],
            uut.DU.dm.memory[2], uut.DU.dm.memory[3]);
        $display("Mem[4]=0x%h  Mem[5]=0x%h  Mem[6]=0x%h  Mem[7]=0x%h",
            uut.DU.dm.memory[4], uut.DU.dm.memory[5],
            uut.DU.dm.memory[6], uut.DU.dm.memory[7]);

        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d INTEGRATION TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d INTEGRATION TESTS FAILED ===", fail_count, test_id - 1);

        $finish;
    end

endmodule