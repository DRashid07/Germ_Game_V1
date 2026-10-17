# Resize a PNG to an exact size, keeping alpha (image_gen returns e.g. 1254x1254 for "1024x1024").
# Usage:  powershell -ExecutionPolicy Bypass -File resize.ps1 <in.png> <out.png> [width] [height]
# Default 1024x1024. Proportional only: it refuses to change the aspect ratio by more than 1%,
# so a template-registered image never gets squashed. Python is NOT installed; System.Drawing.
# It prints the SOURCE pixel format: a transparent asset must already be Format32bppArgb before
# resizing (the output is always 32-bit, so a 24-bit fake-checkerboard result would be hidden).
# Any failure exits 1.
param([string]$In, [string]$Out, [int]$W = 1024, [int]$H = 1024)
$ErrorActionPreference = 'Stop'
try {
  Add-Type -AssemblyName System.Drawing
  $inFull = (Resolve-Path -LiteralPath $In).Path
  $outFull = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Out)
  $outDir = Split-Path -Parent $outFull
  if (-not (Test-Path -LiteralPath $outDir)) { throw "output folder does not exist: $outDir" }
  $src = [System.Drawing.Image]::FromFile($inFull)
  $srcInfo = "$($src.Width)x$($src.Height) $($src.PixelFormat)"
  $ra = $src.Width / $src.Height; $rb = $W / $H
  if ([Math]::Abs($ra - $rb) / $rb -gt 0.01) {
    $src.Dispose(); throw "aspect mismatch: $srcInfo -> ${W}x${H}"
  }
  $dst = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($dst)
  $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $attr = New-Object System.Drawing.Imaging.ImageAttributes
  $attr.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)   # no dark fringe at the edges
  $g.DrawImage($src, (New-Object System.Drawing.Rectangle 0, 0, $W, $H), 0, 0, $src.Width, $src.Height,
    [System.Drawing.GraphicsUnit]::Pixel, $attr)
  $g.Dispose(); $src.Dispose()
  # The source may be the same file as the output: save to a temp name first.
  $tmp = "$outFull.tmp.png"
  $dst.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png); $dst.Dispose()
  Move-Item -LiteralPath $tmp -Destination $outFull -Force
  if (-not (Test-Path -LiteralPath $outFull)) { throw "nothing written: $outFull" }
  Write-Output "resized $srcInfo -> $outFull (${W}x${H})"
} catch {
  Write-Error "resize.ps1: $($_.Exception.Message)" -ErrorAction Continue
  exit 1
}
