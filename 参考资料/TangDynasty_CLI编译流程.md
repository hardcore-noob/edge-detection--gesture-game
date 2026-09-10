# TangDynasty CLI 编译流程

> 整理日期：2026-09-08
> 适用工具：TD Release_2026.1_SP2（Build 6.2.2.200067）
> 适用工程：`example/lab_ex1_mipi_hdmi/lab_ex1_mipi_hdmi/td_project/camera_to_dsi_display.al`
> 本文基于实际执行过的 TangDynasty 命令行编译流程整理。

## 1. 用途

本文记录在 Windows 环境下使用 TangDynasty（TD）命令行接口，从修改引脚约束、重新综合、布局布线到生成 bit 流的完整流程。

适用于以下场景：

- 修改 `pin.adc`、`.sdc` 或 RTL 后，不打开图形界面直接编译；
- 批量编译多个工程；
- 在终端或脚本中执行固定工程流程；
- 验证生成的 `.bit` 文件是否存在、是否使用了预期的引脚约束。

## 2. 环境信息

### 2.1 工具安装路径

当前机器实际安装路径为：

```text
D:\TangDynasty
```

注意：注册表中可能残留旧的安装路径 `D:\Tang Dynasty`，实际有效目录是 `D:\TangDynasty`。

### 2.2 相关可执行文件

```text
D:\TangDynasty\bin\td_commands_prompt.exe
```

这是 TD 的命令行/Tcl 入口，本文使用它执行官方默认流程脚本。

其他可能用到的文件：

```text
D:\TangDynasty\scripts\DefaultFlow.tcl
D:\TangDynasty\bin\td.exe
D:\TangDynasty\bin\run.exe
```

### 2.3 工程目录

源码和约束目录：

```text
example\lab_ex1_mipi_hdmi\lab_ex1_mipi_hdmi\user_source\hdl_source
example\lab_ex1_mipi_hdmi\lab_ex1_mipi_hdmi\user_source\constraints_source
example\lab_ex1_mipi_hdmi\lab_ex1_mipi_hdmi\user_source\ip_source
```

TD 工程文件：

```text
example\lab_ex1_mipi_hdmi\lab_ex1_mipi_hdmi\td_project\camera_to_dsi_display.al
```

编译运行目录：

```text
example\lab_ex1_mipi_hdmi\lab_ex1_mipi_hdmi\td_project\camera_to_dsi_display_Runs\syn_1
example\lab_ex1_mipi_hdmi\lab_ex1_mipi_hdmi\td_project\camera_to_dsi_display_Runs\phy_1
```

## 3. CLI 使用方式

TangDynasty 的 `td_commands_prompt.exe` 本质上是 TD 的 Tcl 命令入口。官方支持的常见用法有两种。

### 3.1 TD CMD 窗口中执行 Tcl 脚本

进入脚本所在目录后执行：

```tcl
source DefaultFlow.tcl
```

### 3.2 批处理文件执行

官方建议在 `.bat` 文件中写入：

```bat
<td_install_dir>\td_commands_prompt.exe demo.tcl
```

TD 在生成 Run 时，会在 `syn_1` 和 `phy_1` 目录下自动生成 `run.bat`。

### 3.3 项目实际使用的默认流程脚本

TD 自动生成的流程脚本为：

```text
D:\TangDynasty\scripts\DefaultFlow.tcl
```

该脚本在启动时会读取当前工作目录下的 `settings.cfg`。

`syn_1\settings.cfg` 的关键内容示例：

```tcl
set ADCList {"../../../user_source/constraints_source/pin.adc"}
set device_name ph1_35p.db
set package_name PH1P35MDG324
set top_model_name {design_top_wrapper}
set start_step read_design
set end_step opt_gate
```

`phy_1\settings.cfg` 的关键内容示例：

```tcl
set parent ../syn_1
set start_step opt_place
set end_step bitgen
```

## 4. 完整编译流程

以下流程是在修改 `pin.adc` 后，从零重新执行综合和布局布线。

### 4.1 第一步：备份约束文件

在修改 `pin.adc` 前先备份，便于恢复：

```powershell
Copy-Item `
  -LiteralPath "D:\competition\example\lab_ex1_mipi_hdmi\lab_ex1_mipi_hdmi\user_source\constraints_source\pin.adc" `
  -Destination "D:\competition\example\lab_ex1_mipi_hdmi\lab_ex1_mipi_hdmi\user_source\constraints_source\pin.adc.orig" `
  -Force
