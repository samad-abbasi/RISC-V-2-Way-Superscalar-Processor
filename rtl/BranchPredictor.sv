`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/29/2026 01:10:41 PM
// Design Name: 
// Module Name: BranchPredictor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module BranchPredictor #(parameter ENTRIES = 16)(
    input  logic        clk, rst,

    input  logic [31:0] PCF,
    output logic        PredictTakenF,
    output logic [31:0] PredictedPCF,

    input  logic        BranchE,
    input  logic        ActualTakenE,
    input  logic [31:0] PCE,
    input  logic [31:0] PCTargetE
);

    localparam IDX = $clog2(ENTRIES);

    logic [31:0] btb_target [0:ENTRIES-1];
    logic [1:0]  btb_state  [0:ENTRIES-1]; // 2-bit saturating counter
    logic        btb_valid  [0:ENTRIES-1];
    logic [31:0] btb_tag    [0:ENTRIES-1];

    // State encoding
    localparam STRONGLY_NOT_TAKEN = 2'b00;
    localparam WEAKLY_NOT_TAKEN   = 2'b01;
    localparam WEAKLY_TAKEN       = 2'b10;
    localparam STRONGLY_TAKEN     = 2'b11;

    wire [IDX-1:0] fetch_idx   = PCF[IDX+1:2];
    wire [IDX-1:0] execute_idx = PCE[IDX+1:2];

    wire tag_match = btb_valid[fetch_idx] && (btb_tag[fetch_idx] == PCF);
    wire predict_taken = tag_match && btb_state[fetch_idx][1]; // MSB=1 means predict taken

    assign PredictTakenF = predict_taken;
    assign PredictedPCF  = predict_taken ? btb_target[fetch_idx] : PCF + 4;

    integer i;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < ENTRIES; i++) begin
                btb_valid[i]  <= 0;
                btb_state[i]  <= WEAKLY_NOT_TAKEN; // start in middle
                btb_target[i] <= 0;
                btb_tag[i]    <= 0;
            end
        end else if (BranchE) begin
            btb_valid[execute_idx]  <= 1;
            btb_tag[execute_idx]    <= PCE;
            btb_target[execute_idx] <= PCTargetE;

            if (ActualTakenE) begin
                // Increment toward STRONGLY_TAKEN, saturate at 2'b11
                if (btb_state[execute_idx] != STRONGLY_TAKEN)
                    btb_state[execute_idx] <= btb_state[execute_idx] + 1;
            end else begin
                // Decrement toward STRONGLY_NOT_TAKEN, saturate at 2'b00
                if (btb_state[execute_idx] != STRONGLY_NOT_TAKEN)
                    btb_state[execute_idx] <= btb_state[execute_idx] - 1;
            end
        end
    end

endmodule