`timescale 1ns / 1ps



module InstMem2W(
    input  logic [31:0] A,
    output logic [31:0] RD0,   // instruction at A        (slot 0)
    output logic [31:0] RD1    // instruction at A + 4    (slot 1)
);

logic [7:0] Memory [63:0]; // byte-addressable memory

initial begin
    // Instruction 0 (A=0): addi x1 x0 10
    Memory[0]  = 8'h93; Memory[1]  = 8'h00; Memory[2]  = 8'ha0; Memory[3]  = 8'h00;

    // Instruction 1 (A=4): addi x2 x0 20
    Memory[4]  = 8'h13; Memory[5]  = 8'h01; Memory[6]  = 8'h40; Memory[7]  = 8'h01;

    // Instruction 2 (A=8): add x3 x1 x2
    Memory[8]  = 8'hb3; Memory[9]  = 8'h81; Memory[10] = 8'h20; Memory[11] = 8'h00;

    // Instruction 3 (A=12): sw x2 13(x1)
    Memory[12] = 8'ha3; Memory[13] = 8'ha6; Memory[14] = 8'h20; Memory[15] = 8'h00;

    // Instruction 4 (A=16): lw x4 13(x1)
    Memory[16] = 8'h03; Memory[17] = 8'ha2; Memory[18] = 8'hd0; Memory[19] = 8'h00;

    // Instruction 5 (A=20): beq x4 x2 12   <- first encounter, BTB miss
    Memory[20] = 8'h63; Memory[21] = 8'h06; Memory[22] = 8'h22; Memory[23] = 8'h00;

    // Instruction 6 (A=24): addi x5 x4 50  <- flushed on first pass
    Memory[24] = 8'h93; Memory[25] = 8'h02; Memory[26] = 8'h22; Memory[27] = 8'h03;

    // Instruction 7 (A=28): addi x6 x5 100 <- flushed on first pass
    Memory[28] = 8'h13; Memory[29] = 8'h83; Memory[30] = 8'h42; Memory[31] = 8'h06;

    // Instruction 8 (A=32): addi x5 x4 400 <- branch target (label)
    Memory[32] = 8'h93; Memory[33] = 8'h02; Memory[34] = 8'h02; Memory[35] = 8'h19;

    // Instruction 9 (A=36): sub x6 x5 x4
    Memory[36] = 8'h33; Memory[37] = 8'h83; Memory[38] = 8'h42; Memory[39] = 8'h40;

    // Instruction 10 (A=40): addi x4 x0 20  (reset x4=20)
    Memory[40] = 8'h13; Memory[41] = 8'h02; Memory[42] = 8'h40; Memory[43] = 8'h01;

    // Instruction 11 (A=44): addi x2 x0 20  (ensure x2=20)
    Memory[44] = 8'h13; Memory[45] = 8'h01; Memory[46] = 8'h40; Memory[47] = 8'h01;

    // Instruction 12 (A=48): beq x4 x2 -28  (back to A=20, BTB now predicts taken)
    //Memory[48] = 8'he3; Memory[49] = 8'h02; Memory[50] = 8'h22; Memory[51] = 8'hfe;

    //Memory[52] = 8'h13; Memory[53] = 8'h00; Memory[54] = 8'h00; Memory[55] = 8'h00;
    //Memory[56] = 8'h13; Memory[57] = 8'h00; Memory[58] = 8'h00; Memory[59] = 8'h00;
    //Memory[60] = 8'h13; Memory[61] = 8'h00; Memory[62] = 8'h00; Memory[63] = 8'h00;
end

assign RD0 = {Memory[A+3], Memory[A+2], Memory[A+1], Memory[A]};
assign RD1 = {Memory[A+7], Memory[A+6], Memory[A+5], Memory[A+4]};

endmodule