```

### 4.2 第二步：修改引脚约束

本次示例将两个按键信号改到板载按键对应的 FPGA 引脚：

```text
I_button[0] → D5   ; K1
I_button[1] → A9   ; K2
```

修改后的 `pin.adc` 内容：

```text
set_pin_assignment	{ I_button[0] }			{ LOCATION = D5;  IOSTANDARD = LVCMOS33; DRIVESTRENGTH = 8; PULLTYPE = PULLUP; }
set_pin_assignment	{ I_button[1] }			{ LOCATION = A9;  IOSTANDARD = LVCMOS33; DRIVESTRENGTH = 8; PULLTYPE = PULLUP; }
```

### 4.3 第三步：确认约束文件已被工程引用

在 `.al` 工程文件中应能找到 `pin.adc`，并且综合、布局布线均启用：

```xml
<ADC_FILE>
    <File Path="../user_source/constraints_source/pin.adc">
        <FileInfo>
            <Attr Name="UsedInSyn" Val="true"/>
            <Attr Name="UsedInP&amp;R" Val="true"/>
            <Attr Name="BelongTo" Val="constraint_1"/>
        </FileInfo>
    </File>
</ADC_FILE>
```

### 4.4 第四步：执行综合（syn_1）

工作目录必须是 `syn_1`。

推荐使用 PowerShell `Start-Process`，参数中的脚本路径使用正斜杠：

```powershell
$synDir = "D:\competition\example\lab_ex1_mipi_hdmi\lab_ex1_mipi_hdmi\td_project\camera_to_dsi_display_Runs\syn_1"

$p = Start-Process `
  -FilePath "D:\TangDynasty\bin\td_commands_prompt.exe" `
  -ArgumentList "D:/TangDynasty/scripts/DefaultFlow.tcl" `
  -WorkingDirectory $synDir `
  -Wait -NoNewWindow -PassThru

"EXIT=$($p.ExitCode)"
```

`syn_1` 阶段会依次执行：

```text
read_design
→ opt_rtl
→ opt_gate
```

正常情况下退出码为 `0`。流程末尾会打印综合阶段的统计信息。

### 4.5 第五步：执行布局布线与 bitgen（phy_1）

工作目录必须是 `phy_1`：

```powershell
$phyDir = "D:\competition\example\lab_ex1_mipi_hdmi\lab_ex1_mipi_hdmi\td_project\camera_to_dsi_display_Runs\phy_1"

$p = Start-Process `
  -FilePath "D:\TangDynasty\bin\td_commands_prompt.exe" `
  -ArgumentList "D:/TangDynasty/scripts/DefaultFlow.tcl" `
  -WorkingDirectory $phyDir `
  -Wait -NoNewWindow -PassThru

"EXIT=$($p.ExitCode)"
```

`phy_1` 阶段会依次执行：

```text
opt_place
→ opt_route
→ bitgen
```

`bitgen` 完成后会生成：

```text
camera_to_dsi_display.bit
camera_to_dsi_display_compress.bit
camera_to_dsi_display_inst.bid
```

## 5. 使用现有 run.bat 的替代方式

每个 Run 目录中已经生成了 `run.bat`。例如：

```text
...\camera_to_dsi_display_Runs\syn_1\run.bat
...\camera_to_dsi_display_Runs\phy_1\run.bat
```

现有 `run.bat` 中带有 `pause`。在交互式终端中可以直接使用，但自动化脚本中建议改用上面的 `Start-Process` 方式，或去掉 `pause` 后调用。

## 6. 输出文件位置与复制

默认输出位置：

```text
...\camera_to_dsi_display_Runs\phy_1\camera_to_dsi_display.bit
...\camera_to_dsi_display_Runs\phy_1\camera_to_dsi_display_compress.bit
...\camera_to_dsi_display_Runs\phy_1\camera_to_dsi_display_inst.bid
```

也可以将生成结果复制到统一输出目录：

```powershell
$out = "D:\competition\output\lab_ex1_k1k2"
$src = "D:\competition\example\lab_ex1_mipi_hdmi\lab_ex1_mipi_hdmi\td_project\camera_to_dsi_display_Runs\phy_1"

New-Item -ItemType Directory -Force -Path $out | Out-Null

Copy-Item "$src\camera_to_dsi_display.bit" "$out\" -Force
Copy-Item "$src\camera_to_dsi_display_compress.bit" "$out\" -Force
Copy-Item "$src\camera_to_dsi_display_inst.bid" "$out\" -Force
Copy-Item "D:\competition\example\lab_ex1_mipi_hdmi\lab_ex1_mipi_hdmi\user_source\constraints_source\pin.adc" "$out\" -Force
```

## 7. 验证结果

### 7.1 检查 bit 流文件

```powershell
Get-ChildItem `
  -LiteralPath "D:\competition\output\lab_ex1_k1k2" `
  -Filter "*.bit" |
  Select-Object Name, Length, LastWriteTime
