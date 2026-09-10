# 05 · 仿真与验证指南

本文覆盖三个 testbench 的用法、自检程序 `insData.txt` 的完整反汇编、
`InsBenchmark` 的检查机制、黄金文件及其**已知问题**、当前失败的根因分析。

## 1. 测试资产总览

| 资产 | 位置 | 用途 |
|---|---|---|
| `insData.txt` | 工程根目录 | 自检程序机器码（26 条指令），ROM 初始化文件 |
| `testcase/pc.txt` 等 4 个 | 工程根目录 | InsBenchmark 黄金值：期望 PC / x1 / x2 / x3 序列（各 26 行） |
| `sim.v` | `sCPULab.srcs/sim_1/imports/new/` | 波形观察 testbench |
| `InsBenchmark.v` | `sCPULab.srcs/sim_1/new/` | 自检 testbench（**当前仿真顶层**） |
| `testcase.v` | `sCPULab.srcs/sim_1/new/` | 黄金值加载模块（供 InsBenchmark 使用） |
| `TestBench_CU.v` | `sCPULab.srcs/sim_1/new/` | 控制单元单独激励（已加入工程） |

## 2. 在 Vivado 中运行仿真

1. 打开 `sCPULab.xpr`；
2. Flow Navigator → SIMULATION → Run Simulation → Run Behavioral Simulation；
3. 结果看 **Tcl Console**（自检消息）与 **Wave** 窗口；
4. 切换仿真顶层：Project Manager → Settings → Simulation → Simulation
   把 `xsim.simulate.top` 设为 `InsBenchmark` / `sim`；
   或在 Sources 面板 sim_1 分组中右键文件 → **Set as Top**。

默认批量运行 1000ns，足够自检程序全程（约 275ns 跑完）。

## 3. 三个 testbench

### 3.1 `sim.v` — 波形观察

- `clk` 初值 0，每 10ns 翻转（**周期 20ns**，上升沿在 t=10, 30, 50…）；
- `rst` 初值 1，t=11ns 释放（第一个上升沿 t=10 落在复位窗口内，PC 被复位）；
- 无任何检查，纯粹跑 `top` 看波形。适合在自检失败时观察数据通路。

### 3.2 `InsBenchmark.v` — 自检（当前顶层）

- `clk` 初值 0，每 5ns 翻转（**周期 10ns**，上升沿在 t=5, 15, 25…）；
- `rst` 在 [4ns, 6ns) 为 1，覆盖 t=5 的上升沿 → PC 复位为 `0x00400000`；
- 例化 `top`，并用**层级引用**直接读寄存器堆：
  `t.mycpu.myrf.regs[1..3]`（x1/x2/x3）与 `t.addr`（PC）；
- 例化 `testcase tc` 加载黄金值，按索引 `count` 给出当前期望值。

**检查机制**（对调试至关重要）：

| 时刻 | 事件 |
|---|---|
| t=0 | clk=0，rst=0，PC=x |
| t=5 | posedge：rst=1 → PC ← 0x00400000，第 0 条指令开始取指 |
| t=15 | posedge：第 0 条指令（ori）执行完毕：PC ← 0x00400004，寄存器堆写入 |
| t=25 | posedge：**检查 0**：比对"第 0 条指令执行后"的状态 |
| t=25+10k | **检查 k**（k=0…25），通过则 `count` 加 1 |
| count=26 | 打印最后一条成功消息 + `Congratulations!...` + `$finish` |

检查 k 的语义：验证**动态执行完第 k 条指令之后**的状态——

- `pc` 应等于 `pcData[k]`（= 下一条指令的地址，跳转指令体现为目标地址）；
- `x1/x2/x3` 应等于 `x1Data[k] / x2Data[k] / x3Data[k]`（= 该指令写回后的值）。

