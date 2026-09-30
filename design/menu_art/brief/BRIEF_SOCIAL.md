You are the UI icon artist for a mobile game. Read STYLE.md in this folder first and
follow its HARD RULES (microbes have NO FACE — no eyes, no pupils, no mouth).

The game is getting a Brawl Stars-style FRIENDS and TEAM system: a friends list, friend
requests by player tag, team invites, a team leader, and a shareable team link. We need
FIVE new icons for it.

The images attached to this prompt are icons of this game's set that are already
APPROVED (mode_duo, icon_quests, icon_settings, class_guard). They are STYLE REFERENCES
ONLY — do not copy their subjects. Make the five new icons belong to exactly the same
set: Brawl Stars-style chunky glyphs, THICK near-black outline (#04090B, about 4% of the
canvas width), bright saturated colours, soft 3D cel shading lit from the TOP-LEFT, one
crisp glossy highlight. Readable at 40x40 pixels — few, big shapes, no fine detail.

Use your built-in image generation tool (image_gen). Save final files into ./out/ with
exactly these names. Work only inside this folder. Python is NOT installed.

## Common
- 1024x1024, subject centred, filling about 80% of the canvas.
- TRANSPARENT background with real alpha. No tile, badge, frame or circle behind the
  glyph, no drop shadow onto a background, no glow outside the outline.
- No text, letters or numbers anywhere. (A plain geometric PLUS SIGN is allowed where
  asked — it is a shape, not a letter.)

## The five icons
1. out/icon_friends.png — FRIENDS (the button that opens the friends list, shown in a
   dark blue square button). TWO faceless glossy jelly microbes side by side, one lime
   green (#7CFF5B) on the left, one cyan (#2FE8E0) on the right and slightly behind.
   They reach toward each other with short thick pseudopods that TOUCH in the middle,
   like a handshake of blobs; one small warm amber (#FFB43D) four-point sparkle at the
   point of contact. Each microbe shows 2–3 pale glossy balls (#D9FFC0) inside its
   body, like the approved mode_duo icon. It must read clearly as "two friends", and it
   must look different from mode_duo (there the two cells just overlap and do not reach
   for each other).
2. out/icon_add_friend.png — ADD FRIEND. ONE faceless glossy lime-green (#7CFF5B)
   microbe with 2–3 pale balls inside, and a big chunky PLUS SIGN badge overlapping its
   lower-right: a round bright-green (#39D353) disc with a thick white plus sign, both
   with the same thick black outline. The plus badge must stay readable at 40x40.
3. out/icon_crown.png — TEAM LEADER crown (shown small, above a teammate's head). A
   chunky rounded golden crown (#FFC83D body, deeper #E08A1E shading) with THREE
   rounded points; on top of each point sits a small pale glossy ball (#D9FFC0) instead
   of a jewel. Simple, bold, wider than it is tall, slight 3/4 tilt is fine.
4. out/icon_invite.png — TEAM INVITE (shown in an invitation pop-up). A chunky
   cream/ivory envelope (#FFF1D6 with warm #E9C48F shading), flap closed, sealed in the
   middle by a round lime-green (#7CFF5B) glossy seal shaped like a small faceless
   microbe blob with one pale ball inside. Slightly tilted, energetic, like the
   approved quest scroll.
5. out/icon_link.png — SHARE TEAM LINK. Two thick interlocking rounded CHAIN LINKS
   (pill-shaped rings) at a 45° diagonal, cyan (#2FE8E0) with a lighter top-left face
   and deeper teal (#138C8A) lower-right shading, one crisp glossy highlight per link.

## Transparency — this is where earlier attempts FAILED
image_gen sometimes answers "transparent background" by PAINTING A GREY CHECKERBOARD
into the pixels (24-bit RGB, no alpha). That is unusable. The workflow that worked in
this project before: generate the icon, then run a second image_gen EDIT on it that
removes the background and outputs real transparency, preserving the subject exactly.
Watch the gaps INSIDE shapes too (inside the chain links, between the crown points):
those must be genuinely transparent, not grey checkers.

VERIFY every file with PowerShell + System.Drawing before accepting it: it must load as
Format32bppArgb AND the pixels at (8,8) and (width-8,height-8) must have alpha 0. For
icon_link.png also check that the pixel at the centre of each ring hole has alpha 0.

## Quality loop
Look at every result yourself. Reject and redo (max 3 tries per icon) if: any
face-like feature on a microbe (two glossy dots side by side read as eyes — avoid),
any text, missing thick black outline, a tile/badge behind the glyph, the alpha check
fails, or it does not match the approved set.

Finish with a short report: each file, pixel size, alpha verification result, and the
exact prompt used.
