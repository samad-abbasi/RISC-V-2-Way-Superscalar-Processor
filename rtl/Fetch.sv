`timescale 1ns / 1ps

module Fetch2W(
    input  logic [31:0] PCTargetE,
    input  logic        PCSrcE, clk, rst, StallF, StallD, FlushD,
    input  logic        BranchE,
    input  logic [31:0] PCE,

    input  logic        ResyncD,         // Hazard Unit wants slot1 re-fetched alone
    input  logic [31:0] ResyncPCD,       // address to re-fetch (= this Fetch's own PCD1)

    output logic [31:0] InstrD0, InstrD1,
    output logic [31:0] PCD0, PCD1,
    output logic [31:0] PCPlus4D0, PCPlus4D1,
    output logic        PredictTakenD,   
    output logic        ValidD1         
    );

    logic [31:0] PCFout, PCNextF;
    logic [31:0] InstrF0, InstrF1;
    logic [31:0] PCPlus4F0, PCPlus4F1;
    logic        PredictTakenF;
    logic [31:0] PredictedPCF;
    logic        ValidF1;

    //Branch Predictor for PC0 
    BranchPredictor #(.ENTRIES(16)) bp (
        .clk           (clk),
        .rst           (rst),
        .PCF           (PCFout),
        .PredictTakenF (PredictTakenF),
        .PredictedPCF  (PredictedPCF),
        .BranchE       (BranchE),
        .ActualTakenE  (PCSrcE),
        .PCE           (PCE),
        .PCTargetE     (PCTargetE)
    );

  
    InstMem2W instructionMem (
        .A   (PCFout),
        .RD0 (InstrF0),     // slot 0: instr at PCFout
        .RD1 (InstrF1)      // slot 1: instr at PCFout + 4
    );

    adder plus4adder0 (PCFout,    32'd4, PCPlus4F0);   
    adder plus4adder1 (PCPlus4F0, 32'd4, PCPlus4F1);  

  
    assign ValidF1 = ~PredictTakenF;

    always_comb begin
      if      (PCSrcE)        PCNextF = PCTargetE;     
       else if (ResyncD)       PCNextF = ResyncPCD;     
       else if (PredictTakenF) PCNextF = PredictedPCF; 
        else                    PCNextF = PCPlus4F1;     
    end

    StateRegEn PCBuffer (clk, rst, StallF, PCNextF, PCFout, 1'b0);


    StateRegEn InstrD0buffer (clk, rst, StallD, InstrF0,   InstrD0,   FlushD);
    StateRegEn InstrD1buffer (clk, rst, StallD, InstrF1,   InstrD1,   FlushD);

    StateRegEn PCD0buffer    (clk, rst, StallD, PCFout,    PCD0,      FlushD);
    StateRegEn PCD1buffer    (clk, rst, StallD, PCPlus4F0, PCD1,      FlushD); 

    StateRegEn PCPlus4D0buf  (clk, rst, StallD, PCPlus4F0, PCPlus4D0, FlushD);
    StateRegEn PCPlus4D1buf  (clk, rst, StallD, PCPlus4F1, PCPlus4D1, FlushD);

    StateRegEn #(.WIDTH(1)) PredTakenDbuf (clk, rst, StallD, PredictTakenF, PredictTakenD, FlushD);

 
    StateRegEn #(.WIDTH(1)) ValidD1buf (clk, rst, StallD, ValidF1, ValidD1, FlushD);

endmodule