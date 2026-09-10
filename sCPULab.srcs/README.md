# RISC-V 单周期CPU设计文档

本项目实现了一个基于RISC-V指令集架构的单周期CPU，包含完整的指令执行流程。以下是对各模块的详细介绍。

## 模块结构示意

```text
                    +--------------------------------------------------+
                    |                      top                         |
                    |                                                  |
                    |  +-----------+    +-----------+    +-----------+  |
                    |  |   CPU     |    |  insrom   |    |  dataram  |  |
                    |  |           |    |           |    |           |  |
                    |  |           |    |           |    |           |  |
                    |  +-----------+    +-----------+    +-----------+  |
                    +--------------------------------------------------+

                              |
                              v

                    +--------------------------------------------------+
                    |                    CPU模块                       |
                    |                                                  |
                    |  +------+  +----+  +-----+  +---+  +---------+   |
                    |  |  pc  |  | ID |  | CU  |  |ALU|  |RegFiles |   |
                    |  +------+  +----+  +-----+  +---+  +---------+   |
                    +--------------------------------------------------+
```

## 各模块详细说明

### 1. 顶层设计(top.v)

顶层模块连接CPU核心、指令存储器(ROM)和数据存储器(RAM)。

[//]: # (以下为Verilog代码，已省略具体实现)

### 2. CPU核心模块(CPU.v)

CPU核心模块整合了所有子模块，包括PC、指令解码、控制单元、ALU和寄存器堆等。

[//]: # (以下为Verilog代码，已省略具体实现)

### 3. 程序计数器(pc.v)

负责维护当前指令地址，并根据下一地址更新。

```verilog
`timescale 1ns / 1ps

// 程序计数器模块
module pc(
    input rst,            // 复位信号，高电平有效
    input clk,            // 时钟信号
    input [31:0] nextaddr, // 下一条指令地址
    output reg [31:0] addr // 当前指令地址
);

always @(posedge clk) begin
    if(rst)
        addr <= 32'h0;     // 复位时PC清零
    else
        addr <= nextaddr;  // 正常情况下更新为下一条指令地址
end

endmodule
```

### 4. 指令解码(ID.v)

解析32位RISC-V指令，提取操作码、寄存器地址和立即数等字段。

```verilog
`timescale 1ns / 1ps

// 指令解码模块
module ID(
    input [31:0] ins,       // 32位指令输入
    output [4:0] rs1,       // 源寄存器1地址输出
    output [4:0] rs2,       // 源寄存器2地址输出
    output [4:0] rd,        // 目标寄存器地址输出
    output [6:0] opcode,    // 操作码输出
    output [2:0] funct3,    // funct3功能码输出
    output dis,             // 判别码第7位输出(即funct7最高位)
    output [11:0] imm12,    // 12位立即数输出
    output [19:0] imm20     // 20位立即数输出
);

assign opcode = ins[6:0];      // 操作码：指令[6:0]
assign rs1 = ins[19:15];        // 源寄存器1：指令[19:15]
assign rs2 = ins[24:20];        // 源寄存器2：指令[24:20]
assign rd = ins[11:7];          // 目标寄存器：指令[11:7]
assign funct3 = ins[14:12];     // funct3：指令[14:12]
assign dis = ins[30];           // funct7判别位：指令[30]

// I-type/S-type/B-type指令的12位立即数
// S-type的立即数由两部分组成：[31:25]和[11:7]
// B-type的立即数也使用相同的字段，但需要重新排列
assign imm12 = {ins[31], ins[7], ins[30:25], ins[11:8]};

// U-type/J-type指令的20位立即数
assign imm20 = {ins[31], ins[19:12], ins[20], ins[30:21]};

endmodule
```

### 5. 控制单元(ControlUnit2.v)

根据操作码产生各种控制信号，协调CPU内部各部件工作。

```verilog
`timescale 1ns / 1ps

// 控制单元模块
module ControlUnit(
    input [6:0] opcode,          // 7位操作码
    input [2:0] funct3,          // 3位功能码
    input funct7,                // 功能码扩展位(指令[30])
    input condition,             // 条件判断结果
    
    output reg [1:0] pcSourceCode,  // PC来源选择: 00=PC+4, 01=条件分支, 10=JAL, 11=JALR
    output reg regWe,            // 寄存器写使能
    output reg memWe,            // 数据存储器写使能
    output reg [3:0] aluOpCode,  // ALU操作码
    output reg bIsImm,           // ALU输入B选择: 1=立即数, 0=寄存器值
    output reg bIs20bImm,        // 立即数选择: 1=20位立即数, 0=12位立即数
    output reg regDataIsFromMem, // 寄存器写入数据选择: 1=来自存储器, 0=来自ALU
    output reg regDataIsFromPC4  // 寄存器写入数据选择: 1=来自PC+4(JAL指令)
);

// RISC-V RV32I 指令集常量定义
localparam R_TYPE = 7'b0110011; // R型: 寄存器-寄存器运算(ADD, SUB, AND, OR等)
localparam I_TYPE = 7'b0010011; // I型: 立即数运算(ADDI, ANDI, ORI等)
localparam LOAD   = 7'b0000011; // 加载指令: LW, LH, LB等
localparam S_TYPE = 7'b0100011; // S型: 存储指令(SW, SH, SB等)
localparam B_TYPE = 7'b1100011; // B型: 条件分支指令(BEQ, BNE, BLT等)
localparam LUI    = 7'b0110111; // U型: 高位立即数加载(LUI)
localparam AUIPC  = 7'b0010111; // U型: PC相对地址计算(AUIPC)
localparam JAL    = 7'b1101111; // J型: 跳转并链接(JAL)
localparam JALR   = 7'b1100111; // I型: 寄存器跳转并链接(JALR)

// ALU操作码常量定义
localparam ALU_ADD  = 4'b0000;  // 加法运算
localparam ALU_SUB  = 4'b0001;  // 减法运算
localparam ALU_AND  = 4'b0010;  // 按位与
localparam ALU_OR   = 4'b0011;  // 按位或
localparam ALU_XOR  = 4'b0100;  // 按位异或
localparam ALU_SLL  = 4'b0101;  // 逻辑左移
localparam ALU_SRL  = 4'b0110;  // 逻辑右移
localparam ALU_SRA  = 4'b0111;  // 算术右移
localparam ALU_EQ   = 4'b1000;  // 相等比较(用于BEQ)
localparam ALU_SLT  = 4'b1001;  // 有符号小于比较(用于BLT)
localparam ALU_ULT  = 4'b1010;  // 无符号小于比较(用于BLTU)
localparam ALU_LUI  = 4'b1011;  // LUI操作
localparam ALU_JAL  = 4'b1100;  // JAL操作(PC相对地址计算)

// 根据指令类型生成相应控制信号
always @(*) begin
    // 默认值设置，最安全的默认状态(相当于NOP指令)
    pcSourceCode      = 2'b00;   // PC顺序执行，PC = PC + 4
    regWe             = 1'b0;    // 禁用寄存器写入
    memWe             = 1'b0;    // 禁用存储器写入
    aluOpCode         = ALU_ADD; // 默认ALU执行加法
    bIsImm            = 1'b0;    // 默认ALU输入B使用寄存器值
    bIs20bImm         = 1'b0;    // 默认使用12位立即数
    regDataIsFromMem  = 1'b0;    // 默认写入数据来自ALU运算结果
    regDataIsFromPC4  = 1'b0;    // 默认写入数据不来自PC+4

    // 根据操作码设置相应的控制信号
    case (opcode)
        R_TYPE: begin           // R型指令：寄存器-寄存器运算
            regWe = 1'b1;        // 使能寄存器写入
            // 根据funct3和funct7确定具体的ALU操作
            case (funct3)
                3'b000: aluOpCode = funct7 ? ALU_SUB : ALU_ADD; // ADD/SUB(根据funct7[5]区分)
                3'b001: aluOpCode = ALU_SLL;  // SLL(逻辑左移)
                3'b010: aluOpCode = ALU_SLT;  // SLT(有符号比较)
                3'b011: aluOpCode = ALU_ULT;  // SLTU(无符号比较)
                3'b100: aluOpCode = ALU_XOR;  // XOR(按位异或)
                3'b101: aluOpCode = funct7 ? ALU_SRA : ALU_SRL; // SRL/SRA(根据funct7[5]区分)
                3'b110: aluOpCode = ALU_OR;   // OR(按位或)
                3'b111: aluOpCode = ALU_AND;  // AND(按位与)
            endcase
        end
        
        I_TYPE: begin           // I型指令：立即数运算
            regWe = 1'b1;        // 使能寄存器写入
            bIsImm = 1'b1;       // ALU输入B使用12位立即数
            case (funct3)
                3'b000: aluOpCode = ALU_ADD;  // ADDI(立即数加法)
                3'b001: aluOpCode = ALU_SLL;  // SLLI(立即数逻辑左移)
                3'b010: aluOpCode = ALU_SLT;  // SLTI(有符号立即数比较)
                3'b011: aluOpCode = ALU_ULT;  // SLTIU(无符号立即数比较)
                3'b100: aluOpCode = ALU_XOR;  // XORI(立即数异或)
                3'b101: aluOpCode = funct7 ? ALU_SRA : ALU_SRL; // SRLI/SRAI
                3'b110: aluOpCode = ALU_OR;   // ORI(立即数或)
                3'b111: aluOpCode = ALU_AND;  // ANDI(立即数与)
            endcase
        end
        
        LOAD: begin             // 加载指令(LW等)
            regWe = 1'b1;        // 使能寄存器写入
            bIsImm = 1'b1;       // ALU输入B使用12位立即数(作为地址偏移量)
            regDataIsFromMem = 1'b1; // 写入数据来自数据存储器
            aluOpCode = ALU_ADD; // ALU操作为有效地址计算(地址+偏移)
        end
        
        S_TYPE: begin           // 存储指令(SW等)
            bIsImm = 1'b1;       // ALU输入B使用12位立即数(作为地址偏移量)
            memWe = 1'b1;        // 使能存储器写入
            aluOpCode = ALU_ADD; // ALU操作为有效地址计算(地址+偏移)
        end
        
        B_TYPE: begin           // 条件分支指令
            // 根据条件判断结果决定是否跳转，否则顺序执行
            pcSourceCode = {1'b0, condition}; // 01=条件跳转，00=顺序执行
            // 设置ALU比较操作
            case (funct3)
                3'b000: aluOpCode = ALU_EQ;   // BEQ(相等判断)
                3'b001: aluOpCode = ALU_EQ;   // BNE(不等判断，需要取反)
                3'b100: aluOpCode = ALU_SLT;  // BLT(有符号小于)
                3'b101: aluOpCode = ALU_SLT;  // BGE(有符号大于等于，需要取反)
                3'b110: aluOpCode = ALU_ULT;  // BLTU(无符号小于)
                3'b111: aluOpCode = ALU_ULT;  // BGEU(无符号大于等于，需要取反)
            endcase
        end
        
        LUI: begin              // LUI指令：加载高位立即数
            regWe = 1'b1;        // 使能寄存器写入
            bIs20bImm = 1'b1;    // 使用20位立即数
            aluOpCode = ALU_LUI; // ALU执行LUI操作(直接传送立即数)
        end
        
        AUIPC: begin            // AUIPC指令：PC相对地址计算
            regWe = 1'b1;        // 使能寄存器写入
            bIs20bImm = 1'b1;    // 使用20位立即数
            aluOpCode = ALU_ADD; // ALU执行加法(PC + 立即数)
        end
        
        JAL: begin              // JAL指令：跳转并链接
            regWe = 1'b1;        // 使能寄存器写入(写入返回地址)
            bIs20bImm = 1'b1;    // 使用20位立即数(作为跳转偏移量)
            regDataIsFromPC4 = 1'b1; // 写入数据为PC+4(返回地址)
            aluOpCode = ALU_JAL; // ALU执行跳转地址计算
            pcSourceCode = 2'b10; // JAL跳转
        end
        
        JALR: begin             // JALR指令：寄存器跳转并链接
            regWe = 1'b1;        // 使能寄存器写入
            bIsImm = 1'b1;       // 使用12位立即数
            regDataIsFromPC4 = 1'b1; // 写入数据为PC+4
            aluOpCode = ALU_ADD; // ALU执行跳转地址计算(rs1 + 立即数)
            pcSourceCode = 2'b11; // JALR跳转
        end
        
        // 默认情况保持默认值(相当于NOP指令)
        default: begin
            // 控制信号保持默认值
        end
    endcase
end

endmodule
```

### 6. 算术逻辑单元(alu.v)

执行算术运算、逻辑运算、移位操作和比较操作。

```verilog
`timescale 1ns / 1ps

// 算术逻辑单元模块
module alu(
    input [31:0] dataA,        // 输入A(通常来自寄存器rs1)
    input [31:0] dataB,        // 输入B(来自寄存器rs2或立即数)
    input [3:0] opcode,        // ALU操作码
    output reg [31:0] result,  // 32位运算结果
    output reg con             // 条件判断结果(用于分支指令)
);

// ALU操作码定义
localparam 
    ALU_ADD  = 4'b0000,  // 加法运算(add, addi, lw, sw, jal等)
    ALU_SUB  = 4'b0001,  // 减法运算(sub)
    ALU_AND  = 4'b0010,  // 按位与(and, andi)
    ALU_OR   = 4'b0011,  // 按位或(or, ori)
    ALU_XOR  = 4'b0100,  // 按位异或(xor, xori)
    ALU_SLL  = 4'b0101,  // 逻辑左移(sll, slli)
    ALU_SRL  = 4'b0110,  // 逻辑右移(srl, srli)
    ALU_SRA  = 4'b0111,  // 算术右移(sra, srai)
    ALU_EQ   = 4'b1000,  // 相等比较(beq)
    ALU_SLT  = 4'b1001,  // 有符号小于比较(slt, slti, blt)
    ALU_ULT  = 4'b1010,  // 无符号小于比较(sltu, sltiu, bltu)
    ALU_LUI  = 4'b1011,  // 加载高位立即数(lui)
    ALU_JAL  = 4'b1100;  // 跳转地址计算(jal)

// 根据操作码执行相应运算
always @(*) begin
    // 默认运算值
    con = 0;     // 条件判断默认为0(不满足条件)
    result = 0;  // 运算结果默认为0
    
    case(opcode)
        // ================= 算术运算 =================
        ALU_ADD: begin  // 加法运算
            result = dataA + dataB;  // 32位加法
            // 应用指令：add, addi, lw, sw, jal, auipc等
            // lw/sw指令中用于计算有效地址(地址 + 偏移)
            // jal指令中用于计算跳转目标地址(PC + 偏移)
        end
        
        ALU_SUB: begin  // 减法运算
            result = dataA - dataB;  // 32位减法
            // 应用指令：sub
        end
        
        // ================= 逻辑运算 =================
        ALU_AND: begin  // 按位与
            result = dataA & dataB;  // 按位与运算
            // 应用指令：and, andi
        end
        
        ALU_OR: begin   // 按位或
            result = dataA | dataB;  // 按位或运算
            // 应用指令：or, ori
        end
        
        ALU_XOR: begin  // 按位异或
            result = dataA ^ dataB;  // 按位异或运算
            // 应用指令：xor, xori
        end
        
        // ================= 移位运算 =================
        ALU_SLL: begin  // 逻辑左移
            // RISC-V规范要求移位位数取dataB的低5位(0-31位)
            result = dataA << dataB[4:0];  // 左移，低位补0
            // 应用指令：sll, slli
        end
        
        ALU_SRL: begin  // 逻辑右移
            result = dataA >> dataB[4:0];  // 右移，高位补0
            // 应用指令：srl, srli
        end
        
        ALU_SRA: begin  // 算术右移
            // 使用系统函数实现符号位扩展移位
            result = $signed(dataA) >>> dataB[4:0];
            // 应用指令：sra, srai
        end
        
        // ================= 比较运算(用于分支指令) =================
        ALU_EQ: begin   // 相等比较
            con = (dataA == dataB);  // 条件判断，相等时置1
            result = 0;              // 结果此处未使用
            // 应用指令：beq(相等时跳转)
        end
        
        ALU_SLT: begin  // 有符号小于比较
            con = ($signed(dataA) < $signed(dataB));  // 有符号数值比较
            result = 0;
            // 应用指令：slt, slti, blt(有符号小于时跳转)
        end
        
        ALU_ULT: begin  // 无符号小于比较
            con = (dataA < dataB);  // 无符号数值比较
            result = 0;
            // 应用指令：sltu, sltiu, bltu(无符号小于时跳转)
        end
        
        // ================= 特殊运算 =================
        ALU_LUI: begin  // 加载高位立即数
            result = dataB << 12;  // 将20位立即数放到寄存器的高20位，低12位清零
            // 应用指令：lui(加载高位立即数)
            // 功能：将20位立即数放到目标寄存器的高20位，低12位置0
        end
        
        ALU_JAL: begin  // 跳转地址计算(与ADD相同，但用途明确)
            result = dataA + dataB;  // PC相对地址计算
            // 应用指令：jal(跳转并链接)
            // 注意实际与ALU_ADD相同，但在此处处理是为了明确用途
        end
        
        // ================= 默认运算 =================
        default: begin
            result = 32'b0;  // 未知操作码时结果为0
            con = 1'b0;      // 条件判断为0
            // 全部穷举，防止未知操作码导致不可预知的行为
        end
    endcase
end

endmodule
```

### 7. 寄存器堆(RegFiles.v)

包含32个32位通用寄存器，支持同时读取两个寄存器和写入一个寄存器。

```verilog
`timescale 1ns / 1ps

// 寄存器文件模块
module RegFiles(
    input clk,               // 全局时钟信号
    input [4:0] raddr1,      // 读端口1地址(rs1寄存器地址)
    output [31:0] rdata1,    // 读端口1数据(rs1寄存器值)
    input [4:0] raddr2,      // 读端口2地址(rs2寄存器地址)
    output [31:0] rdata2,    // 读端口2数据(rs2寄存器值)
    input [4:0] waddr,       // 写端口地址(rd寄存器地址)
    input we,                // 写使能信号，高电平有效
    input [31:0] wdata       // 写入数据(要写入寄存器的数据)
);

// ========================= 寄存器存储阵列 =========================
// RISC-V RV32I架构包含32个32位通用寄存器
// 注意：regs[0]未使用，因为x0寄存器硬连线为0
reg [31:0] regs [1:31];   // 31个32位寄存器数组，索引1-31对应x1-x31
    
// ========================= 寄存器初始化 =========================
integer i;
initial begin
    // 上电时将所有寄存器初始化为0
    for (i = 1; i < 32; i = i + 1) 
        regs[i] = 32'b0;
end

// ========================= 读端口逻辑 =========================
// 读端口1：异步读取，地址变化时立即输出数据
// RISC-V规范规定x0寄存器始终返回0
assign rdata1 = (raddr1 == 5'b00000) ? 32'b0 :   // 读取x0寄存器时返回0
                regs[raddr1];                    // 读取x1-x31寄存器时返回存储值
    
// 读端口2：异步读取，地址变化时立即输出数据
assign rdata2 = (raddr2 == 5'b00000) ? 32'b0 :   // 读取x0寄存器时返回0
                regs[raddr2];                    // 读取x1-x31寄存器时返回存储值
    
// ========================= 时序逻辑写端口 =========================
// 写端口在时钟上升沿同步写入
always @(posedge clk) begin
    if (we) begin                    // 写使能有效
        if (waddr != 5'b00000) begin  // 目标寄存器不是x0(x0不能写入)
            regs[waddr] <= wdata;     // 将数据写入指定寄存器
        end
        // 如果waddr==0，则忽略写入操作，x0寄存器始终保持为0
    end
end

endmodule
```

### 8. 指令存储器(rom.v)

只读存储器，用于存储程序指令。

```verilog
`timescale 1ns / 1ps

module rom(
    input [7:0] addr,
    output [31:0] data
);
    reg[31:0] insData[0:255];
    initial
        $readmemh("insData.txt", insData);
    assign data = insData[addr];
endmodule
```

### 9. 数据存储器(ram.v)

可读写存储器，用于存储程序运行时的数据。

```verilog
`timescale 1ns / 1ps

module ram(
    input clk,             // 时钟信号
    input we,              // 写使能 (1 = 写入, 0 = 读取)
    input [7:0] addr,      // 8位地址线 (256个32位存储单元)
    input [31:0] data_in,  // 32位写入数据
    output [31:0] data_out // 32位读出数据
);
    // 定义256个32位的存储单元
    reg [31:0] memory [0:255];
    
    // 同步写入逻辑
    always @(posedge clk) begin
        if (we) begin
            memory[addr] <= data_in; // 在时钟上升沿将数据写入内存
        end
    end
    
    // 异步读取逻辑
    assign data_out = memory[addr];  // 地址变化时立即输出数据
endmodule
```

## 总结

本项目实现了完整的RISC-V单周期CPU，能够执行基本的RV32I指令集。各模块协同工作，形成了完整的指令执行流水线.
