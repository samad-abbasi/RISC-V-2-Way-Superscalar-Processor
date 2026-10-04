`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/24/2026 03:07:18 PM
// Design Name: 
// Module Name: StateRegEn
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

module StateRegEn #(
    parameter int WIDTH = 32
)(
    input  logic             clk,
    input  logic             rst,
    input  logic              EN,
    input  logic       [WIDTH-1:0] in,
    output logic       [WIDTH-1:0] out,
    input logic               clr

);

always_ff @(posedge clk or posedge rst)
    if (rst)       out <= '0;
    else if (clr)  out <= '0;
    else if (!EN)  out <= in;
            


endmodule