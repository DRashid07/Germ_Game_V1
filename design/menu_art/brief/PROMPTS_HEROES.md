> Codex-in öz hesabatıdır (dəyişdirilməyib, yalnız fayl yolları nisbi edilib). `raw/`-dakı qəhrəmanlar Codex-in son "1024-ə sığdırma" addımından ƏVVƏLKİ 1254×1254 alfa-lı orijinallardır — ikiqat nümunələmə olmasın deyə oyuna onlar emal olunub.

Completed all three hero assets. Opaque checkerboard attempts were rejected; the delivered files contain real transparency.

| File | Size | Alpha verification |
|---|---:|---|
| [hero_ciliate.png](../raw/hero_ciliate.png) | 1024×1024 | `Format32bppArgb`; both tested corners alpha 0 |
| [hero_heliozoan.png](../raw/hero_heliozoan.png) | 1024×1024 | `Format32bppArgb`; both tested corners alpha 0 |
| [hero_amoeba.png](../raw/hero_amoeba.png) | 1024×1024 | `Format32bppArgb`; both tested corners alpha 0 |

Final transparent content bounds are approximately 800×786, 800×781, and 800×772 respectively.

### Exact ciliate prompts

```text
Use case: stylized-concept
Asset type: 1024x1024 mobile game lobby hero character cutout
Input images: Image 1 is the authoritative in-game KİRPİKLİ/ciliate species identity reference. Image 2 is an approved hero-design reference only; preserve its egg-shaped body, eight glossy internal spheres, darker inner lobe, tapered cilia fringe, and S-curved whip tail, but do not copy its painted checkerboard pixels.
Primary request: Create the same faceless laym-green ciliate as a polished chunky 3D-ish premium mobile-game character, in a 3/4 view from slightly above, tilted slightly forward as if darting ahead.
Scene/backdrop: isolated cutout with genuine transparent alpha background; no backdrop pixels, no ground, no floor, no stage, no cast shadow, no ambient glow outside the silhouette.
Subject: slipper/egg-shaped squishy jelly body; dense fringe of short tapered light-green cilia all around, thick at roots and fine at tips; one long whip tail from the back, thick at root and thin at end, gentle S-curve; exactly eight clearly visible glossy pale-green ammo spheres inside a darker cytoplasm lobe.
Style/medium: clean stylized soft-3D cartoon render, Brawl-Stars-like lobby polish while matching the simple readable in-game species design.
Composition/framing: full body centered, nothing cropped, entire tail and every cilium visible, creature fills about 75–80% of a square canvas with safe padding.
Lighting/mood: one global light from top-left; crisp specular highlight top-left; deeper green bottom-right shading; visible dark underside shadow band for 3D volume; thin bright rim light along bottom-right edge.
Color palette: body #7CFF5B, top-light tint near #C9FFB8, body shadow near #3D8A2C, spheres #D9FFC0 with small white highlights, outline #04090B.
Materials/textures: glossy slightly translucent jelly membrane, darker inner cytoplasm visible through it.
Constraints: thick continuous dark #04090B outline around the whole body silhouette, visually about 1.5–2% of canvas width; cilia and tail each have a thinner #04090B outline; energetic fast-species pose; exactly one creature; no facial anatomy.
Avoid: eyes, pupils, paired eye-like dots, mouth, eyebrows, face, text, letters, numbers, logos, UI, watermark, signature, checkerboard, colored background, vignette, scenery, floor, shadow, halo, glow spill, cropping.
```

```text
Use case: background-extraction
Asset type: 1024x1024 mobile game character cutout PNG
Primary request: Keep the ciliate creature itself exactly unchanged in design, pose, colors, outline, eight internal spheres, cilia, tail, lighting, scale, and framing. Remove every checkerboard/background pixel and output the creature as a clean cutout with a genuinely transparent alpha-channel background.
Constraints: preserve the entire creature and all edge detail; outside the outlined silhouette must contain zero background imagery and zero colored pixels; no checkerboard painted into pixels; no matte; no floor; no cast shadow; no halo; no glow spill; no text; no face; no crop.
```

### Exact heliozoan prompts

