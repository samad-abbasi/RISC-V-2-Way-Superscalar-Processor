`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/23/2026 02:57:37 PM
// Design Name: 
// Module Name: StateReg
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


module StateReg #(
    parameter int WIDTH = 32
)(
    input  logic             clk,
    input  logic             rst,
    input  logic [WIDTH-1:0] in,
    output logic [WIDTH-1:0] out,
    input logic clr
);

always_ff @(posedge clk or posedge rst) begin
        if (rst || clr)  out <= '0;
        else             out <= in;
    end
    

endmodule