`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/23/2026 02:19:44 AM
// Design Name: 
// Module Name: ImmExtend
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


module ImmExtend(
input logic [1:0] ImmSrc, 
input logic [31:0] instruction,
output logic [31:0] ImmExtD
    );
    

 
    logic [11:0] load_imm, store_imm;
    logic [12:0] branch_imm;
    logic [20:0] jal_im;
           
    
    assign load_imm = instruction[31:20];
    assign store_imm = {instruction[31:25], instruction[11:7]};
    assign branch_imm = {instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    assign jal_im = {instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
   
    always @(*) begin 
    case (ImmSrc)
    2'b00://LW
        ImmExtD = {{20{load_imm[11]}}, load_imm};
    
    2'b01: //SW
        ImmExtD = {{20{store_imm[11]}}, store_imm};
    
    2'b10: //BEQ
        ImmExtD = {{19{branch_imm[12]}}, branch_imm};

    2'b11: //Jal
     ImmExtD = {{11{jal_im[20]}}, jal_im}; 
     
    default: ImmExtD = 32'b0; 
    endcase
    end
    
    
 endmodule   