// =============================================================================
// EEE4120F Project — Specialised StarCore-1 Processor
// File        : StarCore1_tb.v
// Description : Integration testbench for the full StarCore-1 processor
//               with hardware interrupt support.
//
// HOW THIS TESTBENCH WORKS
// ------------------------
// Drives only the clock and interrupt_pin. Observes internal state via
// hierarchical references. Verifies the interrupt handling path end-to-end:
//   interrupt_pin → ISM → request_interrupt → PCL → PC=0x0002 → RETI → epc
//
// HIERARCHICAL REFERENCES
// -----------------------
//   uut.DU            — Datapath instance
//   uut.CU            — ControlUnit instance
//   uut.ISM           — InterruptStateMachine instance
//   uut.DU.pcl        — ProgramCounterLogic instance inside Datapath
//   uut.DU.pcl.epc    — saved return address register inside PCL
//   uut.DU.pc_current — current PC wire (driven by PCL)
//   uut.DU.instr      — fetched instruction word
//   uut.DU.alu_result — ALU output
//   uut.DU.zero_flag  — ALU zero flag
//   uut.DU.reg_file.reg_array[N] — GPR register N
//   uut.DU.dm.memory[N]          — data memory word N
//   uut.ISM.start_reg  — ISM: interrupt pending (request_interrupt source)
//   uut.ISM.active_reg — ISM: interrupt active (blocks re-triggering)
//
// INTERRUPT TIMING (cycle-by-cycle)
// ----------------------------------
// Between clock edges N and N+1:
//   interrupt_pin rises  →  ISM start_reg=1  →  request_interrupt=1
//
// At clock edge N+1:
//   PCL: epc <= pc_current   ; pc_current <= 0x0002
//   ISM: start_reg <= 0      ; active_reg <= 1
//
// At clock edge N+2 (RETI at 0x0002 executes):
//   PCL: pc_current <= epc
//   ISM: active_reg <= 0
//
// Run from project root:
//   iverilog -Wall -I src/ -o build/star_sim \
//       src/Parameter.v src/ALU.v src/GPR.v src/InstructionMemory.v \
//       src/DataMemory.v src/ALU_Control.v src/ControlUnit.v \
//       src/ProgramCounterLogic.v src/Datapath.v src/StarCore1.v \
//       src/InterruptStateMachine.v tb/StarCore1_tb.v
//   cd test && ../build/star_sim
//   gtkwave ../waves/star.vcd &
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module StarCore1_tb;

    // -------------------------------------------------------------------------
    // Clock and GPIO pins
    // -------------------------------------------------------------------------
    reg  clk;
    reg  [15:0] io_in_pins;   // io_in_pins[0] is the IRQ source via GPIO

    initial clk        = 1'b0;
    initial io_in_pins = 16'd0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    wire [15:0] io_out_pins;

    StarCore1 uut (
        .clk        (clk),
        .io_in_pins (io_in_pins),
        .io_out_pins(io_out_pins)
    );

    // -------------------------------------------------------------------------
    // Waveform dump
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("../waves/star.vcd");
        $dumpvars(0, StarCore1_tb);
    end

    integer fail_count;
    integer test_id;
    reg [15:0] saved_pc;

    initial begin
        fail_count = 0;
        test_id    = 1;
    end

    // -------------------------------------------------------------------------
    // check16: compare 16-bit value, catching X and Z.
    // -------------------------------------------------------------------------
    task check16;
        input [15:0] got;
        input [15:0] expected;
        input [63:0] id;
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d]: got=0x%h expected=0x%h", id, got, expected);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d]: 0x%h", id, got);
        end
    endtask

    // -------------------------------------------------------------------------
    // check1: compare 1-bit value, catching X and Z.
    // -------------------------------------------------------------------------
    task check1;
        input       got;
        input       expected;
        input [127:0] label;
        input [63:0] id;
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d] %s: got=%b expected=%b", id, label, got, expected);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d] %s: %b", id, label, got);
        end
    endtask

    // -------------------------------------------------------------------------
    // Cycle-by-cycle trace — fires on every rising clock edge.
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        $display("%0t ns | PC=0x%h | instr=%b | R0=0x%h R1=0x%h R2=0x%h | alu=0x%h z=%b | irq=%b active=%b",
            $time,
            uut.DU.pc_current,
            uut.DU.instr,
            uut.DU.reg_file.reg_array[0],
            uut.DU.reg_file.reg_array[1],
            uut.DU.reg_file.reg_array[2],
            uut.DU.alu_result,
            uut.DU.zero_flag,
            uut.ISM.start_reg,
            uut.ISM.active_reg
        );
    end

    // =========================================================================
    // MAIN STIMULUS AND VERIFICATION
    // =========================================================================
    initial begin
        $display("=== StarCore-1 Integration Testbench ===");

        // ------------------------------------------------------------------
        // Phase 1: Normal operation — run 20 cycles without any interrupt.
        // ------------------------------------------------------------------
        $display("");
        $display("--- Phase 1: Normal operation (20 cycles, no interrupt) ---");

        repeat(20) @(posedge clk);
        #1;

        // T1: ISM must be idle — no spurious interrupts
        $display("T1: ISM idle before interrupt:");
        check1(uut.ISM.active_reg, 1'b0, "active_reg", test_id);
        test_id = test_id + 1;

        // ------------------------------------------------------------------
        // Phase 2: Fire interrupt.
        //   Save the PC value that is about to be executed.
        //   The interrupt fires between clock edges, so:
        //     epc will be saved_pc + 2  (the instruction that was displaced)
        //     PC  will jump to 0x0002   (handler — RETI at word 1)
        // ------------------------------------------------------------------
        $display("");
        $display("--- Phase 2: Interrupt fires ---");

        @(posedge clk); #1;
        saved_pc = uut.DU.pc_current;  // PC that will be displaced by interrupt

        // Pulse interrupt_pin between clock edges
        io_in_pins[0] = 1'b1;
        #2;
        io_in_pins[0] = 1'b0;

        // Next clock edge processes the interrupt
        @(posedge clk); #1;

        // T2: PC must be at the interrupt handler
        $display("T2: PC at handler (0x0002):");
        check16(uut.DU.pc_current, 16'h0002, test_id);
        test_id = test_id + 1;

        // T3: ISM must be in active state (blocks re-triggering)
        $display("T3: ISM active_reg set:");
        check1(uut.ISM.active_reg, 1'b1, "active_reg", test_id);
        test_id = test_id + 1;

        // T4: epc must be saved_pc (interrupt re-executes the interrupted instruction)
        $display("T4: epc = saved_pc:");
        check16(uut.DU.pcl.epc, saved_pc, test_id);
        test_id = test_id + 1;

        // ------------------------------------------------------------------
        // Phase 3: RETI executes (handler at 0x0002 is just RETI).
        // ------------------------------------------------------------------
        $display("");
        $display("--- Phase 3: RETI executes ---");

        @(posedge clk); #1;

        // T5: PC must be restored to saved_pc (re-executes the interrupted instruction)
        $display("T5: PC restored to epc:");
        check16(uut.DU.pc_current, saved_pc, test_id);
        test_id = test_id + 1;

        // T6: ISM must be back to idle
        $display("T6: ISM active_reg cleared:");
        check1(uut.ISM.active_reg, 1'b0, "active_reg", test_id);
        test_id = test_id + 1;

        // T7: PC must not be stuck at the handler
        $display("T7: PC left handler:");
        if (uut.DU.pc_current !== 16'h0002)
            $display("PASS [T%0d]: PC=0x%h (not stuck at handler)", test_id, uut.DU.pc_current);
        else begin
            $display("FAIL [T%0d]: PC is still 0x0002", test_id);
            fail_count = fail_count + 1;
        end
        test_id = test_id + 1;

        // ------------------------------------------------------------------
        // Phase 4: Second interrupt — verify ISM re-enables after RETI.
        // ------------------------------------------------------------------
        $display("");
        $display("--- Phase 4: Second interrupt (verify re-triggering) ---");

        @(posedge clk); #1;
        saved_pc = uut.DU.pc_current;

        io_in_pins[0] = 1'b1;
        #2;
        io_in_pins[0] = 1'b0;

        @(posedge clk); #1;

        // T8: Second interrupt must also vector to the handler
        $display("T8: PC at handler on second interrupt:");
        check16(uut.DU.pc_current, 16'h0002, test_id);
        test_id = test_id + 1;

        // T9: ISM active again
        $display("T9: ISM active_reg set on second interrupt:");
        check1(uut.ISM.active_reg, 1'b1, "active_reg", test_id);
        test_id = test_id + 1;

        // Second RETI
        @(posedge clk); #1;

        // T10: ISM clears after second RETI
        $display("T10: ISM idle after second RETI:");
        check1(uut.ISM.active_reg, 1'b0, "active_reg", test_id);
        test_id = test_id + 1;

        // T11: PC restored to correct address after second RETI
        $display("T11: PC restored after second RETI:");
        check16(uut.DU.pc_current, saved_pc, test_id);
        test_id = test_id + 1;

        // ------------------------------------------------------------------
        // Summary
        // ------------------------------------------------------------------
        $display("");
        $display("--- Final state ---");
        $display("R0=0x%h  R1=0x%h  R2=0x%h",
            uut.DU.reg_file.reg_array[0],
            uut.DU.reg_file.reg_array[1],
            uut.DU.reg_file.reg_array[2]);
        $display("Mem[0]=0x%h  Mem[1]=0x%h  Mem[2]=0x%h  Mem[3]=0x%h",
            uut.DU.dm.ram[0], uut.DU.dm.ram[1],
            uut.DU.dm.ram[2], uut.DU.dm.ram[3]);

        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d INTEGRATION TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d INTEGRATION TESTS FAILED ===", fail_count, test_id - 1);

        $finish;
    end

endmodule