```text
Use case: stylized-concept
Asset type: 1024x1024 mobile game lobby hero character cutout
Input images: Image 1 is the accepted ciliate hero and authoritative family-style reference for material, palette, outline weight, lighting, 3/4 volume, and polish. Image 2 is the authoritative in-game AYAQLI/heliozoan species identity reference for its round body and radiating bead-tipped spokes.
Primary request: Create the same faceless laym-green heliozoan as a polished chunky 3D-ish premium mobile-game character, in a 3/4 view from slightly above, standing sturdily on its lower spokes like a spider/walker.
Scene/backdrop: isolated cutout with genuine transparent alpha background; no backdrop pixels, no ground, no floor, no stage, no cast shadow, no ambient glow outside the silhouette.
Subject: round spherical squishy jelly body; 9 long thin straight radiating axopodia spokes, each ending in one small glossy green bead; lower spokes angle down as planted legs, upper spokes fan outward like a sunburst; about eight clearly visible glossy pale-green ammo spheres arranged organically inside a darker cytoplasm lobe, not as a face.
Style/medium: match Image 1 exactly: clean stylized soft-3D cartoon render, premium mobile-game lobby polish, simple readable in-game species design.
Composition/framing: full body centered, nothing cropped, all spokes and tip beads fully visible, creature fills about 75–80% of square canvas with safe padding.
Lighting/mood: same one global light from top-left; crisp specular highlight top-left; deeper green bottom-right shading; visible dark underside shadow band for 3D volume; thin bright rim light along bottom-right edge.
Color palette: body #7CFF5B, top-light tint near #C9FFB8, body shadow near #3D8A2C, spheres #D9FFC0 with small white highlights, outline #04090B.
Materials/textures: glossy slightly translucent jelly membrane, darker inner cytoplasm visible through it.
Constraints: thick continuous dark #04090B outline around whole round body, visually about 1.5–2% of canvas width; every spoke and bead has a thinner #04090B outline and a bright thin green core; exactly one creature; sturdy slow-species pose; no facial anatomy.
Avoid: eyes, pupils, paired eye-like dots, mouth, eyebrows, face, text, letters, numbers, logos, UI, watermark, signature, checkerboard painted into pixels, colored background, vignette, scenery, floor, shadow, halo, glow spill, cropping, bent tentacles, cilia, whip tail.
```

```text
Use case: background-extraction
Asset type: 1024x1024 mobile game character cutout PNG
Primary request: Keep the heliozoan creature itself exactly unchanged in design, pose, colors, outline, eight straight bead-tipped spokes, eight internal spheres, lighting, scale, and framing. Remove every checkerboard/background pixel and output the creature as a clean cutout with a genuinely transparent alpha-channel background.
Constraints: preserve the entire creature and every spoke/bead edge; outside the outlined silhouette must contain zero background imagery and zero colored pixels; no checkerboard painted into pixels; no matte; no floor; no cast shadow; no halo; no glow spill; no text; no face; no crop.
```

### Exact amoeba prompts

```text
Use case: stylized-concept
Asset type: 1024x1024 mobile game lobby hero character cutout
Input images: Image 1 is the accepted ciliate hero and authoritative family-style reference for jelly material, palette, outline weight, lighting, 3/4 volume, and polish. Image 2 is the authoritative in-game AMÖB/amoeba species identity reference for its bean/blob silhouette, layered gel, and star crystals.
Primary request: Create the same faceless laym-green amoeba as a polished chunky 3D-ish premium mobile-game character, in a 3/4 view from slightly above, with a squishy sneaky crawling pose.
Scene/backdrop: isolated cutout with genuine transparent alpha background; no backdrop pixels, no ground, no floor, no stage, no cast shadow, no ambient glow outside the silhouette.
Subject: soft asymmetric bean/blob body with 2–3 broad bulging pseudopod lobes reaching forward and one small bumpy tail bulge at the back; clearly show two nested body layers: a lighter more translucent outer gel rim/ectoplasm and a more saturated inner endoplasm; inside the endoplasm include about eight clearly visible glossy pale-green ammo spheres plus several small pale star-shaped crystal particles, arranged organically and never as a face.
Style/medium: match Image 1 exactly: clean stylized soft-3D cartoon render, premium mobile-game lobby polish, simple readable in-game species design.
Composition/framing: full body centered, nothing cropped, every pseudopod and tail bulge fully visible, creature fills about 75–80% of square canvas with safe padding.
Lighting/mood: same one global light from top-left; crisp specular highlight top-left; deeper green bottom-right shading; visible dark underside shadow band for 3D volume; thin bright rim light along bottom-right edge.
Color palette: outer gel #C9FFB8 to #7CFF5B, inner body saturated green near #65D946 with shadow near #3D8A2C, spheres #D9FFC0 with small white highlights, pale mint star crystals, outline #04090B.
Materials/textures: glossy slightly translucent jelly membrane; outer ectoplasm visibly wraps around the inner endoplasm.
Constraints: thick continuous dark #04090B outline around the complete outer blob silhouette, visually about 1.5–2% of canvas width; inner layer has a slimmer dark-green boundary; exactly one creature; no facial anatomy.
Avoid: eyes, pupils, paired eye-like dots, mouth, eyebrows, face, text, letters, numbers, logos, UI, watermark, signature, checkerboard painted into pixels, colored background, vignette, scenery, floor, shadow, halo, glow spill, cropping, cilia, spokes, legs, whip tail.
```

```text
Use case: background-extraction
Asset type: 1024x1024 mobile game character cutout PNG
Primary request: Keep the amoeba creature itself exactly unchanged in design, pose, colors, thick outline, two gel layers, pseudopod lobes, seven internal spheres, star crystals, lighting, scale, and framing. Remove every checkerboard/background pixel and output the creature as a clean cutout with a genuinely transparent alpha-channel background.
Constraints: preserve the entire creature and all lobe edges; outside the outlined silhouette must contain zero background imagery and zero colored pixels; no checkerboard painted into pixels; no matte; no floor; no cast shadow; no halo; no glow spill; no text; no face; no crop.
```