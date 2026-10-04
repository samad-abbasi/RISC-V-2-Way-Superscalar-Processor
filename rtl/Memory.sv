`timescale 1ns / 1ps


module Memory2W(
    input  logic        clk,
    input  logic        rst,
    // Inputs from Execute stage
    input  logic        RegWriteM0, RegWriteM1,
    input  logic        MemWriteM0, MemWriteM1,
    input  logic [1:0]  ResultSrcM0, ResultSrcM1,
    input  logic [31:0] ALUResultM0, ALUResultM1,
    input  logic [31:0] WriteDataM0, WriteDataM1,
    input  logic [31:0] PCPlus4M0, PCPlus4M1,
    input  logic [4:0]  RdM0, RdM1,
    // Outputs to Writeback stage
    output logic        RegWriteW0, RegWriteW1,
    output logic [1:0]  ResultSrcW0, ResultSrcW1,
    output logic [31:0] ALUResultW0, ALUResultW1,
    output logic [31:0] ReadDataW0, ReadDataW1,
    output logic [31:0] PCPlus4W0, PCPlus4W1,
    output logic [4:0]  RdW0, RdW1
);

   
    logic [31:0] ReadDataM0, ReadDataM1;
    DataMem2W data_mem(
        .clk  (clk),
  
        .WE0 (MemWriteM0),
        .A0  (ALUResultM0),
        .WD0 (WriteDataM0),
        .RD0 (ReadDataM0),
    
        .WE1 (MemWriteM1),
        .A1  (ALUResultM1),
        .WD1 (WriteDataM1),
        .RD1 (ReadDataM1)
    );

    // Pipeline registers to Writeback stage
    // Lane 0
    StateReg #(.WIDTH(1))  m0_u1 (.clk(clk), .rst(rst), .in(RegWriteM0),  .out(RegWriteW0),  .clr(1'b0));
    StateReg #(.WIDTH(2))  m0_u2 (.clk(clk), .rst(rst), .in(ResultSrcM0), .out(ResultSrcW0), .clr(1'b0));
    StateReg                m0_u3 (.clk(clk), .rst(rst), .in(ALUResultM0), .out(ALUResultW0), .clr(1'b0));
    StateReg                m0_u4 (.clk(clk), .rst(rst), .in(ReadDataM0),  .out(ReadDataW0),  .clr(1'b0));
    StateReg #(.WIDTH(5))  m0_u5 (.clk(clk), .rst(rst), .in(RdM0),        .out(RdW0),        .clr(1'b0));
    StateReg                m0_u6 (.clk(clk), .rst(rst), .in(PCPlus4M0),  .out(PCPlus4W0),   .clr(1'b0));

    // Lane 1
    StateReg #(.WIDTH(1))  m1_u1 (.clk(clk), .rst(rst), .in(RegWriteM1),  .out(RegWriteW1),  .clr(1'b0));
    StateReg #(.WIDTH(2))  m1_u2 (.clk(clk), .rst(rst), .in(ResultSrcM1), .out(ResultSrcW1), .clr(1'b0));
    StateReg                m1_u3 (.clk(clk), .rst(rst), .in(ALUResultM1), .out(ALUResultW1), .clr(1'b0));
    StateReg                m1_u4 (.clk(clk), .rst(rst), .in(ReadDataM1),  .out(ReadDataW1),  .clr(1'b0));
    StateReg #(.WIDTH(5))  m1_u5 (.clk(clk), .rst(rst), .in(RdM1),        .out(RdW1),        .clr(1'b0));
    StateReg                m1_u6 (.clk(clk), .rst(rst), .in(PCPlus4M1),  .out(PCPlus4W1),   .clr(1'b0));

endmodule