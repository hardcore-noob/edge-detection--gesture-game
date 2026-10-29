# 资源预算与验收

本文记录当前资源基线、构建门禁、面积表阅读方法和布局参数。历史优化过程见
`CHANGELOG.md`。

## 当前基线

| 资源 | 用量 | 占比 |
|---|---:|---:|
| slices | 17764 / 21216 | 83.73% |
| LUT6 | 16290 / 21216 | 76.78% |
| 触发器 | 15478 / 42432 | 36.48% |
| ERAM | 76 / 108 | 70.37% |
| DSP | 8 / 40 | 20.00% |
| feedthrough | 6161 | — |
| final Setup WNS | +711 ps | 0 违例 |
| final Hold WNS | +20 ps | 0 违例 |

## 构建门禁

- slices <95%
- final Setup WNS ≥ +200 ps
- Hold 0 违例
- 一次 PnR 通过
- 0 ERROR，且 bitgen 成功

门禁用于当前竞赛阶段。资源优化不能通过关闭必要功能、跳过时序检查或忽略错误来达标。

## 构建与产物

```powershell
pwsh -NoProfile -File tools/build_td.ps1
```

主要产物：

```text
td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display.bit
td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display_compress.bit
```

构建结束后同时保留：

- 本次 `td_YYYYMMDD_HHMMSS.log`
- `route.qor`
- `final_timing.rpt`
- `camera_to_dsi_display_phy.area`

## 数字来源

只使用本次构建新生成的日志。`run.log` 可能是更早构建留下的旧文件，不能作为
当前数字。

关键文件：

- `camera_to_dsi_display_rtl.area`：RTL/门级面积，用于判断模块真实门数。
- `camera_to_dsi_display_gate.area`：门级打包后的中间结果。
- `camera_to_dsi_display_phy.area`：布局布线后的最终资源。

模块定位优先看 `*.area` 文末的 `Report Hierarchy Area`：

- `logic lut`：普通逻辑。
- `ripple`：加法器/进位链。
- `seq`：时序单元。
- `eram`：块 RAM。
- `dram lut`：分布式 RAM 占用的 LUT。

父模块数字包含子模块。RTL 级门数适合判断大块逻辑是否值得搬迁；post-route 层次表
会被优化器摊平，不能单独用来否定模块价值。

## 布局参数

`phy_1/settings.cfg` 当前参数：

```tcl
set phyWildParams {place opt_timing high place max_fanout 250}
```

- `opt_timing high`：提高布局时序优化强度。
- `max_fanout 250`：拆分高扇出网，抑制长线和 feedthrough。

新 worktree 由 `tools/new_worktree_runs.ps1` 从仓库模板补齐这两个参数。

## 优化优先级

1. 清理死代码、未使用端口、重复 mux 和常量分支。
2. 压缩 `recog_top` 的宽组合路径和重复统计逻辑。
3. 合并游戏对象槽、渲染判属中的重复比较与地址 mux。
4. 复用现有 ERAM/DSP 或共享数据通路，避免为单一功能复制整套逻辑。
5. 结构重构必须保持数据相位、跨域握手和输出对齐。

## 记录格式

每次资源相关构建至少记录：

- commit 或分支
- slices、LUT6、reg、ERAM、DSP、feedthrough
- final Setup / Hold WNS
- 是否一次 PnR
- 与上一稳定基线的差值
- bit 路径和 SHA256
