`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/26 09:07:55
// Design Name: 
// Module Name: ControlUnit2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 主译码器：根据 opcode/funct3/funct7 产生全部控制信号
//              译码依据见 docs/03-instruction-set.md 控制真值表
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ControlUnit(
    input [6:0] opcode,
    input [2:0] funct3,
    input funct7,               //指令的第30位，区分 add/sub、srl/sra
    input condition,            //是否满足B类指令的跳转条件 =1  满足（由CPU中的下地址mux使用）
    output reg [1:0] pcSourceCode,  //下一条指令地址来源方式   =00 顺序执行   =01 有条件跳转   =10  jal    =11  jalr
    output reg regWe,           //寄存器写使能端   =1
    output reg memWe,           //RAM写使能端      =1
    output reg [3:0] aluOpCode, //ALU运算类型（编码见 docs/02 ALU操作码表）
    output reg bIsImm,          //b是否是立即数（12位符号扩展）
    output reg bIs20bImm,       //b是否是20位的立即数（lui）
    output reg regDataIsFromMem,    //rwdata是否来源于mem
    output reg regDataIsFromPC4     //rwdata是否来源于pc+4
    );

    always @(*) begin
        //默认：顺序执行、不写任何状态、ALU做加法、b选寄存器
        pcSourceCode = 2'b00;
        regWe = 1'b0;
        memWe = 1'b0;
        aluOpCode = 4'b0000;
        bIsImm = 1'b0;
        bIs20bImm = 1'b0;
        regDataIsFromMem = 1'b0;
        regDataIsFromPC4 = 1'b0;

        case (opcode)
            7'b0110011: begin               //R型指令
                regWe = 1'b1;
                case (funct3)
                    3'b000: aluOpCode = funct7 ? 4'b1000 : 4'b0000; //sub / add
                    3'b001: aluOpCode = 4'b0001;                    //sll
                    3'b010: aluOpCode = 4'b0010;                    //slt（扩展）
                    3'b011: aluOpCode = 4'b0011;                    //sltu（扩展）
                    3'b100: aluOpCode = 4'b0100;                    //xor
                    3'b101: aluOpCode = funct7 ? 4'b1101 : 4'b0101; //sra / srl
                    3'b110: aluOpCode = 4'b0110;                    //or
                    3'b111: aluOpCode = 4'b0111;                    //and
                    default: aluOpCode = 4'b0000;
                endcase
            end
            7'b0010011: begin               //I型运算指令
                regWe = 1'b1;
                bIsImm = 1'b1;
                case (funct3)
                    3'b000: aluOpCode = 4'b0000;                    //addi
                    3'b001: aluOpCode = 4'b0001;                    //slli
                    3'b010: aluOpCode = 4'b0010;                    //slti（扩展）
                    3'b011: aluOpCode = 4'b0011;                    //sltiu（扩展）
                    3'b100: aluOpCode = 4'b0100;                    //xori
                    3'b101: aluOpCode = funct7 ? 4'b1101 : 4'b0101; //srai / srli
                    3'b110: aluOpCode = 4'b0110;                    //ori
                    3'b111: aluOpCode = 4'b0111;                    //andi
                    default: aluOpCode = 4'b0000;
                endcase
            end
            7'b0000011: begin               //lw
                if (funct3 == 3'b010) begin
                    regWe = 1'b1;
                    bIsImm = 1'b1;
                    aluOpCode = 4'b0000;    //rs1+imm 计算地址
                    regDataIsFromMem = 1'b1;
                end
            end
            7'b0100011: begin               //sw
                if (funct3 == 3'b010) begin
                    memWe = 1'b1;
                    bIsImm = 1'b1;
                    aluOpCode = 4'b0000;    //rs1+imm 计算地址
                end
            end
            7'b1100011: begin               //条件分支指令（满足条件才跳转）
                pcSourceCode = 2'b01;
                case (funct3)
                    3'b000: aluOpCode = 4'b1001;                    //beq
                    3'b001: aluOpCode = 4'b1010;                    //bne（扩展）
                    3'b100: aluOpCode = 4'b0010;                    //blt
                    3'b101: aluOpCode = 4'b1011;                    //bge（扩展）
                    3'b110: aluOpCode = 4'b0011;                    //bltu
                    3'b111: aluOpCode = 4'b1100;                    //bgeu（扩展）
                    default: aluOpCode = 4'b1001;
                endcase
            end
            7'b0110111: begin               //lui：b=imm20，ALU内部左移12位
                regWe = 1'b1;
                bIs20bImm = 1'b1;
                aluOpCode = 4'b1111;
            end
            7'b1101111: begin               //jal：写回pc+4，跳转
                regWe = 1'b1;
                pcSourceCode = 2'b10;
                regDataIsFromPC4 = 1'b1;
            end
            7'b1100111: begin               //jalr：ALU算目标地址，写回pc+4
                regWe = 1'b1;
                bIsImm = 1'b1;
                aluOpCode = 4'b1110;
                pcSourceCode = 2'b11;
                regDataIsFromPC4 = 1'b1;
            end
            default: ;                      //未知指令：保持默认（等价nop）
        endcase
    end

endmodule
