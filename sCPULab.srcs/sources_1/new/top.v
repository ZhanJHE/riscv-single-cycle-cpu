`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/10 16:38:07
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 仿真顶层：例化CPU、指令存储器ROM、数据存储器RAM
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input clk,
    input rst
    );
    
    wire[31:0] addr,insdata;
    wire memwe;
    wire[7:0] memaddr;
    wire[31:0] memwdata,memrdata;
    CPU mycpu(
        .clk(clk),
        .rst(rst),
        .pcAddr(addr),
        .insData(insdata),
        .memWe(memwe),
        .memAddr(memaddr),
        .memWdata(memwdata),
        .memRdata(memrdata)
    );
    
    //实例化ROM
    rom insrom(
        .addr(addr[9:2]),
        .data(insdata)
     );
     
     //实例化RAM
     ram dataram(
        .clk(clk),
        .we(memwe),
        .addr(memaddr),
        .data_in(memwdata),
        .data_out(memrdata)
     );
     
endmodule
