# 04 · 模块参考

逐模块的端口表、行为与已知问题。路径均相对仓库根目录。
信号整体连接关系见 [02 · 架构与数据通路](02-architecture.md)。

> 所有 `.v` 文件为 **GBK 编码**（中文注释），编辑时注意，见
> [01 · 编码注意事项](01-overview.md)。

---

## 1. `pc.v` — 程序计数器

路径：`sCPULab.srcs/sources_1/imports/imports/new/pc.v`

| 端口 | 方向 | 位宽 | 说明 |
|---|---|---|---|
| `clk` | in | 1 | 时钟 |
| `rst` | in | 1 | 同步复位，高有效 |
| `nextaddr` | in | 32 | 下一 PC 值 |
| `addr` | out reg | 32 | 当前 PC |

行为：`posedge clk` 时 `rst=1` 则 `addr <= 32'h00400000`，否则 `addr <= nextaddr`。

- ✅ 已完成。
- 注意：没有写使能/暂停输入，每个时钟沿都更新（单周期 CPU 可接受）。
- 复位值 `0x00400000` 与 ROM 基址、自检黄金值中的 PC 序列一致。

## 2. `rom.v` — 指令存储器

路径：`sCPULab.srcs/sources_1/imports/imports/new/rom.v`

| 端口 | 方向 | 位宽 | 说明 |
|---|---|---|---|
| `addr` | in | 8 | 字索引（top 接 `pcAddr[9:2]`） |
| `data` | out | 32 | 指令字（异步组合读） |

- 容量 64×32b，`initial $readmemh("../../../../insData.txt", insData)`。
- ✅ 已完成。已知问题：
  - `$readmemh` 相对路径仅在 XSim 默认运行目录下成立（见 [01](01-overview.md)）；
    **该方式不能用于综合**——上板需改用 Vivado IP（Block Memory Generator +
    COE 文件）或其他初始化方案；
  - 未初始化的字（26 号以后）读出为 `x`，仿真中若 PC 越过程序末尾会看到 x 指令。

## 3. `ID.v` — 指令译码器

路径：`sCPULab.srcs/sources_1/imports/new/ID.v`

| 端口 | 方向 | 位宽 | 说明 |
|---|---|---|---|
| `ins` | in | 32 | 指令字 |
| `opcode` | out | 7 | `ins[6:0]` |
| `rd` | out | 5 | `ins[11:7]` |
| `funct3` | out | 3 | `ins[14:12]` |
| `rs1` | out | 5 | `ins[19:15]` |
| `rs2` | out | 5 | `ins[24:20]` |
| `funct7` | out | 1 | `ins[30]`（区分 add/sub、srl/sra 够用） |
| `imm12` | out | 12 | I/S/B 型立即数拼装（见下） |
| `imm20` | out | 20 | **当前无驱动**（U/J 待实现） |

`imm12` 按类型拼装（互斥的类型掩码相或）：

- I 型：`ins[31:20]`
- B 型：`{ins[31], ins[7], ins[30:25], ins[11:8]}`（imm[12]、imm[11]、imm[10:5]、imm[4:1]）
- S 型：`{ins[31:25], ins[11:7]}`

状态：

- ✅ I/S/B 立即数 ✅；**U 型与 J 型立即数已实现**（2026-09）：
  `U_type = (ins[6:0]==7'b0110111)`、`J_type = (ins[6:0]==7'b1101111)`，
  `imm20 = {20{U_type}}&ins[31:12] | {20{J_type}}&{ins[31],ins[19:12],ins[20],ins[30:21]}`。
  两者复用 20 位 `imm20` 端口，由 CPU 端按类型扩展/移位（`lui` 直用、
  `jal` 左移 1 位符号扩展）。

## 4. `ControlUnit2.v` — 控制单元（当前为桩）

路径：`sCPULab.srcs/sources_1/imports/new/ControlUnit2.v`

模块名：`ControlUnit`。

