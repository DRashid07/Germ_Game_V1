You are the UI icon artist for a mobile game. Read STYLE.md in this folder first and
follow its HARD RULES (microbes have NO FACE — no eyes, no mouth).

Twelve icons of this game's set are already APPROVED: ref/approved_icon_set_1.png and
ref/approved_icon_set_2.png (shown on a blue test background). Make SIX MORE that
belong to exactly the same set: Brawl Stars-style chunky glyphs, THICK black outline
(#04090B, about 4% of canvas width), bright saturated colours, soft 3D cel shading lit
from the TOP-LEFT, one crisp glossy highlight. Readable at 40x40 pixels — few, big
shapes, no fine detail.

Use your built-in image generation tool (image_gen). Save final files into ./out/
with exactly these names. Work only inside this folder. Python is NOT installed.

## Common
- 1024x1024, subject centred, filling about 80% of the canvas.
- TRANSPARENT background with real alpha. No tile, badge, frame or circle behind the
  glyph, no drop shadow onto a background, no glow outside the outline.
- No text, letters or numbers.

## Class icons (shown next to the class name on each character card)
1. out/class_swift.png — class "SWIFT" (fast). A bold double chevron / speed arrow
   pointing right with two motion streaks behind it, warm amber-orange (#FFB43D).
2. out/class_control.png — class "CONTROLLER". A round spider-web-like NET: a ring
   with 6 straight spokes and one inner ring, glowing violet (#A96BFF).
3. out/class_guard.png — class "GUARDIAN". A chunky rounded SHIELD, blue (#4D9BFF)
   with a lighter rim and a small glossy bubble emblem in the middle.

## Super-ability icons (shown on the character's info page)
4. out/super_trichocyst.png — "TRİXOSİST": an explosive burst — a laym-green
   (#7CFF5B) core with many sharp pale needles shooting outward in all directions,
   a few small pale balls breaking apart. Violent, fast.
5. out/super_net.png — "AKSOPODİYA TORU": a laym-green round microbe core with long
   straight spokes and a glowing cyan (#2FE8E0) web stretched between the spoke tips,
   two pale food balls caught in the web and being pulled in.
6. out/super_cyst.png — "SİSTLƏŞMƏ": a laym-green blob curled up inside a hard,
   glossy, faceted protective SHELL/bubble (pale cyan-white, thick and armoured),
   a small ball bouncing off the shell with a tiny impact spark.

## Transparency — this is where earlier attempts FAILED
image_gen sometimes answers "transparent background" by PAINTING A GREY CHECKERBOARD
into the pixels (24-bit RGB, no alpha). That is unusable. The workflow that worked in
this project before: generate the icon, then run a second image_gen EDIT on it that
removes the background and outputs real transparency, preserving the subject exactly.

VERIFY every file with PowerShell + System.Drawing before accepting it: it must load as
Format32bppArgb AND the pixels at (8,8) and (width-8,height-8) must have alpha 0.

## Quality loop
Look at every result yourself. Reject and redo (max 3 tries per icon) if: any
face-like feature on a microbe, any text, missing thick black outline, a tile/badge
behind the glyph, the alpha check fails, or it does not match the approved sets.

Finish with a short report: each file, pixel size, alpha verification result, and the
exact prompt used.
