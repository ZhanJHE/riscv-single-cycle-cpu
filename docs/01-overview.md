# 01 · 项目概览与环境

## 1. 项目是什么

本项目是计算机组成原理课程的 FPGA 实验工程：用 Verilog HDL 在 Xilinx Vivado 中实现一个
**RISC-V 32 位（RV32I 子集）单周期 CPU**。

- **设计目标**：23 条指令助记符（`add` `sub` `xor` `or` `and` `sll` `srl` `sra`、
  `andi` `xori` `ori` `slli` `srli` `srai` `lw` `addi` `jalr`、`beq` `blt` `bltu`、
  `sw`、`lui`、`jal`），其中 `jalr` 无自检程序覆盖，属设计目标。
- **自检程序**（`insData.txt`，26 条指令）实际覆盖 **22 种**助记符。
- **当前状态（2026-09 更新）**：全部功能缺陷已修复——控制单元已按标准 RV32I
  完整译码、数据通路三处多路选择器已补完、U/J 型立即数已实现、RAM 已接入并
  注册进工程；自检所需条件齐备，**行为仿真验证与综合/上板由使用者执行**
  （无引脚约束文件）。

> 如实了解"哪些能用、哪些是半成品"，请先阅读
> [06 · 现状与开发路线](06-status-and-roadmap.md)。

## 2. 现状一览

| 组件 | 状态 | 说明 |
|---|---|---|
| `pc.v` 程序计数器 | ✅ 完成 | 同步复位，复位值 `0x00400000` |
| `rom.v` 指令存储器 | ✅ 完成 | 64×32b，`$readmemh` 加载 `insData.txt` |
| `ID.v` 指令译码器 | ✅ 完成 | I/S/B/U/J 型立即数均已实现 |
| `alu.v` ALU | ✅ 完成 | 16 种 4bit 操作码 + 分支条件输出 `con` |
| `RegFiles.v` 寄存器堆 | ✅ 完成 | 32×32b，`x0` 恒 0 |
| `ram.v` 数据存储器 | ✅ 完成并已接入 | 256×32b，同步写异步读；已连线并注册进工程 |
| `ControlUnit2.v` 控制单元 | ✅ 完成 | 按标准 RV32I 译码（2026-09 实施） |
| `CPU.v` 数据通路 | ✅ 完成 | 三处 mux 与 `bIs20bImm` 接线已修复，含 RAM 接口（2026-09 实施） |
| `top.v` 仿真顶层 | ✅ 完成 | CPU + ROM + RAM |
| 行为仿真自检 | ⏳ 待验证 | 条件已齐备，**由使用者在 Vivado 中运行**（见 [05](05-verification.md)） |
| 综合 / 实现 / 上板 | ❌ 未开始 | `synth_1` 目录为空，无 `.xdc` 约束（由使用者执行） |

## 3. 开发环境

| 项 | 值 |
|---|---|
| 工具 | Xilinx Vivado **2017.4**（仿真器 XSim） |
| 目标器件 | `xc7a35tcsg324-1`（Artix-7，35T，CSG324 封装，速度等级 -1） |
| 语言 | Verilog-2001 |
| 工程文件 | `sCPULab.xpr`（双击或 File → Open Project 打开） |

## 4. 仓库实际目录结构

