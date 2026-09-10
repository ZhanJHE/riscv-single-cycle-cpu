`timescale 1ns / 1ps

module ram(
    input clk,             // 时钟信号
    input we,              // 写使能 (1 = 写入, 0 = 读取)
    input [7:0] addr,      // 8位地址线 (256个32位存储单元)
    input [31:0] data_in,  // 32位输入数据
    output [31:0] data_out // 32位输出数据
);
    // 定义256个32位的存储单元
    reg [31:0] memory [0:255];
    
//    // 初始化存储器（可选）
//    // 在实际FPGA中，可以使用$readmemh或$readmemb初始化
//    initial begin
//        // 示例：将所有存储单元初始化为0
//        for (integer i = 0; i < 256; i = i + 1) begin
//            memory[i] = 32'h00000000;
//        end
        
//        // 或者使用系统函数初始化（需要外部文件）
//        // $readmemh("ram_init.hex", memory);
//    end
    
    // 同步写操作
    always @(posedge clk) begin
        if (we) begin
            memory[addr] <= data_in; // 在时钟上升沿写入数据
        end
    end
    
    // 异步读操作
    assign data_out = memory[addr];  // 地址变化时立即输出数据
endmodule