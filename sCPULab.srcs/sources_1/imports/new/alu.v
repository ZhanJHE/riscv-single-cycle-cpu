`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/10/07 14:58:57
// Design Name: 
// Module Name: alu
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


module alu(
    input [31:0] dataA,        // 操作数a（已重命名）
    input [31:0] dataB,        // 操作数b（已重命名）
    input [3:0] opcode,        // 操作码
    output reg [31:0] result,  // 运算结果
    output reg con             // 条件输出
);

// 中间信号
wire signed [31:0] signed_dataA = dataA;  // 有符号dataA
wire signed [31:0] signed_dataB = dataB;  // 有符号dataB
wire [31:0] sum = dataA + dataB;          // 加法结果
wire [31:0] diff = dataA - dataB;         // 减法结果

// 比较结果（1位）
wire lt_signed = (signed_dataA < signed_dataB);
wire lt_unsigned = (dataA < dataB);
wire eq = (dataA == dataB);
wire ne = (dataA != dataB);
wire ge_signed = (signed_dataA >= signed_dataB);
wire ge_unsigned = (dataA >= dataB);

always @(*) begin
    // 默认输出
    result = 0;
    con = 0;
    
    case(opcode)
        // 加法
        4'b0000: result = sum;
        
        // 逻辑左移
        4'b0001: result = dataA << dataB[4:0];
        
        // 有符号小于比较（特殊处理）
        4'b0010: begin
            result = {31'b0, lt_signed};
            con = lt_signed;
        end
        
        // 无符号小于比较（特殊处理）
        4'b0011: begin
            result = {31'b0, lt_unsigned};
            con = lt_unsigned;
        end
        
        // 异或
        4'b0100: result = dataA ^ dataB;
        
        // 逻辑右移
        4'b0101: result = dataA >> dataB[4:0];
        
        // 或
        4'b0110: result = dataA | dataB;
        
        // 与
        4'b0111: result = dataA & dataB;
        
        // 减法
        4'b1000: result = diff;
        
        // 相等比较（B类指令）
        4'b1001: begin
            result = 0;
            con = eq;
        end
        
        // 不等比较（B类指令）
        4'b1010: begin
            result = 0;
            con = ne;
        end
        
        // 有符号大于等于（B类指令）
        4'b1011: begin
            result = 0;
            con = ge_signed;
        end
        
        // 无符号大于等于（B类指令）
        4'b1100: begin
            result = 0;
            con = ge_unsigned;
        end
        
        // 算术右移
        4'b1101: result = signed_dataA >>> dataB[4:0];
        
        // JALR地址计算
        4'b1110: result = sum & ~32'b1;
        
        // LUI（加载高位立即数）
        4'b1111: result = dataB << 12;
        
        default: begin
            result = 0;
            con = 0;
        end
    endcase
end

endmodule