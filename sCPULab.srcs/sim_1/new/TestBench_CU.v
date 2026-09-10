`timescale 1ns / 1ps

module ControlUnit_tb;

    // 输入信号
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg funct7;
    reg condition;
    
    // 输出信号
    wire [1:0] pcSourceCode;
    wire regWe;
    wire memWe;
    wire [3:0] aluOpCode;
    wire bIsImm;
    wire bIs20bImm;
    wire regDataIsFromMem;
    wire regDataIsFromPC4;
    
    // 实例化被测模块
    ControlUnit uut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .condition(condition),
        .pcSourceCode(pcSourceCode),
        .regWe(regWe),
        .memWe(memWe),
        .aluOpCode(aluOpCode),
        .bIsImm(bIsImm),
        .bIs20bImm(bIs20bImm),
        .regDataIsFromMem(regDataIsFromMem),
        .regDataIsFromPC4(regDataIsFromPC4)
    );
    
    // 测试过程
    initial begin
        // 初始化输入
        opcode = 0;
        funct3 = 0;
        funct7 = 0;
        condition = 0;
        
        // 打开波形文件
        $dumpfile("ControlUnit_tb.vcd");
        $dumpvars(0, ControlUnit_tb);
        
        // 测试R型指令
        $display("=== 测试R型指令 ===");
        opcode = 7'b0110011; // R型指令
        
        // ADD
        funct3 = 3'b000;
        funct7 = 0;
        #10;
        $display("ADD: aluOpCode=%b, regWe=%b", aluOpCode, regWe);
        
        // SUB
        funct3 = 3'b000;
        funct7 = 1;
        #10;
        $display("SUB: aluOpCode=%b, regWe=%b", aluOpCode, regWe);
        
        // AND
        funct3 = 3'b111;
        funct7 = 0;
        #10;
        $display("AND: aluOpCode=%b, regWe=%b", aluOpCode, regWe);
        
        // OR
        funct3 = 3'b110;
        funct7 = 0;
        #10;
        $display("OR: aluOpCode=%b, regWe=%b", aluOpCode, regWe);
        
        // XOR
        funct3 = 3'b100;
        funct7 = 0;
        #10;
        $display("XOR: aluOpCode=%b, regWe=%b", aluOpCode, regWe);
        
        // SLL
        funct3 = 3'b001;
        funct7 = 0;
        #10;
        $display("SLL: aluOpCode=%b, regWe=%b", aluOpCode, regWe);
        
        // SRL
        funct3 = 3'b101;
        funct7 = 0;
        #10;
        $display("SRL: aluOpCode=%b, regWe=%b", aluOpCode, regWe);
        
        // SRA
        funct3 = 3'b101;
        funct7 = 1;
        #10;
        $display("SRA: aluOpCode=%b, regWe=%b", aluOpCode, regWe);
        
        // 测试I型指令
        $display("\n=== 测试I型指令 ===");
        opcode = 7'b0010011; // I型指令
        
        // ADDI
        funct3 = 3'b000;
        #10;
        $display("ADDI: aluOpCode=%b, bIsImm=%b", aluOpCode, bIsImm);
        
        // ANDI
        funct3 = 3'b111;
        #10;
        $display("ANDI: aluOpCode=%b, bIsImm=%b", aluOpCode, bIsImm);
        
        // ORI
        funct3 = 3'b110;
        #10;
        $display("ORI: aluOpCode=%b, bIsImm=%b", aluOpCode, bIsImm);
        
        // XORI
        funct3 = 3'b100;
        #10;
        $display("XORI: aluOpCode=%b, bIsImm=%b", aluOpCode, bIsImm);
        
        // SLLI
        funct3 = 3'b001;
        #10;
        $display("SLLI: aluOpCode=%b, bIsImm=%b", aluOpCode, bIsImm);
        
        // SRLI
        funct3 = 3'b101;
        funct7 = 0;
        #10;
        $display("SRLI: aluOpCode=%b, bIsImm=%b", aluOpCode, bIsImm);
        
        // SRAI
        funct3 = 3'b101;
        funct7 = 1;
        #10;
        $display("SRAI: aluOpCode=%b, bIsImm=%b", aluOpCode, bIsImm);
        
        // 测试加载指令
        $display("\n=== 测试加载指令 ===");
        opcode = 7'b0000011; // LOAD
        funct3 = 3'b010; // LW
        #10;
        $display("LW: aluOpCode=%b, regDataIsFromMem=%b", aluOpCode, regDataIsFromMem);
        
        // 测试存储指令
        $display("\n=== 测试存储指令 ===");
        opcode = 7'b0100011; // STORE
        funct3 = 3'b010; // SW
        #10;
        $display("SW: aluOpCode=%b, memWe=%b", aluOpCode, memWe);
        
        // 测试分支指令
        $display("\n=== 测试分支指令 ===");
        opcode = 7'b1100011; // BRANCH
        
        // BEQ (条件满足)
        funct3 = 3'b000;
        condition = 1;
        #10;
        $display("BEQ (条件满足): pcSourceCode=%b", pcSourceCode);
        
        // BEQ (条件不满足)
        condition = 0;
        #10;
        $display("BEQ (条件不满足): pcSourceCode=%b", pcSourceCode);
        
        // BLT
        funct3 = 3'b100;
        condition = 1;
        #10;
        $display("BLT: aluOpCode=%b", aluOpCode);
        
        // BLTU
        funct3 = 3'b110;
        condition = 1;
        #10;
        $display("BLTU: aluOpCode=%b", aluOpCode);
        
        // 测试U型指令
        $display("\n=== 测试U型指令 ===");
        opcode = 7'b0110111; // LUI
        #10;
        $display("LUI: bIs20bImm=%b", bIs20bImm);
        
        // 测试J型指令
        $display("\n=== 测试J型指令 ===");
        
        // JAL
        opcode = 7'b1101111; // JAL
        #10;
        $display("JAL: pcSourceCode=%b, regDataIsFromPC4=%b", pcSourceCode, regDataIsFromPC4);
        
        // JALR
        opcode = 7'b1100111; // JALR
        #10;
        $display("JALR: pcSourceCode=%b, bIsImm=%b", pcSourceCode, bIsImm);
        
        // 测试完成
        $display("\n=== 测试完成 ===");
        #100 $finish;
    end

endmodule