```
riscv-single-cycle-cpu/
├── sCPULab.xpr                    # Vivado 工程文件
├── insData.txt                    # 自检程序机器码（ROM 初始化，$readmemh 十六进制格式）
├── README.md                      # 项目简介（已随本文件集更新）
├── riscv_cpu_documentation.html   # 早期逐模块说明（保留作参考）
├── docs/                          # 本文档集
│   ├── README.md                  # 文档索引
│   ├── 01-overview.md             # 本文件
│   ├── 02-architecture.md         # 架构与数据通路
│   ├── 03-instruction-set.md      # 指令集参考
│   ├── 04-module-reference.md     # 模块参考
│   ├── 05-verification.md         # 仿真与验证指南
│   └── 06-status-and-roadmap.md   # 现状与开发路线
├── testcase/                      # InsBenchmark 黄金值（各 26 行十六进制）
│   ├── pc.txt                     # 期望 PC 序列
│   ├── x1.txt / x2.txt / x3.txt   # 期望 x1/x2/x3 序列（四个文件均已核验正确）
└── sCPULab.srcs/
    ├── sources_1/                 # 设计源文件
    │   ├── new/
    │   │   ├── top.v              # 仿真顶层：CPU + ROM + RAM
    │   │   └── ram.v              # 数据存储器（已完成并接入，已注册进工程）
    │   └── imports/
    │       ├── new/
    │       │   ├── CPU.v          # CPU 数据通路（2026-09 补完）
    │       │   ├── ControlUnit2.v # 控制单元（2026-09 完整译码）
    │       │   ├── ID.v           # 指令译码器
    │       │   └── alu.v          # 算术逻辑单元
    │       └── imports/
    │           ├── new/
    │           │   ├── pc.v       # 程序计数器
    │           │   └── rom.v      # 指令存储器
    │           └── riscv/
    │               └── register - ego/register.srcs/.../RegFiles.v
    │                              # 寄存器堆（导入路径嵌套 6 层，建议整理，见 06）
    └── sim_1/                     # 仿真源文件
        ├── imports/new/sim.v      # 波形观察 testbench（clk 20ns 周期）
        └── new/
            ├── InsBenchmark.v     # 自检 testbench（当前仿真顶层，clk 10ns 周期）
            ├── testcase.v         # 黄金值加载模块（供 InsBenchmark 比对）
            └── TestBench_CU.v     # 控制单元单独激励（已加入工程）
```

> 说明：`sCPULab.sim/`、`sCPULab.sim11/`、`sCPULab.cache/`、`sCPULab.runs/` 等为
> Vivado 自动生成的仿真/编译产物，已被 `.gitignore` 排除，不必手工维护；
> `_backup_before_fix/` 为 2026-09 修复 RTL 前的四个原始文件备份（确认无误后可删）。

## 5. 编码与路径注意事项（重要）

1. **源文件编码为 GBK**：所有 `.v` 文件含中文注释，以 GBK（GB18030）编码保存。
   - VS Code 打开时请选择 `GB18030` 编码，否则中文注释乱码；
   - 用 Git 等工具做 diff 时注意编码；
   - 本 `docs/` 文档集为 UTF-8 编码（Markdown 通用标准）。
2. **`$readmemh` 相对路径依赖仿真运行目录**：`rom.v` 用
   `../../../../insData.txt`、`testcase.v` 用 `../../../../testcase/*.txt`
   加载数据。该相对路径只在 XSim 默认运行目录
   （`sCPULab.sim*/sim_1/behav/xsim/`，上溯 4 级即工程根目录）下成立。
   更换仿真器（ModelSim/Questa 等）或改动目录层级都会导致加载失败。
3. **数据文件必须位于工程根目录**：`insData.txt` 与 `testcase/` 都在仓库根目录，
   移动它们会破坏仿真。

## 6. 历史沿革与工程杂项

- 工程曾位于 `G:\CS\new_lab5\sCPULab\`（`vivado.log` 中留有该路径记录），后迁移至
  当前位置。旧的 `.sim/` 产物中可能残留旧绝对路径，重新运行一次仿真即可刷新。
- `.xpr` 中的 `IPRepoPath` 指向一个已不存在的外部目录
  （`../../Verilog project/composition priciple/...`）。本工程未使用 IP，
  打开工程时的相关警告可以忽略；如需彻底清除见 [06 · 工程卫生](06-status-and-roadmap.md)。
- `InsBenchmark.v` 中有一条作者留言日期 `2023.9.10`，自检消息输出中会原样打印。

## 7. 下一步阅读

- 理解设计 → [02 · 架构与数据通路](02-architecture.md)
- 跑通仿真 → [05 · 仿真与验证指南](05-verification.md)
- 继续开发补完 CPU → [06 · 现状与开发路线](06-status-and-roadmap.md)