任一项不符 → `test=0` → **直接 `$finish`，没有任何"失败"提示文本**。
排查方法：看 `$finish called at time : XX ns` 的时刻，
`k = (XX − 25) / 10`，即第 k 条指令的比对出错；再对照
[第 4 节的期望值表](#4-自检程序-insdatatxt-逐条反汇编与期望值)。

每周期还会按 `count` 打印一行消息；第 3 条指令（`ori x2,x2,0x789`）没有专属
消息（case 表里跳过了 `5'h3`），打印分隔线 `-------------`。

### 3.3 `TestBench_CU.v` — 控制单元单独激励

- 对 `ControlUnit` 逐指令施加 opcode/funct3/funct7，`$display` 打印输出；
- **无自动断言**；已注册进 Vivado 工程（在 Sources 的 sim_1 中可见）；
- 它隐含"控制单元已按标准译码"的假设——控制单元现已按
  [03 · 控制真值表](03-instruction-set.md) 实现（2026-09），可直接用它做
  单独验证；建议顺手把 `$display` 升级为断言。

## 4. 自检程序 `insData.txt` 逐条反汇编与期望值

以下反汇编已逐位核验（标准 RV32I 编码）。"动态步"列 = 按程序实际控制流
（含跳转）的执行顺序编号，即 InsBenchmark 检查 k 对应"动态步 k"。

| 动态步 | 地址 | 机器码 | 指令 | 效果 / 执行后状态 | 下一条 PC | 预期消息（该步检查通过时打印） |
|---|---|---|---|---|---|---|
| 0 | 0x00400000 | `78906093` | `ori x1, x0, 0x789` | x1=0x00000789 | 0x00400004 | `1. ori success!` |
| 1 | 0x00400004 | `abc12137` | `lui x2, 0xABC12` | x2=0xABC12000 | 0x00400008 | `2. lui success!` |
| 2 | 0x00400008 | `78916113` | `ori x2, x2, 0x789` | x2=0xABC12789 | 0x0040000C | `-------------` |
| 3 | 0x0040000C | `78904193` | `xori x3, x0, 0x789` | x3=0x00000789 | 0x00400010 | `3. xori success!` |
| 4 | 0x00400010 | `01419193` | `slli x3, x3, 20` | x3=0x78900000 | 0x00400014 | `4. slli success!` |
| 5 | 0x00400014 | `00518193` | `addi x3, x3, 5` | x3=0x78900005（作移位量 5） | 0x00400018 | `5. addi success!` |
| 6 | 0x00400018 | `003110b3` | `sll x1, x2, x3` | x1=x2<<5=0x7824F120 | 0x0040001C | `6. sll success!` |
| 7 | 0x0040001C | `003100b3` | `add x1, x2, x3` | x1=0x2451278E | 0x00400020 | `7. add success!` |
| 8 | 0x00400020 | `00815093` | `srli x1, x2, 8` | x1=0x00ABC127 | 0x00400024 | `8. srli sucess!` |
| 9 | 0x00400024 | `40815093` | `srai x1, x2, 8` | x1=0xFFABC127 | 0x00400028 | `9. srai sucess!` |
| 10 | 0x00400028 | `003140b3` | `xor x1, x2, x3` | x1=0xD351278C | 0x0040002C | `10. xor success!` |
| 11 | 0x0040002C | `003150b3` | `srl x1, x2, x3` | x1=x2>>5=0x055E093C | 0x00400030 | `11. srl success!` |
| 12 | 0x00400030 | `403150b3` | `sra x1, x2, x3` | x1=x2>>>5=0xFD5E093C | 0x00400034 | `12. sra success!` |
| 13 | 0x00400034 | `45617093` | `andi x1, x2, 0x456` | x1=0x00000400 | 0x00400038 | `13. andi success!` |
| 14 | 0x00400038 | `fe310ee3` | `beq x2, x3, −4` | x2≠x3 → **不跳** | 0x0040003C | `14. beq not jump success!` |
| 15 | 0x0040003C | `002060b3` | `or x1, x0, x2` | x1=0xABC12789 | 0x00400040 | `15. or success!` |
| 16 | 0x00400040 | `00208863` | `beq x1, x2, +16` | 相等 → **跳转** | 0x00400050 | `16. beq jump success!` |
| 17 | 0x00400050 | `fe314ae3` | `blt x2, x3, −12` | 有符号 x2<x3 → **跳回** | 0x00400044 | `17. blt jump success!` |
| 18 | 0x00400044 | `403100b3` | `sub x1, x2, x3` | x1=0x33312784 | 0x00400048 | `18. sub success!` |
| 19 | 0x00400048 | `fe3166e3` | `bltu x2, x3, −20` | 无符号 x2>x3 → **不跳** | 0x0040004C | `19. bltu not jump success!` |
| 20 | 0x0040004C | `0021e463` | `bltu x3, x2, +8` | 无符号 x3<x2 → **跳转** | 0x00400054 | `20. bltu jump success!` |
| 21 | 0x00400054 | `fe21cee3` | `blt x3, x2, −4` | 有符号 x3>x2 → **不跳** | 0x00400058 | `21. blt not jump success!` |
| 22 | 0x00400058 | `003170b3` | `and x1, x2, x3` | x1=0x28800001 | 0x0040005C | `22. and success!` |
| 23 | 0x0040005C | `00202023` | `sw x2, 0(x0)` | RAM[0]=0xABC12789 | 0x00400060 | `23. sw success!` |
| 24 | 0x00400060 | `00002083` | `lw x1, 0(x0)` | x1=RAM[0]=0xABC12789 | 0x00400064 | `24. lw success!` |
| 25 | 0x00400064 | `0000006f` | `jal x0, 0` | 原地自循环（程序结束） | 0x00400064 | `25. jal success!` + `Congratulations! all instructions passed the test!!!` |

控制流小结：0–16 顺序执行（第 14 条 beq 不跳、第 16 条 beq 跳到 0x00400050）
→ 第 17 动态步 blt 跳回 0x00400044 执行 sub → 顺序 0x00400048/0x0040004C
→ bltu 跳到 0x00400054 → blt 不跳 → 顺序执行 and/sw/lw → jal 自循环收尾。
**地址 0x00400044 的 `sub` 恰好被执行一次（经跳转），0x00400048 的 `bltu` 也被执行。**

注意消息里的 `sucess` 为源码中的原始拼写（`$display` 字符串如此），文档保留原样。

## 5. 黄金文件核验结论

`testcase/` 下四个黄金文件已与上表**逐行、字节级核验**（2026-09 复核），
**全部一致，无需修改**：

- **`pc.txt`**：与上表"下一条 PC"列完全一致，含三处跳转目标
  （k16→0x00400050、k17→0x00400044、k20→0x00400054）✅
- **`x1.txt`**：与"执行后 x1"逐行一致——k6 起为 `sll`/`add`/`srli`/`srai`/`xor`/
  `srl`/`sra`/`andi` 结果，k18 起为 `sub` 结果（经跳转回 0x00400044 执行），
  k22 为 `and` 结果，k24 为 `lw` 结果 ✅
- **`x2.txt`**：0 → 0xABC12000（k1，lui）→ 0xABC12789（k2，ori）后恒定 ✅
- **`x3.txt`**：0 → 0x789（k3，xori）→ 0x78900000（k4，slli）→ 0x78900005
  （k5，addi）后恒定 ✅

结论：只要 RTL 按 [03 · 控制真值表](03-instruction-set.md) 实现正确，
自检即可完整通过，**不存在黄金文件障碍**。

> 历史备注：本文档早期版本曾误报 `x1.txt` 第 4–14 行存在"+2 错位"，
> 后经文件修改时间（2023/5/30 从未变更）与字节级转储复核确认该论述有误
> （系当时阅读失误），特此更正，请以本节结论为准。

## 6. 修复前失败的根因分析（历史记录）

> 2026-09 更新：控制单元与数据通路已按本方案补完，以下失败不应再复现；
> 保留本节作为排查参照。若修复后的仿真仍在 25ns 附近失败，可对照本节定位。

`vivado.log`（2025-12-22 记录，工程旧路径 G:\CS\new_lab5）：

```
$finish called at time : 25 ns : File ".../InsBenchmark.v" Line 63
```

即在**检查 0**（t=25ns）处失败。根因链：

1. `ControlUnit2.v` 是常数桩：`aluOpCode` 恒为 `4'b0011`（无符号小于）；
2. 第 0 条指令 `ori x1, x0, 0x789` 执行时，ALU 实际计算
   `0 < 0x789`（dataA = rs1 = x0 = 0，b = imm12 符号扩展 0x789）→ 结果 `1`；
3. `CPU.v` 写回选择为 TODO（恒取 ALU 结果）→ x1 被写入 `1`，而期望 `0x789`；
4. 检查 0 比对 x1 失败 → `$finish`。

即便 ALU 操作碰巧正确，`CPU.v` 的另外两处 TODO（b 选择恒取立即数、
下地址恒为 pc+4）也会让移位类/寄存器型指令与任何跳转失败。

## 7. 推荐验证流程

1. 黄金文件已核验正确（见第 5 节），无需修改；
2. RTL 补完已实施（[06 · 步骤 1–4](06-status-and-roadmap.md)，2026-09）；
3. `Run Behavioral Simulation`（顶层 InsBenchmark），确认 26 项检查全过、
   出现 `Congratulations!`；
4. 切顶层为 `sim` 跑波形，抽查关键信号（PC 序列、x1/x2/x3、RAM[0]）；
5. 用 `TestBench_CU.v`（加入工程后）单独核对控制单元各指令的输出真值；
6. （可选）综合 + 时序仿真，再考虑上板（见 [06 · 步骤 6](06-status-and-roadmap.md)）。
