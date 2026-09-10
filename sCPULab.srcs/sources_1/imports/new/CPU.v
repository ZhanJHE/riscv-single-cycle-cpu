`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/26 09:07:55
// Design Name: 
// Module Name: CPU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: RISC-V单周期CPU数据通路，连接PC/译码/控制/寄存器堆/ALU
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CPU(
    input clk,
    input rst,
    output [31:0] pcAddr,    //pc指示当前地址
    input [31:0] insData,    //从rom中获取的指令
    output memWe,            //RAM写使能
    output [7:0] memAddr,    //RAM字地址
    output [31:0] memWdata,  //RAM写数据
    input [31:0] memRdata    //RAM读数据
    );
    //声明wire总线，用来连接各个模块
    wire[31:0]nextaddr,curraddr,addr4,rdata1,rdata2,rwdata,a,b,f,mdata,imm12_exp,imm20_exp,addr_branch,addr_jal,addr_jalr;
    wire[4:0] rs1,rs2,rd;
    wire[6:0] opcode;
    wire[2:0] func;
    wire[1:0] pcsource;
    wire dis,con,rwe,mwe,isimm,is20imm,isfm,ispc4;
    wire[11:0] imm12;
    wire[19:0] imm20;
    wire[3:0] aluop;
    //实例化PC
    pc mypc(
        .rst(rst),
        .clk(clk),
        .nextaddr(nextaddr),
        .addr(curraddr)
    ); 
    assign pcAddr=curraddr;
    
    //实例化ID
    ID myid(
        .ins(insData),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .opcode(opcode),
        .funct3(func),
        .funct7(dis),
        .imm12(imm12),
        .imm20(imm20)
    );
    
    //实例化控制单元
    ControlUnit mycu(
        .opcode(opcode),
        .funct3(func),
        .funct7(dis),
        .condition(con),
        .pcSourceCode(pcsource),
        .regWe(rwe),
        .memWe(mwe),
        .aluOpCode(aluop),
        .bIsImm(isimm),
        .bIs20bImm(is20imm),
        .regDataIsFromMem(isfm),
        .regDataIsFromPC4(ispc4)
    );
    
    //实例化寄存器堆
    RegFiles myrf(
        .raddr1(rs1),
        .rdata1(rdata1),
        .raddr2(rs2),
        .rdata2(rdata2),
        .waddr(rd),
        .wdata(rwdata),
        .we(rwe),
        .clk(clk)
    );
    
    //实例化ALU
    //获取a的数据 来源于rdata1
    assign a=rdata1;
    //将12位立即数符号扩展位32位
    assign imm12_exp={{20{imm12[11]}},imm12};
    //将20位立即数零扩展位32位（lui用，ALU内部再左移12位）
    assign imm20_exp={12'b0,imm20};
    //b操作数选择：lui选imm20 / I型选imm12符号扩展 / 其余选寄存器rdata2
    always @(*) begin
        if(is20imm)         b=imm20_exp;
        else if(isimm)      b=imm12_exp;
        else                b=rdata2;
    end
    //实例化ALU
    alu myalu(
        .dataA(a),
        .dataB(b),
        .opcode(aluop),
        .result(f),
        .con(con)
    );
    
    //写回数据选择：lw来自RAM / jal,jalr来自pc+4 / 其余来自ALU
    assign addr4=curraddr+32'd4;
    always @(*) begin
        if(isfm)            rwdata=mdata;
        else if(ispc4)      rwdata=addr4;
        else                rwdata=f;
    end
    
    //下地址选择：顺序pc+4 / 条件分支 / jal / jalr
    //B型立即数：ID输出的imm12=imm[12:1]，实际偏移=符号扩展后左移1位
    assign addr_branch=curraddr+{{19{imm12[11]}},imm12,1'b0};
    //J型立即数：ID输出的imm20=imm[20:1]，实际偏移=符号扩展后左移1位
    assign addr_jal=curraddr+{{11{imm20[19]}},imm20,1'b0};
    //jalr目标地址：ALU操作码1110=(rs1+imm12)&~1，此处再清一次bit0作双保险
    assign addr_jalr=f&~32'b1;
    always @(*) begin
        case(pcsource)
            2'b01:   nextaddr=con?addr_branch:addr4;    //条件分支：满足才跳
            2'b10:   nextaddr=addr_jal;                 //jal
            2'b11:   nextaddr=addr_jalr;                //jalr
            default: nextaddr=addr4;                    //顺序执行
        endcase
    end
    
    //RAM接口：地址取ALU结果的字索引（字节地址/4，与ROM的addr[9:2]风格一致），写数据为rdata2
    assign mdata=memRdata;
    assign memWe=mwe;
    assign memAddr={2'b00,f[9:2]};
    assign memWdata=rdata2;
    
endmodule
