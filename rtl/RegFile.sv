`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: RegFile2W
// Description: 6-ported register file for the 2-way superscalar pipeline
//              (Harris & Harris Fig. 7.68 style):
//                - 4 read ports  (2 instructions x 2 source operands)
//                - 2 write ports (2 instructions writing back per cycle)
//
// WAW behavior: if both write ports target the same nonzero register in the
// same cycle, SLOT 1 (the younger instruction in program order) must win.
// This falls out naturally here: WE0's write is issued first and WE1's write
// is issued second inside the same always block, so on a same-address
// collision the second non-blocking assignment is the one that "sticks."
//
// Read-during-write: like the original RegFile, writes happen on the falling
// edge and reads are combinational, so an instruction can read a value
// written earlier in the same clock cycle without needing forwarding.
//////////////////////////////////////////////////////////////////////////////////
 
module RegFile2W(
    input  logic        clk, rst,
 
    // Slot 0 (older instruction in the bundle) source registers
    input  logic [4:0]  A1_0, A2_0,
    output logic [31:0] RD1_0, RD2_0,
 
    // Slot 1 (younger instruction in the bundle) source registers
    input  logic [4:0]  A1_1, A2_1,
    output logic [31:0] RD1_1, RD2_1,
 
    // Writeback ports (slot 0 = AW0/WD0/WE0, slot 1 = AW1/WD1/WE1)
    input  logic [4:0]  AW0, AW1,
    input  logic [31:0] WD0, WD1,
    input  logic        WE0, WE1
);
 
    logic [31:0] reg_memory [31:0];
    integer i;
 
    always @(negedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                reg_memory[i] <= 32'b0;
        end else begin
            // Slot 0 writes first...
            if (WE0 && (AW0 != 0))
                reg_memory[AW0] <= WD0;
            // ...slot 1 writes second, so it wins a same-address WAW race,
            // matching in-order program semantics (later instruction wins).
            if (WE1 && (AW1 != 0))
                reg_memory[AW1] <= WD1;
        end
    end
 
    assign RD1_0 = reg_memory[A1_0];
    assign RD2_0 = reg_memory[A2_0];
    assign RD1_1 = reg_memory[A1_1];
    assign RD2_1 = reg_memory[A2_1];
 
endmodule