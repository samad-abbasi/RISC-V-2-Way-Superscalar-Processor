`timescale 1ns / 1ps

module Execute2W(
    input  logic        clk,
    input  logic        rst,
    // Control signals from Decode stage
    input  logic        RegWriteE0, RegWriteE1,
    input  logic        MemWriteE0, MemWriteE1,
    input  logic        JumpE0, JumpE1,
    input  logic        BranchE0, BranchE1,
    input  logic        ALUSrcE0, ALUSrcE1,
    input  logic [1:0]  ResultSrcE0, ResultSrcE1,
    input  logic [2:0]  ALUControlE0, ALUControlE1,
    // Operand values from Decode stage
    input  logic [31:0] RD1E0, RD1E1,
    input  logic [31:0] RD2E0, RD2E1,
    // Program counters and immediates
    input  logic [31:0] PCE0, PCE1,
    input  logic [31:0] PCPlus4E0, PCPlus4E1,
    input  logic [31:0] ImmExtE0, ImmExtE1,
    // Register numbers for forwarding 
    input  logic [4:0]  Rs1E0, Rs2E0,
    input  logic [4:0]  Rs1E1, Rs2E1,
    input  logic [4:0]  RdE0, RdE1,
    //  control  from Hazard unit
    input  logic [1:0]  ForwardAE0, ForwardBE0,
    input  logic [1:0]  ForwardAE1, ForwardBE1,
    // Results from Memory stage (for forwarding)
    input  logic [31:0] ALUResultM0, ALUResultM1,
    input  logic        RegWriteM0, RegWriteM1,
    input  logic [4:0]  RdM0, RdM1,
    // Results from Writeback stage (for forwarding)
    input  logic [31:0] ResultW0, ResultW1,
    input  logic        RegWriteW0, RegWriteW1,
    input  logic [4:0]  RdW0, RdW1,
    // Outputs to Memory stage
    output logic        RegWriteM0_out, RegWriteM1_out,
    output logic        MemWriteM0_out, MemWriteM1_out,
    output logic [1:0]  ResultSrcM0_out, ResultSrcM1_out,
    output logic [31:0] ALUResultM0_out, ALUResultM1_out,
    output logic [31:0] WriteDataM0_out, WriteDataM1_out,
    output logic [4:0]  RdM0_out, RdM1_out,
    output logic [31:0] PCPlus4M0, PCPlus4M1,
    // Branch outputs
    output logic        PCSrcE,
    output logic [31:0] PCTargetE
);

    logic [31:0] SrcA0, SrcB0_pre, SrcB0;
    logic [31:0] SrcA1_base, SrcB1_base;
    logic [31:0] SrcA1, SrcB1_pre, SrcB1;
    logic [31:0] Lane0BypassValue;
    logic        Lane0BypassValid;
    logic        Zero0;
    logic [31:0] ALURes0, ALURes1;


    always @(*) begin
        case (ForwardAE0)
            2'b10: begin
                if      (RegWriteM1 && (RdM1 != 0) && (Rs1E0 == RdM1)) SrcA0 = ALUResultM1;
                else if (RegWriteM0 && (RdM0 != 0) && (Rs1E0 == RdM0)) SrcA0 = ALUResultM0;
                else                                                   SrcA0 = RD1E0;
            end
            2'b01: begin
                if      (RegWriteW1 && (RdW1 != 0) && (Rs1E0 == RdW1)) SrcA0 = ResultW1;
                else if (RegWriteW0 && (RdW0 != 0) && (Rs1E0 == RdW0)) SrcA0 = ResultW0;
                else                                                   SrcA0 = RD1E0;
            end
            default: SrcA0 = RD1E0;
        endcase

        case (ForwardBE0)
            2'b10: begin
                if      (RegWriteM1 && (RdM1 != 0) && (Rs2E0 == RdM1)) SrcB0_pre = ALUResultM1;
                else if (RegWriteM0 && (RdM0 != 0) && (Rs2E0 == RdM0)) SrcB0_pre = ALUResultM0;
                else                                                   SrcB0_pre = RD2E0;
            end
            2'b01: begin
                if      (RegWriteW1 && (RdW1 != 0) && (Rs2E0 == RdW1)) SrcB0_pre = ResultW1;
                else if (RegWriteW0 && (RdW0 != 0) && (Rs2E0 == RdW0)) SrcB0_pre = ResultW0;
                else                                                   SrcB0_pre = RD2E0;
            end
            default: SrcB0_pre = RD2E0;
        endcase
    end

    assign SrcB0 = ALUSrcE0 ? ImmExtE0 : SrcB0_pre;

    ALU alu0(
        .in1        (SrcA0),
        .in2        (SrcB0),
        .alu_control(ALUControlE0),
        .result     (ALURes0),
        .zero_flag  (Zero0)
    );

    assign PCSrcE = JumpE0 | (Zero0 & BranchE0);
    adder adder0(PCE0, ImmExtE0, PCTargetE);


    assign Lane0BypassValue = (ResultSrcE0 == 2'b10) ? PCPlus4E0 : ALURes0;
    assign Lane0BypassValid = RegWriteE0 && (RdE0 != 5'd0) && (ResultSrcE0 != 2'b01);

 
    always @(*) begin
        case (ForwardAE1)
            2'b10: begin
                if      (RegWriteM1 && (RdM1 != 0) && (Rs1E1 == RdM1)) SrcA1_base = ALUResultM1;
                else if (RegWriteM0 && (RdM0 != 0) && (Rs1E1 == RdM0)) SrcA1_base = ALUResultM0;
                else                                                   SrcA1_base = RD1E1;
            end
            2'b01: begin
                if      (RegWriteW1 && (RdW1 != 0) && (Rs1E1 == RdW1)) SrcA1_base = ResultW1;
                else if (RegWriteW0 && (RdW0 != 0) && (Rs1E1 == RdW0)) SrcA1_base = ResultW0;
                else                                                   SrcA1_base = RD1E1;
            end
            default: SrcA1_base = RD1E1;
        endcase

        case (ForwardBE1)
            2'b10: begin
                if      (RegWriteM1 && (RdM1 != 0) && (Rs2E1 == RdM1)) SrcB1_base = ALUResultM1;
                else if (RegWriteM0 && (RdM0 != 0) && (Rs2E1 == RdM0)) SrcB1_base = ALUResultM0;
                else                                                   SrcB1_base = RD2E1;
            end
            2'b01: begin
                if      (RegWriteW1 && (RdW1 != 0) && (Rs2E1 == RdW1)) SrcB1_base = ResultW1;
                else if (RegWriteW0 && (RdW0 != 0) && (Rs2E1 == RdW0)) SrcB1_base = ResultW0;
                else                                                   SrcB1_base = RD2E1;
            end
            default: SrcB1_base = RD2E1;
        endcase


        if (Lane0BypassValid && (Rs1E1 == RdE0)) SrcA1 = Lane0BypassValue;
        else                                     SrcA1 = SrcA1_base;

        if (Lane0BypassValid && (Rs2E1 == RdE0)) SrcB1_pre = Lane0BypassValue;
        else                                     SrcB1_pre = SrcB1_base;
    end

    assign SrcB1 = ALUSrcE1 ? ImmExtE1 : SrcB1_pre;

    ALU alu1(
        .in1        (SrcA1),
        .in2        (SrcB1),
        .alu_control(ALUControlE1),
        .result     (ALURes1),
        .zero_flag  ()
    );

    // Pipeline registers to Memory stage
    StateReg #(.WIDTH(1))  reg0_u1 (.clk(clk), .rst(rst), .in(RegWriteE0),  .out(RegWriteM0_out),   .clr(1'b0));
    StateReg #(.WIDTH(1))  reg0_u2 (.clk(clk), .rst(rst), .in(MemWriteE0),  .out(MemWriteM0_out),   .clr(1'b0));
    StateReg #(.WIDTH(2))  reg0_u3 (.clk(clk), .rst(rst), .in(ResultSrcE0), .out(ResultSrcM0_out),  .clr(1'b0));
    StateReg               reg0_u4 (.clk(clk), .rst(rst), .in(ALURes0),     .out(ALUResultM0_out), .clr(1'b0));
    StateReg               reg0_u5 (.clk(clk), .rst(rst), .in(SrcB0_pre),   .out(WriteDataM0_out), .clr(1'b0));
    StateReg #(.WIDTH(5))  reg0_u6 (.clk(clk), .rst(rst), .in(RdE0),        .out(RdM0_out),        .clr(1'b0));
    StateReg               reg0_u7 (.clk(clk), .rst(rst), .in(PCPlus4E0),   .out(PCPlus4M0),       .clr(1'b0));

    StateReg #(.WIDTH(1))  reg1_u1 (.clk(clk), .rst(rst), .in(RegWriteE1),  .out(RegWriteM1_out),   .clr(1'b0));
    StateReg #(.WIDTH(1))  reg1_u2 (.clk(clk), .rst(rst), .in(MemWriteE1),  .out(MemWriteM1_out),   .clr(1'b0));
    StateReg #(.WIDTH(2))  reg1_u3 (.clk(clk), .rst(rst), .in(ResultSrcE1), .out(ResultSrcM1_out),  .clr(1'b0));
    StateReg               reg1_u4 (.clk(clk), .rst(rst), .in(ALURes1),     .out(ALUResultM1_out), .clr(1'b0));
    StateReg               reg1_u5 (.clk(clk), .rst(rst), .in(SrcB1_pre),   .out(WriteDataM1_out), .clr(1'b0));
    StateReg #(.WIDTH(5))  reg1_u6 (.clk(clk), .rst(rst), .in(RdE1),        .out(RdM1_out),        .clr(1'b0));
    StateReg               reg1_u7 (.clk(clk), .rst(rst), .in(PCPlus4E1),   .out(PCPlus4M1),       .clr(1'b0));

endmodule