| 端口 | 方向 | 位宽 | 说明 |
|---|---|---|---|
| `opcode` / `funct3` / `funct7` / `condition` | in | 7/3/1/1 | 指令字段 + ALU 分支条件 |
| `pcSourceCode` | out | 2 | 下地址来源（00 顺序/01 条件分支/10 jal/11 jalr） |
| `regWe` / `memWe` | out | 1 | 寄存器堆 / RAM 写使能 |
| `aluOpCode` | out | 4 | ALU 操作 |
| `bIsImm` / `bIs20bImm` | out | 1 | b 操作数选择 |
| `regDataIsFromMem` / `regDataIsFromPC4` | out | 1 | 写回数据选择 |

- ✅ **已完整实现**（2026-09，替换了此前的常数桩）：`always @(*)` +
  `case(opcode)` 按标准 RV32I 译码，真值表与
  [03 · 控制真值表](03-instruction-set.md) 一致；顺带支持
  slt/sltu/slti/sltiu/bne/bge/bgeu 扩展指令。
- `condition` 输入由 CPU 中的下地址 mux 使用（`con ? addr_branch : addr4`），
  控制单元本身对分支无条件输出 `pcSourceCode=01`。
- 历史备注：旧版曾把所有输出写成常数（`aluOpCode=0011` 等），是
  [05 · 根因分析](05-verification.md) 中自检失败的直接原因。

## 5. `alu.v` — 算术逻辑单元

路径：`sCPULab.srcs/sources_1/imports/new/alu.v`

| 端口 | 方向 | 位宽 | 说明 |
|---|---|---|---|
| `dataA` / `dataB` | in | 32 | 操作数 a / b |
| `opcode` | in | 4 | 操作码 |
| `result` | out reg | 32 | 运算结果 |
| `con` | out reg | 1 | 分支条件（比较类操作有效） |

- ✅ 已完成：16 种操作（`0000`–`1111`），完整表见
  [02 · ALU 操作码表](02-architecture.md)。
- 细节：移位量取 `dataB[4:0]`；有符号比较用 `wire signed`；`1110`（jalr）
  清 bit0；`1111`（lui）把 `dataB` 左移 12 位——因此 **`lui` 时 b 选择器必须
  提供 20 位立即数**；`default` 分支输出 0。

## 6. `RegFiles.v` — 寄存器堆

路径：`sCPULab.srcs/sources_1/imports/imports/riscv/register - ego/.../RegFiles.v`
（导入路径嵌套 6 层，建议整理，见 [06 · 工程卫生](06-status-and-roadmap.md)）

| 端口 | 方向 | 位宽 | 说明 |
|---|---|---|---|
| `clk` | in | 1 | 时钟 |
| `raddr1` / `raddr2` | in | 5 | 读地址（对应 rs1/rs2） |
| `rdata1` / `rdata2` | out | 32 | 读数据（异步） |
| `waddr` / `wdata` | in | 5/32 | 写地址 / 写数据 |
| `we` | in | 1 | 写使能（posedge 同步写） |

- 32×32b；`regs[1:31]`（不存 x0）；`initial` 循环清零（XSim 生效）。
- `x0` 读端硬连线为 0；写 `x0` 被忽略。
- ✅ 已完成。已知问题：
  - 写保护条件写的是 `if(waddr != 4'b00000)` —— 5 位 `waddr` 与 **4 位字面量**
    比较。Verilog 会把字面量零扩展到 5 位，功能正确，但建议改成 `5'b00000`；
  - 异步读无"写透传"：同一时钟沿写入的数据要到下一周期才能读出
    （单周期 CPU 中写回发生在周期末尾，不影响正确性，但改流水线时要注意）。

## 7. `ram.v` — 数据存储器

路径：`sCPULab.srcs/sources_1/new/ram.v`

| 端口 | 方向 | 位宽 | 说明 |
|---|---|---|---|
| `clk` | in | 1 | 时钟 |
| `we` | in | 1 | 写使能（posedge 同步写） |
| `addr` | in | 8 | 字索引（256 个 32 位字） |
| `data_in` | in | 32 | 写数据 |
| `data_out` | out | 32 | 读数据（异步） |

