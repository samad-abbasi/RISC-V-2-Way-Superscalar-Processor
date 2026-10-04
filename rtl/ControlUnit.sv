`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/23/2026 02:00:48 AM
// Design Name: 
// Module Name: ControlUnit
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


module ControlUnit(
    input logic  [6:0] op,
    input logic  [2:0] func3,
    input logic        func7_5,
 
    output logic       RegWriteD,
    output logic [1:0] ResultSrcD,
    output logic       MemWriteD,
    output logic       JumpD,
    output logic       BranchD,

    output logic [2:0] ALUControlD,

    output logic       ALUSrcD,
    
    output logic [1:0] ImmSrcD
    

);

logic [1:0] ALUop;


always @(*) begin
        case(op)
            // lw instruction
            7'b0000011: begin
                RegWriteD  = 1'b1;
                ALUSrcD    = 1'b1;
                MemWriteD  = 1'b0;
                ResultSrcD = 2'b01; 
                BranchD    = 1'b0;
                ALUop     = 2'b00;
                JumpD      = 1'b0;
                ImmSrcD    = 2'b00;  
            end

            // sw instruction
            7'b0100011: begin
                RegWriteD  = 1'b0;
                ALUSrcD    = 1'b1;
                MemWriteD  = 1'b1;
                ResultSrcD = 2'b00;
                BranchD    = 1'b0;
                ALUop     = 2'b00;
                JumpD      = 1'b0;  
                ImmSrcD    = 2'b01;  

            end

            // R-type instruction
            7'b0110011: begin
                RegWriteD  = 1'b1;
                ALUSrcD    = 1'b0;
                MemWriteD  = 1'b0;
                ResultSrcD = 2'b00; 
                BranchD    = 1'b0;
                ALUop     = 2'b10;
                JumpD      = 1'b0;
                ImmSrcD    = 2'b00;  
            end

            // beq instruction
            7'b1100011: begin
                RegWriteD  = 1'b0;
                ALUSrcD    = 1'b0;
                MemWriteD  = 1'b0;
                ResultSrcD = 2'b00;
                BranchD    = 1'b1;
                ALUop     = 2'b01;
                JumpD      = 1'b0;
                ImmSrcD    = 2'b10;  
            end

            // [NEW] jal instruction (J-Type)
            7'b1101111: begin
                RegWriteD  = 1'b1;     
                ALUSrcD    = 1'b0;     
                MemWriteD  = 1'b0;     
                ResultSrcD = 2'b10;    
                BranchD    = 1'b0;
                ALUop     = 2'b00;
                JumpD      = 1'b1;     // Unconditional JumpD
                ImmSrcD    = 2'b11;
            end
            
            //Immediate Command
            7'b0010011: begin 
                RegWriteD  = 1'b1;     
                ALUSrcD    = 1'b1;     
                MemWriteD  = 1'b0;     
                ResultSrcD = 2'b00;    
                BranchD    = 1'b0;
                ALUop     = 2'b10;
                JumpD      = 1'b0;   
                ImmSrcD    = 2'b00;            
            end 

            // default case
            default: begin
                RegWriteD  = 1'b0;
                ALUSrcD    = 1'b0;
                MemWriteD  = 1'b0;
                ResultSrcD = 2'b00;
                BranchD    = 1'b0;
                ALUop     = 2'b00;
                JumpD      = 1'b0; 
                ImmSrcD    = 2'b00;
            end
        endcase
    end

    parameter   ALU_ADD = 3'b000, 
                ALU_SUB = 3'b001, 
                ALU_AND = 3'b010, 
                ALU_OR  = 3'b011, 
                ALU_XOR = 3'b100, 
                ALU_SLL = 3'b101, 
                ALU_SRL = 3'b110;

    always_comb begin
        case (ALUop)
            2'b00: ALUControlD = ALU_ADD; 
            2'b01: ALUControlD = ALU_SUB; 
            
            2'b10: begin
                case (func3)
                    3'b000:  ALUControlD = func7_5 ? ALU_SUB : ALU_ADD; 
                    3'b001:  ALUControlD = ALU_SLL;                      
                    3'b100:  ALUControlD = ALU_XOR;                      
                    3'b101:  ALUControlD = ALU_SRL;                      
                    3'b110:  ALUControlD = ALU_OR;                       
                    3'b111:  ALUControlD = ALU_AND;                      
                    default: ALUControlD = ALU_ADD;
                endcase
            end


            default: ALUControlD = ALU_ADD;
        endcase
    end
    
    
endmodule