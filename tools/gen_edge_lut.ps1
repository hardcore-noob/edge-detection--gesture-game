<#
  生成 edge_detect_96.v 里那张边缘灰度映射表（√ 曲线）。

  用法：  .\tools\gen_edge_lut.ps1            # 默认白点 256
          .\tools\gen_edge_lut.ps1 -WhitePoint 128   # 更"白描"的一档
  输出：  256 行 case 分支，直接替换 edge_detect_96.v 里 edge_curve 函数的内容。

  曲线：  code = clamp(round(255 * sqrt(mag / WhitePoint)), 0, 255)
          mag = |gx| + |gy|，干净的阶跃边缘约等于 4*Δ（Δ 是两侧真实灰阶差）

  WhitePoint 是"多强的边缘算纯白"：
    128 → Δ≈32 纯白（弱边缘最亮，但 Δ≥32 就过曝）
    256 → Δ≈64 纯白（当前选型，兼顾弱边缘可见与强边缘不糊）
    512 → Δ≈128 纯白（保守，画面偏灰）

  显示器 gamma≈2.2 折算后，感知亮度 ≈ (mag / WhitePoint)^1.1，
  所以白点越小整幅图越亮；曲线指数（这里是 1.1，线性映射是 2.2）由曲线类型决定，
  想要更"硬"的效果可以把 sqrt 换成 mag^0.68 之类的幂函数。
#>
param([int]$WhitePoint = 256)

if ($WhitePoint -lt 1) { throw "WhitePoint 必须 >= 1" }

for ($i = 0; $i -lt 256; $i++) {
    $mag = 4 * $i                 # 索引 = mag >> 2
    $code = [math]::Round(255.0 * [math]::Sqrt($mag / $WhitePoint))
    if ($code -gt 255) { $code = 255 }
    "            8'd{0}: edge_curve = 8'd{1};" -f $i, $code
}
