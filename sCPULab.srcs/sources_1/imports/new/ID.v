`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/26 09:07:55
// Design Name: 
// Module Name: ID
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 指令译码器：提取指令字段与立即数（I/S/B/U/J 型）
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ID(
    input [31:0] ins,
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,
    output [6:0] opcode,
    output [11:0] imm12,      //12位立即数
    output [2:0] funct3,
    output [19:0] imm20,      //20位立即数
    output funct7        //区分码，指令的第30位
    );
    
    assign opcode=ins[6:0];
    assign rd=ins[11:7];
    assign funct3=ins[14:12];
    assign rs1=ins[19:15];
    assign rs2=ins[24:20];
    assign funct7=ins[30];

    wire I_type,S_type,B_type,J_type,U_type;
    //00x0011  I指令  
    assign I_type=~ins[6]&~ins[5]&~ins[3]&~ins[2]&ins[1]&ins[0];  
    //1100011  B指令
    assign B_type=(&ins[6:5])&~(|ins[4:2])&(&ins[1:0]);   
    //0100011  S指令        
    assign S_type=~ins[6]&ins[5]&~(|ins[4:2])&(&ins[1:0]); 
    //0110111  U指令（lui）
    assign U_type=(ins[6:0]==7'b0110111);
    //1101111  J指令（jal）
    assign J_type=(ins[6:0]==7'b1101111);
        
    assign imm12={12{I_type}}&ins[31:20]|
                 {12{B_type}}&{ins[31],ins[7],ins[30:25],ins[11:8]}|
                 {12{S_type}}&{ins[31:25],ins[11:7]};
    //U型：imm20 = ins[31:12]
    //J型：imm20 = {imm[20],imm[19:12],imm[11],imm[10:1]} = imm[20:1]（CPU端左移1位使用）
    assign imm20={20{U_type}}&ins[31:12]|
                 {20{J_type}}&{ins[31],ins[19:12],ins[20],ins[30:21]};

endmodule
