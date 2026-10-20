You are the logo designer for the mobile game "Germ Arena". This is ROUND 2 — a polish
round on logos you already drew. Read STYLE.md in this folder first: palette, top-left
light and "microbes have NO FACE" apply. Its "no text, no logos" rule does NOT apply:
this job is the logo itself.

The owner's brief is unchanged: the logo must fit the game's current design, be SIMPLE —
not flashy like a typical AI-generated logo — and feel like a PREMIUM game. Round 1's
concept A is already in the game as the boot splash (centred on plain #070F12 while the
game loads). The owner asked to keep working on the logos.

## Files in ./ref
- round1_logo_a.png — round-1 concept A (stacked GERM / ARENA). Currently shipped.
- round1_logo_c.png — round-1 concept C (round petri-dish mark + stacked wordmark).
- round1_a_on_menu.png — concept A placed over the menu background, for context.
- menu_screenshot.png — the current home screen (style the logo must belong to).
- lettering_baloo2.png — "GERM ARENA" in the game's heading font, Baloo 2 ExtraBold.
- hero_amoeba.png — approved faceless lime microbe (material reference).
- menu_bg.jpg — the menu background art (use it only for previews).

## Art-director critique of round 1 (fix ALL of these)
Concept A:
1. The deep-teal depth/extrusion is GRAINY and mottled (visible noise and colour
   speckle). It must be one clean flat colour, #0E3A40, with a crisp #04090B edge.
2. The highlights on ARENA are pale-green smudges on ivory — they read like stains.
   Use ONE consistent highlight language for all nine letters: a small crisp rounded
   capsule near the top-left of each letter, white/near-white (#FFFFFF at ~70% over the
   face colour, i.e. #D8FFC8 on lime and #FFFFFF on ivory). Same size and angle on every
   letter of a line. No blobs, no smears.
3. The near-black outline is thin and slightly uneven for a game logo next to this UI.
   Make it about 1.4x heavier and perfectly uniform around every letter and the whole
   lockup (outer contour), like the chunky buttons in menu_screenshot.png.
4. The counters are cramped — the A counters almost close up at small sizes. Open the
   counters of A and R a little (still Baloo-2-like) so they read at 300 px wide.
5. Keep what works: the layout, the GERM lime / ARENA ivory hierarchy, both lines the
   same width, the Baloo-2 spirit, the short depth. Do NOT change the spelling.
Concept C:
6. The petri-dish ring is dark teal on a dark background and nearly disappears. Make the
   ring a visible glass-edge teal (#2B5963 face with a #04090B outline, thin lighter
   #2FE8E0 inner rim line at most 2 px), same outline weight as the letters.
7. The mark is too large next to the wordmark and the germ is a generic splat. Make the
   mark exactly as tall as the two-line wordmark, the germ a rounder, calmer amoeba-like
   blob (like hero_amoeba.png's silhouette, simplified), lime with 3 unequal pale balls
   inside, one small top-left highlight. No face.
8. Its wordmark must use exactly the corrected concept-A rendering, so A and C are one
   family.

## Deliverables (put finals in ./out)
1. out/logo_a2.png — concept A with fixes 1–5. This is the main candidate.
2. out/logo_a3.png — logo_a2 plus ONE small identity detail that says "germ" without
   adding clutter. Pick the single best idea, for example: the crossbar of the G ends in a
   small round pale cell ball (#D9FFC0, like the game's food balls), or the counter of
   the R in GERM holds one tiny pale cell ball. Exactly one detail, subtle, and the logo
   must still read as a clean wordmark. No microbe face.
3. out/logo_c2.png — concept C with fixes 6–8.

Every final: landscape 1536x1024, lockup centred at about 80–85% of the width, nothing
cropped, TRANSPARENT background with real alpha (counters, gaps between letters and
words, and the inside of the petri ring must be transparent). Spelling exactly
G E R M / A R E N A, nothing else (no tagline, no TM).

Still banned: glow, bloom, neon, lens flare, rays, sparkles, stars, particles, bubbles,
drips, chrome, metal, gold, gems, glass effects, rainbow or many-stop gradients, noise or
grain, photoreal 3D, shields, banners, ribbons, wings, crowns, swooshes, frames, badges or
plates behind the text, drop shadows onto a background, and any face on a microbe.

## How to work
- Use your built-in image generation tool (image_gen). Work only inside this folder.
  Python is NOT installed; use PowerShell + System.Drawing for checks and previews.
- Prefer EDITING the round-1 files (they are the approved base) over new generations, so
  the letterforms stay recognisable. Do a fresh generation only if edits cannot fix it.
- Transparency trap: image_gen sometimes PAINTS a checkerboard instead of real alpha.
  The project's working method: do the art pass, then a separate background-extraction
  edit that outputs real transparency and preserves the art exactly.
- VERIFY each final with PowerShell + System.Drawing: Format32bppArgb; alpha 0 at (8,8)
  and (width-8,height-8); report the alpha at the centre of the first A's counter (in
  the open part below the crossbar) and, for c2, at the centre of the ring's empty band
  between ring and germ. Also composite each final over solid #FF40C0 (magenta) at full
  size and LOOK at it: every place meant to be empty must show magenta, with no dark
  plugs, grey fringe or halo.
- Previews in ./work for each final: preview_<name>_dark.png (1600x720, #070F12, logo
  at 45% width + a 300 px copy bottom-left), preview_<name>_menu.png (menu_bg.jpg scaled
  to 1600x900, logo 700 px wide centred), preview_<name>_magenta.png.

## Quality loop
Inspect every result closely at full size and at 300 px. Reject and redo (max 3 tries
per deliverable) if: any letter is misspelled, malformed or changed in style; the depth
is not flat; the highlights are inconsistent; the outline is uneven; any banned effect
appears; a microbe reads as having a face; the alpha checks or the magenta check fail.

Finish with a short report in English (also saved as REPORT.md): each file, pixel size,
the alpha measurements, what changed vs round 1, which candidate you recommend for the
boot splash and why, and the exact prompts used.
