# 06 · 现状与开发路线

本文给出诚实的现状盘点、把 CPU 补完到自检通过的具体步骤、验收标准与工程卫生建议。
各模块的端口与已知问题见 [04 · 模块参考](04-module-reference.md)。

## 1. 现状盘点

### 1.1 已完成

| 项 | 说明 |
|---|---|
| 五大功能部件 | `pc.v`、`rom.v`、`ID.v`（I/S/B 立即数）、`alu.v`（16 操作）、`RegFiles.v` |
| `ram.v` | ✅ 模块完成并已接入（已注册进 `.xpr`，`top.v` 已例化） |
| 自检程序 | `insData.txt` 26 条指令，覆盖 22 种助记符（见 [05 · 反汇编表](05-verification.md)） |
| 自检框架 | `InsBenchmark.v` + 黄金值比对机制完整可用 |
| 波形观察 | `sim.v` 可用 |
| 控制单元译码 | ✅ `ControlUnit2.v` 已按标准 RV32I 完整实现（2026-09） |
| 数据通路 mux | ✅ `CPU.v` 三处选择器（b/写回/下地址）与 `bIs20bImm` 宽度错配已修复（2026-09） |
| U/J 立即数 | ✅ `ID.v` 已实现 `imm20`（U/J 型共用端口，CPU 端按类型扩展） |
| RAM 接入 | ✅ `CPU.v` 新增存储器接口端口，`top.v` 已例化 RAM；`ram.v`/`TestBench_CU.v` 已注册进 `.xpr` |

### 1.2 尚未完成

> 2026-09 更新：本表原列出的功能性缺陷（控制单元译码、三处 mux、U/J 立即数、
> RAM 接入、`bIs20bImm` 宽度错配）已全部修复；黄金文件经字节级核验本就正确，
> 无需修改。剩余事项如下：

| # | 项 | 位置 | 说明 |
|---|---|---|---|
| 1 | 功能仿真验证 | Vivado 行为仿真 | **由使用者执行**：跑 InsBenchmark 26 项自检 |
| 2 | `jalr` 测试覆盖 | 自检程序未含 jalr | 已实现但无自检覆盖，建议自行补一条测试指令并扩展黄金文件 |
| 3 | 综合 / 约束 / 上板 | 无 `.xdc`，`synth_1` 为空 | **由使用者执行**（见步骤 6） |
| 4 | `RegFiles.v` 路径整理 | 6 层嵌套导入路径 | 可选，见工程卫生建议 #1 |

## 2. 补完路线（建议按序执行）

> 每步都给出"改哪里、怎么改、怎么验证"。改 `.v` 前注意源文件是 GBK 编码
> （见 [01](01-overview.md)）。

### 步骤 0 · 黄金文件核验 ✅（无需修改）

经字节级复核（2026-09）：四个黄金文件与自检程序**完全一致**。此前文档所称
"x1.txt 第 4–14 行 +2 错位"系阅读失误，已在 [05 · 第 5 节](05-verification.md)
正式更正。**请勿按旧文档修改 `x1.txt`。**

### 步骤 1 · `ID.v` 补 U/J 型立即数 ✅（已完成，下述为实现要点）

- U 型：`imm20 = ins[31:12]`；
- J 型：`imm20 = {ins[31], ins[19:12], ins[20], ins[30:21]}`（即 imm[20:1]）；
- 两者可共用 20 位 `imm20` 输出，用 `U_type = (opcode == 7'b0110111)`、
  `J_type = (opcode == 7'b1101111)` 做掩码相或（与现有 I/S/B 写法一致）；
- CPU 端使用方式不同：`lui` 直接把 `imm20` 送 b 选择器（ALU `1111` 左移 12）；
  `jal` 目标 = `curraddr + {{12{imm20[19]}}, imm20, 1'b0}`（符号扩展后左移 1 位）。

**验证**：跑 `TestBench_CU.v`（先加入工程）或在 `sim.v` 波形里看
`lui`/`jal` 译码输出。

### 步骤 2 · `ControlUnit2.v` 按真值表译码 ✅（已完成，下述为实现要点）

把常数赋值替换为按 [03 · 控制真值表](03-instruction-set.md) 的组合逻辑。
参考骨架（可直接采用 case 或布尔表达式风格）：

