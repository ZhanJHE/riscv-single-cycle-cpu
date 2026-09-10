`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/02 16:14:17
// Design Name: 
// Module Name: pc
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


module pc(
    input clk,
    input rst,
    input[31:0] nextaddr,
    output reg [31:0] addr
    );
    always @(posedge clk)
    begin
        if(rst==1'b1)
            addr<=32'h00400000;
        else
            addr<=nextaddr;
    end
    
endmodule
