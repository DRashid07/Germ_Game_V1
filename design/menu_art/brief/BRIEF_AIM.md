You are the UI icon artist for a mobile game. Read STYLE.md in this folder first and
follow its HARD RULES (no text, no faces, no UI screenshots).

The game is getting Brawl Stars-style AIMING in battle. A TAP on the fire button shoots
at the nearest enemy automatically (a rough auto-aim). For a precise shot the player
HOLDS the fire button and DRAGS it like a joystick: a knob follows the thumb, an aim
line is drawn from the player's microbe, and releasing the thumb fires along that line.
We need FOUR new in-battle HUD pieces for this.

Attached images:
- ref/ingame_hud.png — a real battle frame. The fire button is the big dark disc with
  the green ring at the lower right. This is where the new pieces will live: small, over
  dark teal water, next to glowing microbes. They must read instantly at small size.
- ref/icon_practice.png, ref/icon_settings.png, ref/icon_link.png,
  ref/super_trichocyst.png — icons of this game that are already APPROVED. STYLE
  REFERENCES ONLY: match their chunky Brawl Stars-style glyph rendering, THICK
  near-black outline (#04090B, about 4% of the canvas width), soft 3D cel shading lit
  from the TOP-LEFT and one crisp glossy highlight. Do not copy their subjects.

## The big difference from the approved icons: MONOCHROME, TINTABLE
The game paints each of these pieces in the PLAYER'S OWN COLOUR at runtime by
multiplying the image with that colour (lime, cyan, pink, amber… it changes per
player). So every piece must be drawn in NEUTRAL WHITE AND GREY ONLY:
- lit faces pure white #FFFFFF, mid shading light grey #D4DCDE, deepest shading
  #9AA6A9, the glossy highlight pure white;
- outlines and any dark detail near-black #04090B;
- absolutely NO hue anywhere — no green, no cyan, no blue tint in the greys, no coloured
  glow. White becomes the player's colour in the game, grey becomes a darker shade of
  it, black stays black.

## Common
- 1024x1024, subject centred.
- TRANSPARENT background with real alpha. No tile, badge, frame or circle behind the
  glyph, no drop shadow onto a background, no glow outside the outline.
- No text, letters or numbers anywhere.
- Few big shapes; each piece must stay readable at 48x48 pixels.

## The four pieces
1. out/hud_fire.png — the FIRE BUTTON icon (sits in the middle of the big round fire
   button, about 90 px on a phone). One chunky glossy BALL — the projectile microbes
   shoot in this game — flying toward the UPPER-RIGHT, with THREE short thick rounded
   speed streaks trailing behind it toward the lower-left (the streaks get shorter and
   thinner away from the ball, like a comet's tail, separated from each other by clear
   gaps). The ball takes about 45% of the glyph's width. Subject fills about 80% of the
   canvas.
2. out/hud_aim_knob.png — the AIM KNOB that sits under the thumb while dragging. A
   perfectly ROUND chunky glossy disc, seen straight from the front, filling about 86%
   of the canvas. Cut into its face is a bold CROSSHAIR in near-black: a small solid
   centre dot and four short thick rounded ticks pointing up, down, left and right
   that start near the centre and stop well before the rim (no full lines across). A
   thin darker inner ring just inside the outer outline gives it the feel of a pressed
   button. Strictly symmetric.
3. out/hud_target.png — the TARGET LOCK reticle that pops around the enemy the
   auto-aim picked. FOUR thick rounded CORNER BRACKETS arranged on a circle around an
   EMPTY centre — like the four corners of a square viewfinder, but each bracket gently
   curved to follow a circle. Each bracket is a chunky white-to-grey bar with the thick
   black outline. The whole CENTRE (about 60% of the canvas) must be EMPTY and fully
   transparent — the enemy microbe shows through it. Strictly symmetric, subject fills
   about 90% of the canvas.
4. out/hud_aim_arrow.png — the ARROWHEAD at the far end of the aim line. One chunky
   rounded CHEVRON pointing RIGHT (east, toward +X), like a bold ">" shape made of two
   thick bars meeting at a rounded tip, with a slight bevel. Not a full arrow — no shaft.
   Symmetric about the horizontal centre line. Subject fills about 70% of the canvas.

## Transparency — this is where earlier attempts FAILED
image_gen sometimes answers "transparent background" by PAINTING A GREY CHECKERBOARD
into the pixels (24-bit RGB, no alpha). That is unusable — and here it is even more
dangerous, because the pieces themselves are white and grey. The workflow that worked
in this project before: generate the piece, then run a second image_gen EDIT on it that
removes the background and outputs real transparency, preserving the subject exactly.
Watch the empty areas INSIDE shapes too (the reticle's whole centre, the gaps between
the fire icon's streaks, the inside of the chevron's notch): those must be genuinely
transparent, not grey checkers.

VERIFY every file with PowerShell + System.Drawing before accepting it: it must load as
Format32bppArgb AND the pixels at (8,8) and (width-8,height-8) must have alpha 0. For
hud_target.png also check that the pixel at the exact centre has alpha 0. For
hud_aim_knob.png check that the centre pixel is OPAQUE and near-black (the crosshair
dot). Also measure, for every file, the largest |R-G|, |G-B|, |R-B| over opaque pixels:
it should stay under 24 (neutral greys). Python is NOT installed — use PowerShell.

Use your built-in image generation tool (image_gen). Save the final files into ./out/
with exactly these names. Work only inside this folder.

## Quality loop
Look at every result yourself. Reject and redo (max 3 tries per piece) if: any colour
hue, any text, missing thick black outline, a tile/badge/backing circle behind the
glyph (the knob IS a disc — that is the subject, not a backing), the alpha check fails,
the reticle's centre is not empty, or it does not match the approved set's rendering.

Finish with a short report: each file, pixel size, alpha and neutrality verification
results, and the exact prompts used.