```

期望能看到两个文件：

```text
camera_to_dsi_display.bit          1789547 字节
camera_to_dsi_display_compress.bit 1314313 字节
```

### 7.2 检查时序状态

查看 `phy_1` 下的时序状态文件：

```text
camera_to_dsi_display_phy.ts
```

本次正确生成的结果：

```text
SWNS: 2.098ns, STNS: 0.000ns.
HWNS: 0.020ns, HTNS: 0.000ns.
```

即 Setup 和 Hold 均无违例。

### 7.3 检查综合日志中的引脚约束

查看 `syn_1\run.log` 中是否读取了新的引脚：

```powershell
rg "I_button\[0\].*D5|I_button\[1\].*A9" `
  "D:\competition\example\lab_ex1_mipi_hdmi\lab_ex1_mipi_hdmi\td_project\camera_to_dsi_display_Runs\syn_1\run.log"
```

应能读取到类似输出：

```text
set_pin_assignment  I_button[0]   LOCATION = D5; ...
set_pin_assignment  I_button[1]   LOCATION = A9; ...
```

### 7.4 查看 flow 状态

```text
...\syn_1\flow.status
...\phy_1\place_flow.status
...\phy_1\route_flow.status
```

`route_flow.status` 中会显示最终时序：

```text
Setup : WNS  2098ps  TNS        0ps  NUM_FEPS     0
Hold  : WNS    20ps  TNS        0ps  NUM_FEPS     0
```

## 8. 常见问题

### 8.1 提示找不到 `DefaultFlow.tcl`

可能原因：

- 当前工作目录不是 `syn_1` 或 `phy_1`；
- 脚本路径中的反斜杠被参数解析后丢失；
- 调用方式不是批处理模式。

本文验证过的方法是让 `Start-Process` 的 `-WorkingDirectory` 指向 Run 目录，脚本路径使用正斜杠：

```text
D:/TangDynasty/scripts/DefaultFlow.tcl
```

### 8.2 修改了 pin.adc 但输出没有变化

检查以下内容：

- `pin.adc` 是否被 `.al` 工程引用；
- 是否重新执行了 `syn_1`，而不只是 `phy_1`；
- `syn_1\run.log` 中是否打印了新的 `set_pin_assignment`；
- 综合数据库 `camera_to_dsi_display_gate.db` 时间戳是否更新。

### 8.3 只改了引脚约束，要不要重新综合

引脚约束属于布局布线阶段的约束，但为保证工程处于一致状态，建议：

```text
重新执行 syn_1
→ 重新执行 phy_1
→ bitgen
```

### 8.4 编译后想固化到 Flash

当前默认流程生成的是 `.bit`。如需烧写到板载 Flash 的最终镜像，请按照项目提供的“PH1P35 烧写程序使用方法”操作，或使用 TD 的 bitgen/烧写配置生成对应格式。

## 9. 常用命令速查

| 目的 | 命令/路径 |
| --- | --- |
| 工具入口 | `D:\TangDynasty\bin\td_commands_prompt.exe` |
| 默认流程脚本 | `D:\TangDynasty\scripts\DefaultFlow.tcl` |
| 综合目录 | `...\camera_to_dsi_display_Runs\syn_1` |
| 布局布线目录 | `...\camera_to_dsi_display_Runs\phy_1` |
| 综合阶段 | `read_design → opt_rtl → opt_gate` |
| 布局布线阶段 | `opt_place → opt_route → bitgen` |
| 最终 bit 流 | `camera_to_dsi_display.bit` |
| 压缩 bit 流 | `camera_to_dsi_display_compress.bit` |
| 映射文件 | `camera_to_dsi_display_inst.bid` |
| 时序状态文件 | `camera_to_dsi_display_phy.ts` |
| 综合日志 | `syn_1\run.log` |
| 布线路由状态 | `phy_1\route_flow.status` |

## 10. 本次实际验证结果

| 项目 | 结果 |
| --- | --- |
| TangDynasty 版本 | TD Release_2026.1_SP2，Build 6.2.2.200067 |
| 按键约束 | `I_button[0] → D5`，`I_button[1] → A9` |
| 综合 | 成功 |
| 布局布线 | 成功 |
| Setup WNS | 2098 ps |
| Hold WNS | 20 ps |
| 生成文件 | `.bit`、`_compress.bit`、`_inst.bid` |

