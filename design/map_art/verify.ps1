# Germ Arena map art: verification of one PNG (Codex runs it on every output).
# Usage:  powershell -ExecutionPolicy Bypass -File verify.ps1 <png> [hollowX hollowY hollowR]
# Prints one line of key=value numbers. Python is NOT installed; this uses System.Drawing.
#
#   format       pixel format (must be Format32bppArgb for transparent assets)
#   corner_a     max alpha over the four 64x64 corner blocks (transparent assets: 0)
#   a8 / aw8     alpha at (8,8) and (w-8,h-8)
#   centre_a     alpha at the exact centre
#   opaque       share of pixels with alpha >= 200
#   bbox         x0,y0,x1,y1 of pixels with alpha >= 128 (registration: footprint is x 128..896, y 128..896)
#   p99_max      99th percentile of max(R,G,B)/255 over opaque pixels (value cap)
#   spread       max of |R-G|,|G-B|,|R-B| over opaque pixels (neutral assets: < 24)
#   key_px       pixels close to #FF00FF or #00FF00 (must be 0 in a finished transparent asset)
#   checker      INFORMATIONAL: share of opaque pixels that are near-neutral light grey/white. White or
#                grey art scores high by design; a painted checkerboard BACKGROUND is caught by corner_a
#                (opaque corners), one inside holes by hollow_a and by looking at the image.
#   hollow_a     mean alpha (0..1) inside the given circle (canopy hollow: <= 0.30)
#   p99_any      like p99_max but over EVERY visible pixel (alpha >= 8): use it for semi-transparent
#                art (rubble at alpha <= 0.8 has no pixel with alpha >= 200, so p99_max reads 0)
#   p99_noamber  like p99_max but ignoring amber pixels: the value cap for BRITTLE and VENT, whose
#                amber crack bodies / lip dashes are an allowed exception
#   amber        share of opaque pixels that are amber (hue 20-50 deg, S >= 0.45, V >= 0.45)
#   amber_glow   share of opaque pixels that are amber AND bright (V >= 0.85) = glowing crack cores
#   spread8      like spread but over every pixel with alpha > 8 (catches colour in soft edges)
# Any error exits 1.
param([string]$Path, [int]$HX = -1, [int]$HY = -1, [int]$HR = -1)
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing
if (-not ("MapVerify" -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Globalization;
using System.Runtime.InteropServices;
public static class MapVerify {
  static int P99(int[] hist, long n) {
    if (n <= 0) return 0;
    long target = (long)Math.Ceiling(n * 0.99), acc = 0;
    for (int v = 0; v < 256; v++) { acc += hist[v]; if (acc >= target) return v; }
    return 255;
  }
  // Amber: hue 20..50 deg, S >= 0.45, V >= 0.45 (crack bodies #D09345, cores #F0B94E..#FFD27A, lip #F0B94E).
  static bool IsAmber(int r, int g, int b) {
    int mx = Math.Max(r, Math.Max(g, b)), mn = Math.Min(r, Math.Min(g, b));
    if (mx < 115 || mx != r || mx == mn) return false;
    double s = (mx - mn) / (double)mx; if (s < 0.45) return false;
    double hue = 60.0 * (g - b) / (double)(mx - mn); if (hue < 0) hue += 360.0;
    return hue >= 20.0 && hue <= 50.0;
  }
  public static string Run(string path, int hx, int hy, int hr) {
    using (var src = new Bitmap(path)) {
      string fmt = src.PixelFormat.ToString();
      int w = src.Width, h = src.Height;
      var bmp = src.Clone(new Rectangle(0, 0, w, h), PixelFormat.Format32bppArgb);
      var data = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
      byte[] px = new byte[data.Stride * h];
      Marshal.Copy(data.Scan0, px, 0, px.Length);
      int stride = data.Stride;
      bmp.UnlockBits(data);
      Func<int,int,int> A = (x, y) => px[y * stride + x * 4 + 3];
      int corner = 0;
      int cb = Math.Min(64, Math.Min(w, h));
      int[] cx = {0, w - cb, 0, w - cb}; int[] cy = {0, 0, h - cb, h - cb};
      for (int k = 0; k < 4; k++)
        for (int y = cy[k]; y < cy[k] + cb; y++)
          for (int x = cx[k]; x < cx[k] + cb; x++) corner = Math.Max(corner, A(x, y));
      int x0 = w, y0 = h, x1 = -1, y1 = -1; long opaque = 0, key = 0, checker = 0;
      int spread = 0, spread8 = 0; int[] hist = new int[256], histAny = new int[256], histNoAmber = new int[256];
      long anyCnt = 0, noAmberCnt = 0, amber = 0, amberGlow = 0;
      double hsum = 0; long hcnt = 0;
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          int i = y * stride + x * 4;
          int b = px[i], g = px[i + 1], r = px[i + 2], a = px[i + 3];
          if (a >= 128) { if (x < x0) x0 = x; if (y < y0) y0 = y; if (x > x1) x1 = x; if (y > y1) y1 = y; }
          int mm = Math.Max(r, Math.Max(g, b));
          if (a >= 8) { histAny[mm]++; anyCnt++; }
          if (a > 8) { int s8 = Math.Max(Math.Abs(r - g), Math.Max(Math.Abs(g - b), Math.Abs(r - b))); if (s8 > spread8) spread8 = s8; }
          if (a >= 200) {
            opaque++;
            int m = mm;
            hist[m]++;
            bool isAmber = IsAmber(r, g, b);
            if (isAmber) { amber++; if (m >= 217) amberGlow++; } else { histNoAmber[m]++; noAmberCnt++; }
            int s = Math.Max(Math.Abs(r - g), Math.Max(Math.Abs(g - b), Math.Abs(r - b)));
            if (s > spread) spread = s;
            if ((r > 225 && g < 40 && b > 225) || (r < 40 && g > 225 && b < 40)) key++;
            if (s < 6 && m > 185) checker++;
          }
          if (hr > 0) {
            int dx = x - hx, dy = y - hy;
            if (dx * dx + dy * dy <= hr * hr) { hsum += a / 255.0; hcnt++; }
          }
        }
      }
      int p99 = P99(hist, opaque), p99Any = P99(histAny, anyCnt), p99NoAmber = P99(histNoAmber, noAmberCnt);
      string res = string.Format(CultureInfo.InvariantCulture,
        "size={0}x{1} format={2} corner_a={3} a8={4} aw8={5} centre_a={6} opaque={7:F3} bbox={8},{9},{10},{11} p99_max={12:F3} spread={13} key_px={14} checker={15:F3}",
        w, h, fmt, corner, A(8, 8), A(w - 8, h - 8), A(w / 2, h / 2), (double)opaque / (w * h),
        x0, y0, x1, y1, p99 / 255.0, spread, key, opaque > 0 ? (double)checker / opaque : 0.0);
      res += string.Format(CultureInfo.InvariantCulture, " p99_any={0:F3} p99_noamber={1:F3} amber={2:F4} amber_glow={3:F4} spread8={4}",
        p99Any / 255.0, p99NoAmber / 255.0, opaque > 0 ? (double)amber / opaque : 0.0, opaque > 0 ? (double)amberGlow / opaque : 0.0, spread8);
      if (hr > 0) res += string.Format(CultureInfo.InvariantCulture, " hollow_a={0:F3}", hcnt > 0 ? hsum / hcnt : 0.0);
      bmp.Dispose();
      return res;
    }
  }
}
"@
}
try {
  $full = (Resolve-Path -LiteralPath $Path).Path
  Write-Output ("{0}: {1}" -f ([System.IO.Path]::GetFileName($full)), [MapVerify]::Run($full, $HX, $HY, $HR))
} catch {
  Write-Error "verify.ps1: $($_.Exception.Message)" -ErrorAction Continue
  exit 1
}
