# RISC-V 单周期 CPU

基于 Verilog 实现的 RISC-V 32 位单周期 CPU，开发与仿真工具为 Xilinx Vivado，
目标器件为 Artix-7 FPGA。

名词解释：

- 单周期 CPU：每条指令在一个时钟周期内完成取指、译码、执行、访存、写回全部
  操作的处理器实现方式。结构简单，便于教学，代价是时钟频率低于流水线实现。
- RV32I：RISC-V 的 32 位基础整数指令集，本项目的指令集来源。
- 黄金值：预先算好的期望结果序列（本项目中是 PC 和寄存器 x1/x2/x3 的值），
  仿真时与实际值逐周期比对，用于自动判对错。

## 指令支持

设计目标 23 条指令，自检程序覆盖其中 22 种（`jalr` 未覆盖）：

| 类型 | 含义 | 指令 |
|---|---|---|
| R 型 | 寄存器对寄存器运算 | add, sub, xor, or, and, sll, srl, sra |
| I 型 | 立即数运算 | addi, andi, ori, xori, slli, srli, srai |
| 加载 | 从数据存储器读字 | lw |
| S 型 | 向数据存储器写字 | sw |
| B 型 | 条件分支 | beq, blt, bltu |
| U 型 | 高位立即数 | lui |
| J 型 | 无条件跳转 | jal, jalr |

各指令的编码、立即数拼装方式与控制真值表见
[docs/03 · 指令集参考](docs/03-instruction-set.md)。

## 当前状态

RTL 已完成（2026-09）：控制单元按标准 RV32I 译码，数据通路三处多路选择器
（b 操作数、写回数据、下地址）补齐，U/J 型立即数实现，RAM 已接入工程。
剩余工作：行为仿真验证、综合与上板，由使用者执行，见
[docs/06 · 现状与开发路线](docs/06-status-and-roadmap.md)。

## 项目结构

```
riscv-single-cycle-cpu/
├── sCPULab.xpr              # Vivado 工程文件
├── insData.txt              # 自检程序机器码（26 条指令，ROM 初始化文件）
├── docs/                    # 项目文档集（索引见 docs/README.md）
├── testcase/                # 自检用黄金值（pc/x1/x2/x3 各 26 行）
│   ├── pc.txt / x1.txt / x2.txt / x3.txt
├── riscv_cpu_documentation.html  # 早期逐模块说明（保留参考）
├── sCPULab.srcs/            # 源代码目录
│   ├── cpu_*.mmd, cpu_structure.puml  # 架构图源（mermaid/PlantUML）
│   ├── sources_1/
│   │   ├── new/
│   │   │   ├── top.v        # 仿真顶层（CPU + ROM + RAM）
│   │   │   └── ram.v        # 数据存储器（256×32b）
│   │   └── imports/
│   │       ├── new/
│   │       │   ├── CPU.v           # 数据通路（含三处多路选择器）
│   │       │   ├── ControlUnit2.v  # 控制单元（主译码器）
│   │       │   ├── ID.v            # 指令译码器
│   │       │   └── alu.v           # 运算单元
│   │       └── imports/
│   │           ├── new/
│   │           │   ├── pc.v     # 程序计数器
│   │           │   └── rom.v    # 指令存储器（64×32b）
│   │           └── riscv/...
│   │               └── RegFiles.v  # 寄存器堆（导入路径过深，建议整理）
│   └── sim_1/
│       ├── imports/new/sim.v       # 波形观察 testbench
│       └── new/
│           ├── InsBenchmark.v      # 自检 testbench（当前仿真顶层）
│           ├── testcase.v          # 黄金值加载模块
│           └── TestBench_CU.v      # 控制单元单独激励
└── README.md                # 本文档
```

## 开发环境

| 项 | 值 |
|---|---|
| 工具 | Xilinx Vivado 2017.4（仿真器 XSim） |
| 器件 | xc7a35tcsg324-1（Artix-7） |
| 语言 | Verilog-2001 |

## 快速开始

### 获取代码

```bash
git clone https://github.com/ZhanJHE/riscv-single-cycle-cpu.git
```

### 运行仿真

1. 启动 Vivado 2017.4，打开 `sCPULab.xpr`。
2. Flow Navigator → SIMULATION → Run Simulation → Run Behavioral Simulation。
   当前仿真顶层为 `InsBenchmark`（自检），可切换为 `sim` 观察波形。
3. 预期结果：Tcl Console 依次输出 25 条 success 消息，最后输出
   `Congratulations! all instructions passed the test!!!`，约 275ns 结束。
   若失败，按 [docs/05 · 检查机制](docs/05-verification.md) 的时刻与步骤
   对应关系定位。

### 综合与上板

尚未实施。需要的准备工作（ROM 初始化方式、引脚约束文件）见
[docs/06 · 步骤 6](docs/06-status-and-roadmap.md)。

## 文档

| 文档 | 内容 |
|---|---|
| [docs/README.md](docs/README.md) | 文档索引与阅读顺序 |
| [docs/01 · 项目概览](docs/01-overview.md) | 现状、环境、目录结构、编码注意事项 |
| [docs/02 · 架构与数据通路](docs/02-architecture.md) | 模块连接、控制信号、ALU 操作码表、存储组织 |
| [docs/03 · 指令集参考](docs/03-instruction-set.md) | 指令格式、编码、控制真值表 |
| [docs/04 · 模块参考](docs/04-module-reference.md) | 逐模块端口表与已知问题 |
| [docs/05 · 仿真与验证指南](docs/05-verification.md) | testbench 用法、自检程序反汇编、失败定位 |
| [docs/06 · 现状与开发路线](docs/06-status-and-roadmap.md) | 已完成项、剩余步骤、验收标准 |
| [docs/07 · 设计文档](docs/07-design.md) | 设计目标、执行过程讲解、设计决策与理由、术语表 |

早期 HTML 说明 `riscv_cpu_documentation.html` 保留作参考，内容以 `docs/`
下的 Markdown 为准。

## 测试程序

`insData.txt` 是 26 条指令的自检程序，由 `InsBenchmark.v` 在每个时钟周期把
PC 和 x1/x2/x3 与 `testcase/` 下的黄金值比对，全部一致时输出
`Congratulations!`。程序覆盖 22 种指令，包含两类分支情况（跳转与不跳转）、
一次向回跳转，以及 sw 写入后 lw 读回的存储器检查。逐条反汇编与期望值见
[docs/05](docs/05-verification.md)。

## 注意事项

1. `.v` 源文件为 GBK 编码（含中文注释）。编辑时选择 GB18030 编码打开，
   否则注释显示乱码。`docs/` 与本 README 为 UTF-8 编码。
2. `rom.v` 与 `testcase.v` 用相对路径 `../../../../` 读数据文件，只在 XSim
   默认运行目录下成立，且不能用于综合。
3. 本项目为课程实验性质，未做时序收敛与板级调试。

## 作者与许可

- 实验课程：计算机组成原理
- 开发时间：2023-2025
- 本项目仅供学习和研究使用。

## 参考资源

- [RISC-V 官方规范](https://riscv.org/technical/specifications/)
- 《RISC-V spec》与《RISC-V-Reader（中文版）》为课程参考资料（未随仓库分发）
