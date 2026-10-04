`timescale 1ns / 1ps


module WriteBack2W(
   
    input  logic        RegWriteW0,
    input  logic        RegWriteW1,
    // Data from the Memory stage
    input  logic [31:0] ALUResultW0,
    input  logic [31:0] ALUResultW1,
    input  logic [31:0] ReadDataW0,
    input  logic [31:0] ReadDataW1,
    input  logic [31:0] PCPlus4W0,
    input  logic [31:0] PCPlus4W1,
    input  logic [4:0]  RdW0,
    input  logic [4:0]  RdW1,
    input  logic [1:0]  ResultSrcW0,
    input  logic [1:0]  ResultSrcW1,

    output logic [31:0] ResultW0,
    output logic [31:0] ResultW1
);

    // Lane 0: select result based on ResultSrcW0
    //   2'b00 = ALU result
    //   2'b01 = data memory read
    //   2'b10 = PC+4 (for jal)
    Mux3 mux0(
        .in1 (ALUResultW0),
        .in2 (ReadDataW0),
        .in3 (PCPlus4W0),
        .sel (ResultSrcW0),
        .out (ResultW0)
    );

    // Lane 1: select result based on ResultSrcW1
    Mux3 mux1(
        .in1 (ALUResultW1),
        .in2 (ReadDataW1),
        .in3 (PCPlus4W1),
        .sel (ResultSrcW1),
        .out (ResultW1)
    );

endmodule