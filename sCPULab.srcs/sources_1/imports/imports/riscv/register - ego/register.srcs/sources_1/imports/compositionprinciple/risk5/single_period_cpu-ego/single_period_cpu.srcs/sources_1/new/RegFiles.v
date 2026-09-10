`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/04/21 14:41:44
// Design Name: 
// Module Name: RegFiles
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


module RegFiles(
    input clk,
    input [4:0] raddr1,
    output [31:0] rdata1,
    input [4:0] raddr2,
    output [31:0] rdata2,
    input [4:0] waddr,
    input we,
    input [31:0] wdata
    );
    reg[31:0] regs[1:31];
    integer i;
    initial
        for(i=1;i<32;i=i+1) regs[i]=32'b0;
    
    assign rdata1=(raddr1==5'b00000)?32'b0:regs[raddr1];  
    assign rdata2=(raddr2==5'b00000)?32'b0:regs[raddr2];
       
    always @(posedge clk)
        if(we)
            if(waddr!=4'b00000)
                regs[waddr]<=wdata;

endmodule