```verilog
always @(*) begin
    // 默认值（对应 nop / 顺序执行）
    pcSourceCode = 2'b00; regWe = 1'b0; memWe = 1'b0;
    bIsImm = 1'b0; bIs20bImm = 1'b0;
    regDataIsFromMem = 1'b0; regDataIsFromPC4 = 1'b0;
    aluOpCode = 4'b0000;
    case (opcode)
        7'b0110011: begin // R 型
            regWe = 1'b1;
            case (funct3)
                3'b000: aluOpCode = funct7 ? 4'b1000 : 4'b0000; // sub / add
                3'b001: aluOpCode = 4'b0001;                    // sll
                3'b100: aluOpCode = 4'b0100;                    // xor
                3'b101: aluOpCode = funct7 ? 4'b1101 : 4'b0101; // sra / srl
                3'b110: aluOpCode = 4'b0110;                    // or
                3'b111: aluOpCode = 4'b0111;                    // and
                default: aluOpCode = 4'b0000;
            endcase
        end
        7'b0010011: begin // I 型运算
            regWe = 1'b1; bIsImm = 1'b1;
            case (funct3)
                3'b000: aluOpCode = 4'b0000;                    // addi
                3'b001: aluOpCode = 4'b0001;                    // slli
                3'b100: aluOpCode = 4'b0100;                    // xori
                3'b101: aluOpCode = funct7 ? 4'b1101 : 4'b0101; // srai / srli
                3'b110: aluOpCode = 4'b0110;                    // ori
                3'b111: aluOpCode = 4'b0111;                    // andi
                default: aluOpCode = 4'b0000;
            endcase
        end
        7'b0000011: begin // lw
            regWe = 1'b1; bIsImm = 1'b1; aluOpCode = 4'b0000;
            regDataIsFromMem = 1'b1;
        end
        7'b0100011: begin // sw
            memWe = 1'b1; bIsImm = 1'b1; aluOpCode = 4'b0000;
        end
        7'b1100011: begin // 分支（con=1 才跳）
            pcSourceCode = 2'b01;
            case (funct3)
                3'b000: aluOpCode = 4'b1001; // beq
                3'b100: aluOpCode = 4'b0010; // blt
                3'b110: aluOpCode = 4'b0011; // bltu
                default: aluOpCode = 4'b1001;
            endcase
        end
        7'b0110111: begin // lui
            regWe = 1'b1; bIs20bImm = 1'b1; aluOpCode = 4'b1111;
        end
        7'b1101111: begin // jal
            regWe = 1'b1; pcSourceCode = 2'b10; regDataIsFromPC4 = 1'b1;
        end
        7'b1100111: begin // jalr
            regWe = 1'b1; bIsImm = 1'b1; aluOpCode = 4'b1110;
            pcSourceCode = 2'b11; regDataIsFromPC4 = 1'b1;
        end
        default: ;
    endcase
end
```

**验证**：`TestBench_CU.v` 逐指令核对输出；注意其激励未覆盖 bge/bgeu/bne。

### 步骤 3 · `CPU.v` 三处 mux ✅（已完成，下述为实现要点）

1. **b 操作数**（修 `assign b=imm12_exp;`）：

```verilog
assign imm20_exp = {12'b0, imm20};                    // lui 用（ALU 内再 <<12）
always @(*) begin
    if (bIs20bImm)      b = imm20_exp;
    else if (bIsImm)    b = imm12_exp;
    else                b = rdata2;
end
```

2. **写回数据**（修 `assign rwdata=f;`；`mdata` 需来自 RAM，见步骤 4）：

```verilog
assign addr4 = curraddr + 32'd4;                      // 已有预留 wire
always @(*) begin
    if (regDataIsFromMem)      rwdata = mdata;
    else if (regDataIsFromPC4) rwdata = addr4;
    else                       rwdata = f;
end
```

3. **下地址**（修 `assign nextaddr=curraddr+4;`；分支/跳转立即数需符号扩展）：

```verilog
wire [31:0] immB_sext = {{19{imm12[11]}}, imm12, 1'b0}; // B型偏移=符号扩展(imm[12:1])后左移1位
wire [31:0] immJ_sext = {{11{imm20[19]}}, imm20, 1'b0};
assign addr_branch = curraddr + immB_sext;            // 已有预留 wire
assign addr_jal    = curraddr + immJ_sext;
assign addr_jalr   = f & ~32'b1;                      // ALU 1110 亦可，二者取一
always @(*) begin
    case (pcsource)
        2'b01:    nextaddr = con ? addr_branch : addr4;  // 条件分支
        2'b10:    nextaddr = addr_jal;
        2'b11:    nextaddr = addr_jalr;
        default:  nextaddr = addr4;
    endcase
end
```

4. 同时修掉 `.bIs20bImm(imm20)` 宽度错配：新增 1 位 wire `is20imm` 接控制单元
   输出，`imm20` 保持由 `ID.v` 驱动。
   （提示：上述代码中的 `bIsImm` / `regDataIsFromMem` / `regDataIsFromPC4`
   是控制单元的端口名，在 `CPU.v` 中对应既有 wire `isimm` / `isfm` / `ispc4`，
   使用时保持名字一致即可。）

