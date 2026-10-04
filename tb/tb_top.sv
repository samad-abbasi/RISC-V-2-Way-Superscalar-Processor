`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: Top2W_tb
// Description : Self-checking testbench for the 2-way superscalar RISC-V project.
//               It verifies reset behavior, dual-issue activity, lane-1 branch
//               restriction, stalls/flushes, branch prediction accounting, data
//               memory write/load behavior, and final architectural register state.
//
// Simulation top: Top2W_tb
//////////////////////////////////////////////////////////////////////////////////

module Top2W_tb;

    // -------------------------------------------------------------------------
    // Clock / reset
    logic clk;
    logic rst;

    localparam int CLK_PERIOD_NS = 10;
    localparam int RESET_CYCLES  = 5;
    localparam int RUN_CYCLES    = 90;

    integer cycle;
    integer pass_count;
    integer fail_count;
    integer dual_wb_count;
    integer mem_write_count;
    integer stall_count;
    integer flush_count;
    integer correct_preds;
    integer mispreds;
    integer i;

    // -------------------------------------------------------------------------
    // DUT
    Top2W dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS/2) clk = ~clk;
    end

    // -------------------------------------------------------------------------
    // Helper: instruction mnemonic decoder for readable traces
    function automatic [63:0] instr_name(input logic [31:0] instr);
        begin
            case (instr[6:0])
                7'b0110011: begin
                    case ({instr[14:12], instr[30]})
                        4'b0000: instr_name = "ADD     ";
                        4'b0001: instr_name = "SUB     ";
                        4'b1110: instr_name = "AND     ";
                        4'b1100: instr_name = "OR      ";
                        4'b1000: instr_name = "XOR     ";
                        4'b0010: instr_name = "SLL     ";
                        4'b1010: instr_name = "SRL     ";
                        default: instr_name = "R-TYPE  ";
                    endcase
                end
                7'b0010011: instr_name = "ADDI    ";
                7'b0000011: instr_name = "LW      ";
                7'b0100011: instr_name = "SW      ";
                7'b1100011: instr_name = "BEQ     ";
                7'b1101111: instr_name = "JAL     ";
                7'b0000000: instr_name = "BUBBLE  ";
                default:    instr_name = "UNKNOWN ";
            endcase
        end
    endfunction

    // Helper: read architectural register from the RegFile2W inside Decode2W
    function automatic [31:0] get_reg(input int idx);
        begin
            get_reg = dut.decode_inst.rf.reg_memory[idx];
        end
    endfunction

    // Helper: read a 32-bit little-endian word from DataMem2W
    function automatic [31:0] get_mem_word(input int addr);
        begin
            get_mem_word = {
                dut.memory_inst.data_mem.memory[addr + 3],
                dut.memory_inst.data_mem.memory[addr + 2],
                dut.memory_inst.data_mem.memory[addr + 1],
                dut.memory_inst.data_mem.memory[addr]
            };
        end
    endfunction

    // Generic checker
    task automatic check_true(input logic condition, input string message);
        begin
            if (condition) begin
                pass_count = pass_count + 1;
                $display("[PASS] %s", message);
            end else begin
                fail_count = fail_count + 1;
                $error("[FAIL] %s", message);
            end
        end
    endtask

    task automatic check_eq32(input [31:0] actual, input [31:0] expected, input string message);
        begin
            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("[PASS] %s  actual=0x%08h expected=0x%08h", message, actual, expected);
            end else begin
                fail_count = fail_count + 1;
                $error("[FAIL] %s  actual=0x%08h expected=0x%08h", message, actual, expected);
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Optional initialization of data memory to avoid X values on unused bytes.
    // Program memory is initialized inside InstMem2W.
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            dut.memory_inst.data_mem.memory[i] = 8'h00;
    end

    // -------------------------------------------------------------------------
    // Main stimulus and final checks
    initial begin
        pass_count     = 0;
        fail_count     = 0;
        dual_wb_count  = 0;
        mem_write_count= 0;
        stall_count    = 0;
        flush_count    = 0;
        correct_preds  = 0;
        mispreds       = 0;
        cycle          = 0;

        // Wave dump for Icarus/GTKWave style simulators. Vivado may ignore this.
        $dumpfile("Top2W_tb.vcd");
        $dumpvars(0, Top2W_tb);

        // Reset
        rst = 1'b1;
        repeat (RESET_CYCLES) @(posedge clk);
        rst = 1'b0;
        $display("\n================ STARTING TOP2W SUPERSCALAR TEST ================\n");

        // Let program execute long enough to pass through the loop and update predictor.
        repeat (RUN_CYCLES) @(posedge clk);
        #1; // allow non-blocking assignments from the last clock edge to settle

        $display("\n================ FINAL ARCHITECTURAL STATE CHECKS ================");

        // Expected architectural state for the built-in InstMem2W program:
        //   addi x1, x0, 10
        //   addi x2, x0, 20
        //   add  x3, x1, x2      -> x3 = 30
        //   sw   x2, 13(x1)      -> MEM[23] = 20
        //   lw   x4, 13(x1)      -> x4 = 20
        //   beq  x4, x2, label   -> taken
        //   label: addi x5, x4, 400 -> x5 = 420
        //   sub  x6, x5, x4      -> x6 = 400
        check_eq32(get_reg(0),  32'd0,   "x0 must remain hardwired to zero");
        check_eq32(get_reg(1),  32'd10,  "x1 should be 10");
        check_eq32(get_reg(2),  32'd20,  "x2 should be 20");
        check_eq32(get_reg(3),  32'd30,  "x3 should be x1 + x2 = 30");
        check_eq32(get_reg(4),  32'd20,  "x4 should load 20 from data memory");
        check_eq32(get_reg(5),  32'd420, "x5 should be x4 + 400 = 420");
        check_eq32(get_reg(6),  32'd400, "x6 should be x5 - x4 = 400");
        check_eq32(get_mem_word(23), 32'd20, "MEM[13+x1] / MEM[23] should contain stored value 20");

        // Structural / behavioral checks
        check_true(dual_wb_count   > 0, "At least one cycle should write back through both superscalar lanes");
        check_true(mem_write_count > 0, "At least one store should reach the dual-ported data memory");
        check_true((correct_preds + mispreds) > 0, "At least one branch should be observed by the predictor statistics");
        check_true(flush_count > 0, "At least one flush should occur after an initial branch misprediction");

        $display("\n================ SUPERSCALAR TEST SUMMARY ================");
        $display("Total cycles              : %0d", cycle);
        $display("Dual writeback cycles     : %0d", dual_wb_count);
        $display("Memory write cycles       : %0d", mem_write_count);
        $display("Stall cycles              : %0d", stall_count);
        $display("Flush cycles              : %0d", flush_count);
        $display("Correct branch predictions: %0d", correct_preds);
        $display("Branch mispredictions     : %0d", mispreds);
        if ((correct_preds + mispreds) > 0)
            $display("Prediction accuracy       : %0.2f%%",
                     100.0 * correct_preds / (correct_preds + mispreds));
        $display("Pass checks               : %0d", pass_count);
        $display("Fail checks               : %0d", fail_count);
        $display("==========================================================\n");

        if (fail_count == 0) begin
            $display("TEST RESULT: PASS");
        end else begin
            $display("TEST RESULT: FAIL -- inspect forwarding/stall/flush waveforms.");
        end

        $finish;
    end

    // -------------------------------------------------------------------------
    // Cycle counter and run-time monitors/checks
    always @(posedge clk) begin
        if (rst) begin
            cycle <= 0;
        end else begin
            cycle <= cycle + 1;

            // Collect statistics
            if (dut.RegWriteW0 && dut.RegWriteW1)
                dual_wb_count <= dual_wb_count + 1;
            if (dut.MemWriteM0 || dut.MemWriteM1)
                mem_write_count <= mem_write_count + 1;
            if (dut.StallF || dut.StallD)
                stall_count <= stall_count + 1;
            if (dut.FlushD || dut.FlushE)
                flush_count <= flush_count + 1;

            if (dut.BranchE0) begin
                if (dut.PredictTakenE == dut.PCSrcE)
                    correct_preds <= correct_preds + 1;
                else
                    mispreds <= mispreds + 1;
            end

            // Always-valid design rules
            if (dut.PCD0[1:0] !== 2'b00)
                $error("PCD0 is not word aligned at cycle %0d: %h", cycle, dut.PCD0);
            if (dut.PCD1[1:0] !== 2'b00)
                $error("PCD1 is not word aligned at cycle %0d: %h", cycle, dut.PCD1);
            if (dut.ValidD1 && !dut.FlushD && (dut.PCD1 !== (dut.PCD0 + 32'd4)))
                $error("PCD1 should equal PCD0+4 when lane 1 is valid. cycle=%0d PCD0=%h PCD1=%h",
                       cycle, dut.PCD0, dut.PCD1);
            if (dut.BranchE1 !== 1'b0)
                $error("Lane 1 must not execute branch instructions. cycle=%0d", cycle);
            if (dut.JumpE1 !== 1'b0)
                $error("Lane 1 must not execute jump instructions. cycle=%0d", cycle);
            if (get_reg(0) !== 32'd0)
                $error("x0 changed from zero at cycle %0d: x0=%h", cycle, get_reg(0));

            // Readable trace for debugging
            $display("CYC=%0d | D0 PC=%08h Instr=%08h %-8s | D1 PC=%08h Instr=%08h %-8s ValidD1=%0b | ",
                     cycle,
                     dut.PCD0, dut.InstrD0, instr_name(dut.InstrD0),
                     dut.PCD1, dut.InstrD1, instr_name(dut.InstrD1), dut.ValidD1);
            $display("        E: BranchE0=%0b PredictTakenE=%0b PCSrcE=%0b PCTargetE=%08h StallF=%0b StallD=%0b FlushD=%0b FlushE=%0b",
                     dut.BranchE0, dut.PredictTakenE, dut.PCSrcE, dut.PCTargetE,
                     dut.StallF, dut.StallD, dut.FlushD, dut.FlushE);
            $display("        W: W0 RegWrite=%0b Rd=x%0d Result=%08h | W1 RegWrite=%0b Rd=x%0d Result=%08h",
                     dut.RegWriteW0, dut.RdW0, dut.ResultW0,
                     dut.RegWriteW1, dut.RdW1, dut.ResultW1);
        end
    end

endmodule