- ✅ 模块本身已完成（初始化代码被注释掉，可按需启用）。
- ✅ **已接入**（2026-09）：已注册进 `.xpr` 的 sources_1，并在 `top.v` 中例化为
  `dataram`，经 `CPU` 的 `mem*` 端口连线；自检程序仅访问地址 0（`0(x0)`）。

## 8. `CPU.v` — CPU 数据通路

路径：`sCPULab.srcs/sources_1/imports/new/CPU.v`

| 端口 | 方向 | 位宽 | 说明 |
|---|---|---|---|
| `clk` / `rst` | in | 1 | 时钟 / 复位 |
| `pcAddr` | out | 32 | 当前 PC（送 ROM） |
| `insData` | in | 32 | 来自 ROM 的指令 |
| `memWe` | out | 1 | RAM 写使能 |
| `memAddr` | out | 8 | RAM 字地址（`= {2'b00, f[9:2]}`） |
| `memWdata` | out | 32 | RAM 写数据（`= rdata2`） |
| `memRdata` | in | 32 | RAM 读数据（内部 `mdata`） |

内部例化 `pc`、`ID`、`ControlUnit`、`RegFiles`、`alu`；内部信号清单见
[02 · 信号清单](02-architecture.md)。

✅ **已补完**（2026-09，替换了原三处 `//TODO:`）：

1. **b 操作数 mux**：`is20imm` → `imm20_exp={12'b0,imm20}`（lui，ALU 内再 <<12）；
   `isimm` → `imm12_exp`；否则 `rdata2`；
2. **写回数据 mux**：`isfm` → `mdata`（RAM 读数）；`ispc4` → `addr4=curraddr+4`；
   否则 `f`；
3. **下地址 mux**：`pcsource=01` 时 `con ? addr_branch : addr4`；`10` → `addr_jal`；
   `11` → `addr_jalr`；默认 `addr4`。其中
   `addr_branch = curraddr + {{19{imm12[11]}}, imm12, 1'b0}`（ID 的 B 型
   `imm12` = imm[12:1]，须左移 1 位）、
   `addr_jal = curraddr + {{11{imm20[19]}}, imm20, 1'b0}`、
   `addr_jalr = f & ~32'b1`；
4. **接线修复**：`bIs20bImm` 改接 1 位 wire `is20imm`，`imm20` 由 `ID.v` 驱动
   （修复了旧版把 1 位输出接到 20 位 wire 的宽度错配）；
5. **新增 RAM 接口端口**（见上表），`mdata = memRdata`。

`InsBenchmark` 依赖的实例名 `mycpu`/`myrf` 与信号 `t.addr` 均未改动。

## 9. `top.v` — 仿真顶层

路径：`sCPULab.srcs/sources_1/new/top.v`

| 端口 | 方向 | 位宽 | 说明 |
|---|---|---|---|
| `clk` / `rst` | in | 1 | 时钟 / 复位 |

- 例化 `CPU`（`mycpu`）、`rom`（`insrom`，地址取 `addr[9:2]`）与
  `ram`（`dataram`，2026-09 接入），RAM 通过 CPU 的 `mem*` 端口相连。

## 10. 仿真文件

| 文件 | 路径 | 用途 | 是否在工程中 |
|---|---|---|---|
| `sim.v` | `sim_1/imports/new/` | 波形观察（clk 20ns 周期，rst=1 保持 11ns） | ✅ |
| `InsBenchmark.v` | `sim_1/new/` | 自检 testbench（**当前仿真顶层**，clk 10ns 周期） | ✅ |
| `testcase.v` | `sim_1/new/` | 加载 `testcase/*.txt` 黄金值供比对 | ✅ |
| `TestBench_CU.v` | `sim_1/new/` | 控制单元单独激励（`$display` 观察，无自动断言） | ✅ 已加入 |

详解见 [05 · 仿真与验证指南](05-verification.md)。
`TestBench_CU.v` 的期望输出基于"控制单元按标准译码"的假设——控制单元现已
完整实现，可直接用它逐指令核对输出真值（建议把 `$display` 升级为断言）。
