`timescale 1ns / 1ps


module Hazard_Unit2W(

    input  logic [4:0] Rs1D0,
    input  logic [4:0] Rs2D0,
    input  logic [4:0] Rs1D1,
    input  logic [4:0] Rs2D1,
    input  logic        ValidD1,      // indicates whether slot 1 in decode is valid

    // Execute stage source and destination registers
    input  logic [4:0] Rs1E0,
    input  logic [4:0] Rs2E0,
    input  logic [4:0] Rs1E1,
    input  logic [4:0] Rs2E1,
    input  logic [4:0] RdE0,
    input  logic [4:0] RdE1,
    input  logic [1:0] ResultSrcE0,
    input  logic [1:0] ResultSrcE1,

    input  logic [4:0] RdM0,
    input  logic [4:0] RdM1,
    input  logic        RegWriteM0,
    input  logic        RegWriteM1,

    input  logic [4:0] RdW0,
    input  logic [4:0] RdW1,
    input  logic        RegWriteW0,
    input  logic        RegWriteW1,

   
    input  logic        BranchE0,       
    input  logic        PredictTakenE,  
    input  logic        PCSrcE,        

   
    output logic        StallF,
    output logic        StallD,
    output logic        FlushD,
    output logic        FlushE,

   
    output logic [1:0]  ForwardAE0,
    output logic [1:0]  ForwardBE0,
    output logic [1:0]  ForwardAE1,
    output logic [1:0]  ForwardBE1
);


    always @(*) begin
        // ForwardA0 (Rs1E0)
        if ( (RegWriteM0 && (RdM0 != 0) && (RdM0 == Rs1E0)) || (RegWriteM1 && (RdM1 != 0) && (RdM1 == Rs1E0)) ) begin
            ForwardAE0 = 2'b10;
        end else if ( (RegWriteW0 && (RdW0 != 0) && (RdW0 == Rs1E0)) || (RegWriteW1 && (RdW1 != 0) && (RdW1 == Rs1E0)) ) begin
            ForwardAE0 = 2'b01;
        end else begin
            ForwardAE0 = 2'b00;
        end

        // ForwardB0 (Rs2E0)
        if ( (RegWriteM0 && (RdM0 != 0) && (RdM0 == Rs2E0)) || (RegWriteM1 && (RdM1 != 0) && (RdM1 == Rs2E0)) ) begin
            ForwardBE0 = 2'b10;
        end else if ( (RegWriteW0 && (RdW0 != 0) && (RdW0 == Rs2E0)) || (RegWriteW1 && (RdW1 != 0) && (RdW1 == Rs2E0)) ) begin
            ForwardBE0 = 2'b01;
        end else begin
            ForwardBE0 = 2'b00;
        end
    end

    always @(*) begin
        // ForwardA1 (Rs1E1)
        if ( (RegWriteM0 && (RdM0 != 0) && (RdM0 == Rs1E1)) || (RegWriteM1 && (RdM1 != 0) && (RdM1 == Rs1E1)) ) begin
            ForwardAE1 = 2'b10;
        end else if ( (RegWriteW0 && (RdW0 != 0) && (RdW0 == Rs1E1)) || (RegWriteW1 && (RdW1 != 0) && (RdW1 == Rs1E1)) ) begin
            ForwardAE1 = 2'b01;
        end else begin
            ForwardAE1 = 2'b00;
        end

        // ForwardB1 (Rs2E1)
        if ( (RegWriteM0 && (RdM0 != 0) && (RdM0 == Rs2E1)) || (RegWriteM1 && (RdM1 != 0) && (RdM1 == Rs2E1)) ) begin
            ForwardBE1 = 2'b10;
        end else if ( (RegWriteW0 && (RdW0 != 0) && (RdW0 == Rs2E1)) || (RegWriteW1 && (RdW1 != 0) && (RdW1 == Rs2E1)) ) begin
            ForwardBE1 = 2'b01;
        end else begin
            ForwardBE1 = 2'b00;
        end
    end

 
    logic lwStall0, lwStall1, lwStall;
    always @(*) begin
     
        lwStall0 = 1'b0;
        if (ResultSrcE0[0]) begin
            if ( (Rs1D0 == RdE0 && RdE0 != 0) || (Rs2D0 == RdE0 && RdE0 != 0) )
                lwStall0 = 1'b1;
        end
        if (ResultSrcE1[0]) begin
            if ( (Rs1D0 == RdE1 && RdE1 != 0) || (Rs2D0 == RdE1 && RdE1 != 0) )
                lwStall0 = 1'b1;
        end

      
        lwStall1 = 1'b0;
        if (ValidD1) begin
            if (ResultSrcE0[0]) begin
                if ( (Rs1D1 == RdE0 && RdE0 != 0) || (Rs2D1 == RdE0 && RdE0 != 0) )
                    lwStall1 = 1'b1;
            end
            if (ResultSrcE1[0]) begin
                if ( (Rs1D1 == RdE1 && RdE1 != 0) || (Rs2D1 == RdE1 && RdE1 != 0) )
                    lwStall1 = 1'b1;
            end
        end

        lwStall = lwStall0 | lwStall1;
    end

    
    assign MispredictE = BranchE0 & (PredictTakenE != PCSrcE);

    assign StallF  = lwStall;
    assign StallD  = lwStall;
    assign FlushD  = MispredictE;
    assign FlushE  = lwStall | MispredictE;

endmodule