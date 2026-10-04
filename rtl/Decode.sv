`timescale 1ns / 1ps


module Decode2W(
    input  logic        clk,
    input  logic        rst,
    
 
    input  logic        RegWriteW0,
    input  logic        RegWriteW1,
    input  logic [31:0] ResultW0,
    input  logic [31:0] ResultW1,
    input  logic [4:0]  RdW0,
    input  logic [4:0]  RdW1,
  
    input  logic [31:0] InstrD0,
    input  logic [31:0] InstrD1,
    input  logic [31:0] PCD0,
    input  logic [31:0] PCD1,
    input  logic [31:0] PCPlus4D0,
    input  logic [31:0] PCPlus4D1,
    input  logic        PredictTakenD,
    input  logic        ValidD1,

    input  logic        FlushE,
  
    output logic        PredictTakenE,
    output logic        RegWriteE0, RegWriteE1,
    output logic        MemWriteE0, MemWriteE1,
    output logic        JumpE0, JumpE1,
    output logic        BranchE0, BranchE1,
    output logic        ALUSrcE0, ALUSrcE1,
    output logic [1:0]  ResultSrcE0, ResultSrcE1,
    output logic [2:0]  ALUControlE0, ALUControlE1,
    output logic [4:0]  RdE0, RdE1,
    output logic [4:0]  Rs1E0, Rs1E1,
    output logic [4:0]  Rs2E0, Rs2E1,
    output logic [31:0] RD1E0, RD1E1,
    output logic [31:0] RD2E0, RD2E1,
    output logic [31:0] PCE0, PCE1,
    output logic [31:0] PCPlus4E0, PCPlus4E1,
    output logic [31:0] ImmExtE0, ImmExtE1,
    output logic        ValidE1
);

    //  wires for slot 0
    logic        RegWriteD0, MemWriteD0, JumpD0, BranchD0, ALUSrcD0;
    logic [1:0]  ResultSrcD0;
    logic [2:0]  ALUControlD0;
    logic [1:0]  ImmSrcD0;
    logic [4:0]  RdD0, Rs1D0, Rs2D0;
    logic [31:0] ImmExtD0;
    logic [31:0] RD1D0, RD2D0;

    //  wires for slot 1
    logic        RegWriteD1, MemWriteD1, JumpD1, BranchD1, ALUSrcD1;
    logic [1:0]  ResultSrcD1;
    logic [2:0]  ALUControlD1;
    logic [1:0]  ImmSrcD1;
    logic [4:0]  RdD1, Rs1D1, Rs2D1;
    logic [31:0] ImmExtD1;
    logic [31:0] RD1D1, RD2D1;

   
    assign RdD0  = InstrD0[11:7];
    assign Rs1D0 = InstrD0[19:15];
    assign Rs2D0 = InstrD0[24:20];
    assign RdD1  = InstrD1[11:7];
    assign Rs1D1 = InstrD1[19:15];
    assign Rs2D1 = InstrD1[24:20];

    
ControlUnit cu0 (
    .op(InstrD0[6:0]), .func3(InstrD0[14:12]), .func7_5(InstrD0[30]),
    .RegWriteD(RegWriteD0), .ResultSrcD(ResultSrcD0), .MemWriteD(MemWriteD0),
    .JumpD(JumpD0), .BranchD(BranchD0), .ALUControlD(ALUControlD0),
    .ALUSrcD(ALUSrcD0), .ImmSrcD(ImmSrcD0)
);

ControlUnit cu1 (
    .op(InstrD1[6:0]), .func3(InstrD1[14:12]), .func7_5(InstrD1[30]),
    .RegWriteD(RegWriteD1), .ResultSrcD(ResultSrcD1), .MemWriteD(MemWriteD1),
    .JumpD(JumpD1), .BranchD(BranchD1), .ALUControlD(ALUControlD1),
    .ALUSrcD(ALUSrcD1), .ImmSrcD(ImmSrcD1)
);
  
    ImmExtend ie0(.ImmSrc(ImmSrcD0), .instruction(InstrD0), .ImmExtD(ImmExtD0));
    ImmExtend ie1(.ImmSrc(ImmSrcD1), .instruction(InstrD1), .ImmExtD(ImmExtD1));

    
RegFile2W rf (
    .clk(clk), .rst(rst), .A1_0(Rs1D0), .A2_0(Rs2D0),
    .A1_1(Rs1D1), .A2_1(Rs2D1), .RD1_0(RD1D0), .RD2_0(RD2D0),
    .RD1_1(RD1D1), .RD2_1(RD2D1), .AW0(RdW0), .AW1(RdW1),
    .WD0(ResultW0), .WD1(ResultW1), .WE0(RegWriteW0), .WE1(RegWriteW1)
     );

    // RAW dependency: slot 1 uses slot 0 destination
    logic cross_dep;
    assign cross_dep = ValidD1 && RegWriteD0 && (RdD0 != 5'd0) &&
                       ((Rs1D1 == RdD0) || (Rs2D1 == RdD0));

    // Prevent slot 1 from branching or jumping
    logic lane1_has_branch_jump;
    assign lane1_has_branch_jump = JumpD1 | BranchD1;

    // Effective validity of slot 1 after dependency and control checks
    logic Valid1_eff;
    // Same-bundle ALU RAW hazards are handled by lane0->lane1 forwarding in Execute2W.
    // Slot 1 is only blocked here if it is not fetched/valid or if it is a branch/jump.
    assign Valid1_eff = ValidD1 && ~lane1_has_branch_jump;

    // Mask control signals for slot 1 when invalid
    logic        RegWriteD1_eff, MemWriteD1_eff, JumpD1_eff, BranchD1_eff, ALUSrcD1_eff;
    logic [1:0]  ResultSrcD1_eff;
    logic [2:0]  ALUControlD1_eff;
    logic [31:0] ImmExtD1_eff;
    logic [4:0]  RdD1_eff, Rs1D1_eff, Rs2D1_eff;
    logic [31:0] RD1D1_eff, RD2D1_eff;
    logic [31:0] PCD1_eff, PCPlus4D1_eff;

    assign RegWriteD1_eff   = Valid1_eff ? RegWriteD1   : 1'b0;
    assign MemWriteD1_eff   = Valid1_eff ? MemWriteD1   : 1'b0;
    // Do not allow jumps/branches in slot 1
    assign JumpD1_eff       = 1'b0;
    assign BranchD1_eff     = 1'b0;
    assign ALUSrcD1_eff     = Valid1_eff ? ALUSrcD1     : 1'b0;
    assign ResultSrcD1_eff  = Valid1_eff ? ResultSrcD1  : 2'b00;
    assign ALUControlD1_eff = Valid1_eff ? ALUControlD1 : 3'b000;
    assign ImmExtD1_eff     = Valid1_eff ? ImmExtD1     : 32'b0;
    assign RdD1_eff         = Valid1_eff ? RdD1         : 5'b0;
    assign Rs1D1_eff        = Valid1_eff ? Rs1D1        : 5'b0;
    assign Rs2D1_eff        = Valid1_eff ? Rs2D1        : 5'b0;
    assign RD1D1_eff        = Valid1_eff ? RD1D1        : 32'b0;
    assign RD2D1_eff        = Valid1_eff ? RD2D1        : 32'b0;
    assign PCD1_eff         = Valid1_eff ? PCD1         : 32'b0;
    assign PCPlus4D1_eff    = Valid1_eff ? PCPlus4D1    : 32'b0;

    // Pipeline registers (Decode -> Execute) for slot 0
    StateReg #(.WIDTH(1))  uRegWrite0  (.clk(clk), .rst(rst), .in(RegWriteD0),   .out(RegWriteE0),   .clr(FlushE));
    StateReg #(.WIDTH(1))  uMemWrite0  (.clk(clk), .rst(rst), .in(MemWriteD0),   .out(MemWriteE0),   .clr(FlushE));
    StateReg #(.WIDTH(1))  uJump0      (.clk(clk), .rst(rst), .in(JumpD0),       .out(JumpE0),       .clr(FlushE));
    StateReg #(.WIDTH(1))  uBranch0    (.clk(clk), .rst(rst), .in(BranchD0),     .out(BranchE0),     .clr(FlushE));
    StateReg #(.WIDTH(1))  uALUSrc0    (.clk(clk), .rst(rst), .in(ALUSrcD0),     .out(ALUSrcE0),     .clr(FlushE));
    StateReg #(.WIDTH(2))  uResultSrc0 (.clk(clk), .rst(rst), .in(ResultSrcD0),  .out(ResultSrcE0),  .clr(FlushE));
    StateReg #(.WIDTH(3))  uALUCtrl0   (.clk(clk), .rst(rst), .in(ALUControlD0), .out(ALUControlE0), .clr(FlushE));
    StateReg #(.WIDTH(5))  uRd0        (.clk(clk), .rst(rst), .in(RdD0),        .out(RdE0),        .clr(FlushE));
    StateReg #(.WIDTH(5))  uRs10       (.clk(clk), .rst(rst), .in(Rs1D0),       .out(Rs1E0),       .clr(FlushE));
    StateReg #(.WIDTH(5))  uRs20       (.clk(clk), .rst(rst), .in(Rs2D0),       .out(Rs2E0),       .clr(FlushE));
    StateReg #(.WIDTH(32)) uRD1_0      (.clk(clk), .rst(rst), .in(RD1D0),       .out(RD1E0),       .clr(FlushE));
    StateReg #(.WIDTH(32)) uRD2_0      (.clk(clk), .rst(rst), .in(RD2D0),       .out(RD2E0),       .clr(FlushE));
    StateReg #(.WIDTH(32)) uPC0        (.clk(clk), .rst(rst), .in(PCD0),        .out(PCE0),        .clr(FlushE));
    StateReg #(.WIDTH(32)) uPCPlus4_0  (.clk(clk), .rst(rst), .in(PCPlus4D0),   .out(PCPlus4E0),   .clr(FlushE));
    StateReg #(.WIDTH(32)) uImm0       (.clk(clk), .rst(rst), .in(ImmExtD0),    .out(ImmExtE0),    .clr(FlushE));

    // Pipeline registers for slot 1
    StateReg #(.WIDTH(1))  vRegWrite1  (.clk(clk), .rst(rst), .in(RegWriteD1_eff),   .out(RegWriteE1),   .clr(FlushE));
    StateReg #(.WIDTH(1))  vMemWrite1  (.clk(clk), .rst(rst), .in(MemWriteD1_eff),   .out(MemWriteE1),   .clr(FlushE));
    StateReg #(.WIDTH(1))  vJump1      (.clk(clk), .rst(rst), .in(JumpD1_eff),       .out(JumpE1),       .clr(FlushE));
    StateReg #(.WIDTH(1))  vBranch1    (.clk(clk), .rst(rst), .in(BranchD1_eff),     .out(BranchE1),     .clr(FlushE));
    StateReg #(.WIDTH(1))  vALUSrc1    (.clk(clk), .rst(rst), .in(ALUSrcD1_eff),     .out(ALUSrcE1),     .clr(FlushE));
    StateReg #(.WIDTH(2))  vResultSrc1 (.clk(clk), .rst(rst), .in(ResultSrcD1_eff),  .out(ResultSrcE1),  .clr(FlushE));
    StateReg #(.WIDTH(3))  vALUCtrl1   (.clk(clk), .rst(rst), .in(ALUControlD1_eff), .out(ALUControlE1), .clr(FlushE));
    StateReg #(.WIDTH(5))  vRd1        (.clk(clk), .rst(rst), .in(RdD1_eff),        .out(RdE1),        .clr(FlushE));
    StateReg #(.WIDTH(5))  vRs11       (.clk(clk), .rst(rst), .in(Rs1D1_eff),       .out(Rs1E1),       .clr(FlushE));
    StateReg #(.WIDTH(5))  vRs21       (.clk(clk), .rst(rst), .in(Rs2D1_eff),       .out(Rs2E1),       .clr(FlushE));
    StateReg #(.WIDTH(32)) vRD1_1      (.clk(clk), .rst(rst), .in(RD1D1_eff),       .out(RD1E1),       .clr(FlushE));
    StateReg #(.WIDTH(32)) vRD2_1      (.clk(clk), .rst(rst), .in(RD2D1_eff),       .out(RD2E1),       .clr(FlushE));
    StateReg #(.WIDTH(32)) vPC1        (.clk(clk), .rst(rst), .in(PCD1_eff),        .out(PCE1),        .clr(FlushE));
    StateReg #(.WIDTH(32)) vPCPlus4_1  (.clk(clk), .rst(rst), .in(PCPlus4D1_eff),   .out(PCPlus4E1),   .clr(FlushE));
    StateReg #(.WIDTH(32)) vImm1       (.clk(clk), .rst(rst), .in(ImmExtD1_eff),    .out(ImmExtE1),    .clr(FlushE));

    // Propagate predicted taken bit for slot 0
    StateReg #(.WIDTH(1))  pred_buf (.clk(clk), .rst(rst), .in(PredictTakenD), .out(PredictTakenE), .clr(FlushE));

    // Propagate validity of slot 1
    StateReg #(.WIDTH(1))  valid_buf (.clk(clk), .rst(rst), .in(Valid1_eff),    .out(ValidE1),      .clr(FlushE));

endmodule