**验证**：仿真单步看 `nextaddr`、`rwdata`、`b` 在各类指令下的取值。

### 步骤 4 · 接入 RAM ✅（已完成，下述为实现要点）

- `CPU.v` 增加端口（或在 `top.v` 直连）：
  `memWe`（输出）、`memAddr`（输出，建议直接给 `f[9:2]` 字索引，与 ROM 风格一致）、
  `memWdata`（输出，`rdata2`）、`memRdata`（输入 → `mdata`）；
- `top.v` 例化 `ram` 并连线（替换文件尾部的 `//TODO:`）；
- 自检仅访问地址 0（`0(x0)`），字索引/字节地址两种取法都能过，
  但要和 ROM 的 `addr[9:2]` 用法保持同一风格，便于以后扩展；
- 若希望 RAM 有确定初值（避免 x），可启用 `ram.v` 中被注释的清零循环。

**验证**：`sw` 后 `lw`，检查 RAM[0] 与 x1。

### 步骤 5 · 跑通自检（里程碑，**由使用者执行**）

顶层 `InsBenchmark` 运行行为仿真，期望输出 25 条成功消息 +
`Congratulations! all instructions passed the test!!!`（约 t=275ns `$finish`）。
任何失败按 [05 · 检查机制](05-verification.md) 的时刻→动态步映射定位。

### 步骤 6 ·（可选）综合与上板

1. `rom.v` 的 `$readmemh` 不能综合初始化：换用 Block Memory Generator IP
   （COE 文件由 `insData.txt` 转换）或推断 ROM 后用 `initial`（Vivado 支持
   FPGA 初值，但路径问题依旧）；
2. 新增 `.xdc`：时钟（板载晶振，建议加 `create_clock` 约束）、复位按键、
   观测输出（PC / x 寄存器 / LED / 数码管——按课程板卡定）；
3. 单周期关键路径（ROM→ID→CU→ALU→写回）较长，关注 WNS；不达标先查
   ROM 输出寄存或降低主频；
4. `RegFiles` 的 `initial` 清零在 Vivado 综合下会转为位流初值，可用。

## 3. 验收标准

- [ ] `InsBenchmark` 26 项检查全部通过，出现 `Congratulations!`；
- [ ] `sim.v` 波形中 PC 序列与 [05 · 反汇编表](05-verification.md) 的"下一条 PC"列一致；
- [ ] RAM[0] 在 `sw` 后为 `0xABC12789`，`lw` 后 x1 恢复 `0xABC12789`；
- [ ] `TestBench_CU.v`（升级断言后）输出与 [03 · 控制真值表](03-instruction-set.md) 一致；
- [ ] （若上板）综合 0 error，时序满足约束。

## 4. 工程卫生建议（不影响功能，但降低维护成本）

1. **整理 `RegFiles.v` 路径**：现位于
   `imports/imports/riscv/register - ego/register.srcs/.../single_period_cpu-ego/.../`
   的 6 层嵌套导入路径。建议复制到 `sCPULab.srcs/sources_1/new/RegFiles.v`，
   在 Vivado 中 Remove 旧文件、Add 新文件（注意保留 GBK 编码）；
2. ~~把 `ram.v`、`TestBench_CU.v` 加入工程~~ ✅ 已直接写入 `.xpr` 的
   sources_1 / sim_1 文件组（2026-09，XML 已校验良构）；
3. **清理失效 IPRepoPath**：Settings → IP → Repository，移除指向
   `../../Verilog project/composition priciple/...` 的条目（本工程未用 IP）；
4. **统一仿真目录**：仓库同时存在 `sCPULab.sim/` 与 `sCPULab.sim11/`
   （Vivado 按工程设置只写其一）。以当前工程重新跑一次仿真后，
   旧目录可归档删除（均已被 .gitignore 排除，不影响 Git 仓库）；
5. **编码约定写进仓库**：`.v` 用 GBK（含中文注释）、`docs/` 用 UTF-8；
   若以后换 UTF-8 保存 `.v`，注意 Vivado 2017.4 在中文 Windows 下的默认编码。

## 5. 风险提示

- **黄金文件已核验正确**：四个文件与自检程序一致（见
  [05 · 第 5 节](05-verification.md)）。若自检失败，请从 RTL 查找原因，
  不要改动黄金文件；
- **不要在综合路径上依赖 `$readmemh` 相对路径**；
- **`x0` 写保护**、**B 型立即数末位补 0**、**jalr 清 bit0** 是三个容易漏的实现点，
  自检程序恰好都会覆盖到；
- 自检只覆盖 22 种指令，`jalr` 已实现但无覆盖——如需覆盖，自行补一条测试指令
  并扩展黄金文件。
