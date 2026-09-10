# RISC-V Single-Cycle CPU

一个基于 Verilog 实现的 RISC-V 单周期 CPU 实验项目（Vivado / FPGA）。

## 项目概述

本项目实现了一个 RISC-V 32 位单周期 CPU 的数据通路，包含以下核心组件：

- 程序计数器 (PC)
- 指令存储器 (ROM)
- 指令译码器 (ID)
- 控制单元 (ControlUnit)
- 算术逻辑单元 (ALU)
- 寄存器堆 (RegFiles)
- 数据存储器 (RAM)

**指令支持**：设计目标 23 条指令（含 `jalr`）；自检程序 `insData.txt` 覆盖其中
22 种。

**当前状态（2026-09 更新）**：全部功能缺陷已修复——控制单元已按标准 RV32I
完整译码、CPU 数据通路三处多路选择器已补完、U/J 型立即数已实现、RAM 已接入
并注册进工程；黄金文件经核验正确。**行为仿真验证与综合/上板由使用者执行**
（详见 [docs/06 · 现状与开发路线](docs/06-status-and-roadmap.md)）。

## 支持的指令

### R型指令
- add, sub, xor, or, and, sll, srl, sra

### I型指令
- andi, xori, ori, slli, srli, srai, lw, addi, jalr

### B型指令
- beq, blt, bltu

### S型指令
- sw

### U型指令
- lui

### J型指令
- jal

各指令的编码、立即数拼装与控制真值表见
[docs/03 · 指令集参考](docs/03-instruction-set.md)。

## 项目结构

```
riscv-single-cycle-cpu/
├── sCPULab.xpr              # Vivado项目文件
├── insData.txt              # 自检程序机器码（26条指令，ROM初始化文件）
├── docs/                    # 项目文档集（中文，含架构/指令集/验证/路线）
├── testcase/                # InsBenchmark黄金值（pc/x1/x2/x3各26行）
│   ├── pc.txt / x1.txt / x2.txt / x3.txt
├── riscv_cpu_documentation.html  # 早期逐模块说明（保留参考）
├── sCPULab.srcs/            # 源代码目录
│   ├── sources_1/
│   │   ├── new/
│   │   │   ├── top.v        # 仿真顶层模块（CPU+ROM）
│   │   │   └── ram.v        # 数据存储器（已完成并接入）
│   │   └── imports/
│   │       ├── new/
│   │       │   ├── CPU.v           # CPU数据通路（2026-09补完）
│   │       │   ├── ControlUnit2.v  # 控制单元（完整译码）
│   │       │   ├── ID.v            # 指令译码器
│   │       │   └── alu.v           # 算术逻辑单元
│   │       └── imports/
│   │           ├── new/
│   │           │   ├── pc.v     # 程序计数器
│   │           │   └── rom.v    # 指令存储器
│   │           └── riscv/...
│   │               └── RegFiles.v  # 寄存器堆（导入路径过深，建议整理）
│   └── sim_1/
│       ├── imports/new/sim.v       # 波形观察testbench
│       └── new/
│           ├── InsBenchmark.v      # 自检testbench（当前仿真顶层）
│           ├── testcase.v          # 黄金值加载模块
│           └── TestBench_CU.v      # 控制单元单独激励（已加入工程）
└── README.md                # 本文档
```

## 开发环境

- **工具**: Xilinx Vivado 2017.4
- **目标器件**: xc7a35tcsg324-1 (Artix-7)
- **语言**: Verilog HDL（源文件含中文注释，为 **GBK 编码**）

## 核心模块说明

### CPU.v
CPU 数据通路模块，例化并连接各子模块。含 b 操作数、写回数据、下地址
三处选择器与 RAM 接口（2026-09 补完）。

### top.v
仿真顶层模块，连接 CPU、指令存储器 ROM 与数据存储器 RAM。

### pc.v
程序计数器模块，存储当前指令地址，复位时初始化为 0x00400000。

### rom.v
指令存储器模块（64×32b），`$readmemh` 加载 `insData.txt`，异步读取。

### ID.v
指令译码器模块，解析 RISC-V 指令格式的各个字段。
I/S/B/U/J 型立即数均已实现。

### ControlUnit2.v
控制单元模块，按标准 RV32I 译码生成各种控制信号（2026-09 补完），
真值表见 [docs/03](docs/03-instruction-set.md)。

### alu.v
算术逻辑单元模块，执行 16 种不同的算术、逻辑和移位运算，
并输出分支条件 `con`。

### RegFiles.v
寄存器堆模块，32 个 32 位通用寄存器（x0 恒 0），双端口读、单端口同步写。

### ram.v
数据存储器模块（256×32b），同步写、异步读。已接入 CPU 并注册进工程。

## 快速开始

### 获取代码

```bash
git clone https://github.com/ZhanJHE/riscv-single-cycle-cpu.git
```

### 在 Vivado 中打开项目

1. 启动 Vivado 2017.4
2. 打开项目文件 `sCPULab.xpr`
3. 在 Sources 面板中查看源代码

### 运行仿真

1. Flow Navigator → Run Simulation → Run Behavioral Simulation
   （当前顶层为 `InsBenchmark` 自检；可切换为 `sim` 观察波形）
2. 自检消息输出在 Tcl Console；详细机制与预期输出见
   [docs/05 · 仿真与验证指南](docs/05-verification.md)

> ✅ RTL 已补完（2026-09），黄金文件已核验正确。直接运行自检应能依次输出
> 25 条 success 消息并以 `Congratulations!` 结束；若有失败，按
> [docs/05 · 检查机制](docs/05-verification.md) 的时刻→动态步映射定位。

## 文档

完整文档集（架构、指令集、模块参考、验证指南、开发路线）：
**[docs/README.md](docs/README.md)**

早期逐模块 HTML 说明：[riscv_cpu_documentation.html](riscv_cpu_documentation.html)
（内容以 docs/ 下的 Markdown 为准）

## 测试程序

项目包含一个 26 条指令的自检程序 `insData.txt`（由 `InsBenchmark.v` 配合
`testcase/` 黄金值逐周期验证），覆盖 22 种指令：

- 逻辑运算指令（ori/xori/andi/and/or/xor）
- 算术运算指令（addi/add/sub/lui）
- 移位指令（slli/srli/srai/sll/srl/sra）
- 比较与分支指令（beq/blt/bltu，含跳转与不跳转两种情况）
- 跳转指令（jal，程序末尾自循环）
- 内存访问指令（sw/lw）

逐条反汇编与期望值见
[docs/05 · 自检程序反汇编表](docs/05-verification.md)。

## 注意事项

1. 本项目是实验性质的单周期 CPU 实现，RTL 已于 2026-09 补完（见
   [docs/06 · 现状与开发路线](docs/06-status-and-roadmap.md)），
   仿真验证与综合上板由使用者执行
2. `.v` 源文件为 GBK 编码，编辑时注意选择正确编码
3. `rom.v`/`testcase.v` 通过相对路径 `../../../../` 读取数据文件，
   仅适用于 XSim 默认运行目录，且不能用于综合
4. 建议在仿真环境中验证所有功能后再做综合

## 作者

- 实验课程：计算机组成原理
- 开发时间：2023-2025

## 许可证

本项目仅供学习和研究使用。

## 参考资源

- [RISC-V官方规范](https://riscv.org/technical/specifications/)
- 《RISC-V spec》与《RISC-V-Reader（中文版）》为课程参考资料（纸质/PDF，未随仓库分发）
