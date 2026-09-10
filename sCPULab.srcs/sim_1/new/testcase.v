`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/31 08:52:29
// Design Name: 
// Module Name: testcase
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


module testcase(
    input [4:0] index,
    output [31:0] pc,
    output [31:0] x1,
    output [31:0] x2,
    output [31:0] x3
    );
    reg[31:0] pcData[0:31];
    initial
        $readmemh("../../../../testcase/pc.txt",pcData);
    assign pc=pcData[index];
    
    reg[31:0] x1Data[0:31];
    initial
        $readmemh("../../../../testcase/x1.txt",x1Data);
    assign x1=x1Data[index];
    
    reg[31:0] x2Data[0:31];
    initial
        $readmemh("../../../../testcase/x2.txt",x2Data);
    assign x2=x2Data[index];
    
    reg[31:0] x3Data[0:31];
    initial
        $readmemh("../../../../testcase/x3.txt",x3Data);
    assign x3=x3Data[index];
    
endmodule
