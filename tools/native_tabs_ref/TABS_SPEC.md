# Native iOS 26 TabView — measured (iPhone 17 Pro, 402×874 pt, scale 3, screenshots of `RefTabs`)

Launch args of the reference: `light`, `five` (5 tabs), `min` (tabBarMinimizeBehavior .onScrollDown).

## Geometry (pt)
- Bar height **62** (186 px); bottom edge **21.3** pt above the screen's bottom; stadium (radius = height/2).
- 3 tabs: bar width **274** (x 63.7…337.7), tab pitch **85.7**, padding bar edge → first tab **8.5**.
- 5 tabs: bar 359 pt wide (x 21…380: margin ≈ 21.5), pitch 68.7 — the tabs shrink to fit the screen.
- Selected capsule: **pitch + 7.6** wide (extends 3.8 past its tab each side), **53.7** high, inset **4.15** from the bar's top/bottom, stadium.
- Icon glyph (SF Symbol, ~25.7 × 22.7 pt) top **12.7** below the bar's top; label caps start 41.3 below it; gap glyph → caps ≈ 6.
- Label **10 pt**, semibold-ish; ~40 pt wide for "Settings".

## Colours
- Capsule over the bar: dark theme white ≈ **20 %** ((37,31,59) → (79,74,97)); light theme black ≈ **6.5 %** ((186,178,221) → (175,168,205)).
- Selected tab: system tint (blue), unselected: primary label colour (white dark / near-black light).
- Glass: dark tone, soft bright rim top/left, 1 px outline; the pressed capsule is a lens (see GlassSegmentedControl).

## Press / hold (native, tap held 5 s on a tab; screenshot 3 px/pt)
- The **whole bar swells**: 274 → 288.7 pt wide (×1.054), 62 → 63.7 pt high; all its content (icons, labels: "Settings" 121 → 128 px) scales alike.
- The capsule turns into a **clear glass lens** 115 × 72 pt (rest 93.3 × 53.7; in bar units +15.8 × +14.6) that overhangs the bar; strong rim refraction, bright hairline, no tone lift.
- Inside the lens the content is **magnified ≈ ×1.22** (icon 77 → 94 px, label 80 → 102 px) and tinted with the accent colour; outside the lens the icons keep their colour.
- A tap on another tab: the lens grows (≈0–25 ms real), travels to the tapped tab while the finger is down (≈40–150 ms real, 80 pt), the page content swaps under it at ≈120 ms, then the lens shrinks back to the capsule 150–300 ms after release. Slow-motion recording (×10, 30 fps sampling, `tab1.mov`) — measured by eye and by the tint centroid, **not** fitted to spring parameters; our spring (k 380, ζ 0.67 ≈ ω 19.5 rad/s) lands 90 % in ≈ 120 ms, the same order.
- Drag with release exactly between two tabs (x = 244, the midpoint) settles on the nearer-by-velocity tab (native chose the *left* one, Tasks).

## Minimize on scroll (`tabBarMinimizeBehavior(.onScrollDown)`) — native does it
Scrolling down collapses the bar into a **round button 47.7 pt** (x 28.3…76, same vertical centre as the bar, bottom 28 pt above the screen's bottom) showing only the selected tab's icon in the tint colour (no label); scrolling up expands it again.

## Lens travel on a tab switch (slow-motion ×10, 30 fps sampling, rim peaks in a row between the icons and the labels)
Lens left/right rims per frame (`lens_nat.json` method: bright thin peaks in rows 186–192 of the 3 px/pt crop): L 243→423 px, R 530→742 px over 170 ms real (width 95.7 → 106 pt, top edge 24.3 → 20.3 pt, bottom 98 → 90 pt in crop units).
Centre `x(τ) = xf + e^(−ζωs)[(x0−xf)cos ωd s + (v0+ζω(x0−xf))/ωd · sin ωd s]` with xf = 201 pt, x0 = 115 pt, v0 = 0, **ω = 0.016 rad/ms (16 rad/s), ζ = 0.85**, t0 = 8 ms after the touch: rmse 1.3 pt (L alone 0.5 pt, R 2.3 pt; a free-edge fit gives ω 0.014, ζ 0.7…0.8, period ≈ 450 ms) — no visible overshoot. Ours before: ω 19.5, ζ 0.67 (k 380, c 26); now k 256, c 27.2 (ω 16, ζ 0.85). Our real-time recording (60 fps): left rim 527 → 665 px in 117 ms after the first frame (77 % of the way) — the same shape.
Not fitted: a separate spring per edge (the lens grows with the press spring, 96 → 106 pt wide during the move vs ours 98 → 112); the icon/label colour changes with the lens window (tint inside the lens) rather than with a crossfade on selection.

## Light theme, held (native vs ours)
Lens clear, white hairline; the bar `(186,178,221)` glass over the dark page; no light band under the lens (ours drew the segmented-control band: removed with `lightBand: false`). Remaining: the native lens has saturated rainbow caps at its top and bottom edge (the dark page refracted through the rim, 22 px tall); ours shows a plain soft rim — stronger refraction (≥1.3) makes the tinted tab layer mirror into the caps, so `refraction` stays 0.9.

## Tools and IoU of the lens outline (tab switch, quick tap; ours Chats→Tasks / Tasks→Settings vs native Inbox→Tasks)
Tools: `lens_track.py` (continuity-based rim tracker for L/R/T/B from the rest capsule on), `compare_lens.py` (stadium IoU per time step, our time axis shifted to the best match, bottom taken as 332 − T because the lens is symmetric about the bar centre and the bottom rim is the noisiest edge), `window_table.py`, `run_ours.sh`, `rim_stats.py`.
Native lens (3 px/pt, from the rest capsule 210…480 × 85…246): width pops 273 → 310 px within ~20 ms and creeps to 320 px at 200 ms (L moves 1.4 px/ms from ~15 ms on, no visible start-up), height 159 → 209 px with a ~60 ms time constant (T 87 → 61).
**Method ceiling:** two native slow-motion runs of the same tap (`tab1.mov`, `tab2.mov`) compared by the same script give a mean IoU of only **0.935** (0–50 ms 0.874, 50–100 0.936, 100–150 0.956, 150–205 0.973): frame quantisation (3.3 ms real) and rim-detection noise (±3 px) cost more than the 0.97 target, so ≥ 0.97 cannot be demonstrated by this method.
| window | native vs native | ours before | ours now (best of 2 runs) | ours now (2nd run) |
|---|---|---|---|---|
| mean 0–205 ms | 0.935 | 0.891 | **0.923** | 0.899 |
| 0–50 ms | 0.874 | 0.736 | 0.880 | 0.853 |
| 50–100 ms | 0.936 | 0.846 | 0.904 | 0.829 |
| 100–150 ms | 0.956 | 0.949 | 0.950 | 0.937 |
| 150–205 ms | 0.973 | 0.965 | 0.957 | 0.964 |
(“before” = the tab bar as of the previous report: press reported by the tap recogniser, lens at full size.) The 50–100 ms window of our runs suffers from dropped frames of the debug build at the page swap (a 60 fps recording shows our lens standing still for 1–2 frames there); that is not the lens's own motion.
What was wrong and is fixed: (1) the press started when the finger lifted (a tap recogniser reports its down only after the 100 ms press timeout while a drag competes) — now a raw `Listener` starts it at pointer down; (2) every plain tap fired `onHorizontalDragCancel` which released the lens at once — now ignored unless a drag started; (3) lens hold after a tap 170 ms after the up (native: ≈ 230 ms from the down, then it shrinks).

## Rim brightness (peak luminance of the hairline minus local background; sides, held tab)
| theme | native | ours before | ours now (specular 2.8) |
|---|---|---|---|
| dark | +74 (146 / 72) | +34 | +66 (113 / 47) |
| light | +21 (231 / 210) | +11 | +16 (223 / 207) |
The native lens's top and bottom edges carry saturated caps of the refracted page; ours does not (see above).

## Drag
Native released exactly between two tabs (x = 244, finger came from the left) → the left tab; ours chose the right one — now the tie breaks to the left as well (−1e−6 bias). A release off the midpoint was not recorded on the native side.

## Colours of the label/icon on selection
Natively the accent appears inside the lens window (and stays on the selected tab after the lens shrinks); there is no separate crossfade: our tint layer does exactly that, so nothing more to implement.

## Not measured
Per-edge springs (frame-by-frame fit as in MORPH_SPEC), accessory mode (the kit has none).

## Ours vs native after the change (same simulator, dark)
| | native | ours |
|---|---|---|
| bar x | 191…1013 px | 193…1012 px |
| bar y | 2372…2558 px | 2373…2558 px |
| capsule | 280 × 161 px | 280 × 161 px |

## Pressed (held on Tasks), ours vs native, px at 3 px/pt
| | native | ours |
|---|---|---|
| bar | 170…1036 | 172…1034 |
| lens x | 428…773 | 432…775 |
| lens y (from bar crop top) | 58…274 | 58…272 |
| collapsed button | 85…228 × 2395…2538 | 86…228 × 2395…2537 |

## Bottom accessory (`tabViewBottomAccessory`, reference arg `acc`; iPhone 17 Pro, 3 px/pt)
**Expanded:** a separate glass plate (stadium, same material as the bar) over the bar: x 63…1142 px = 21…380 pt (the bar's own margins), y 2205…2347 px → **47.3–47.7 pt high**, 8.7 pt above the bar (bar top 2373). With an accessory the **bar is as wide as the screen allows** (359 pt, 21.5 pt margins, not 274) and the tabs share it: pitch 114.2 pt, selected capsule 124 pt wide (ext 4.9 pt per side; 3.8 at pitch 85.7). The bar's height (62) and bottom (21.3 pt) are unchanged.
**Inline (bar collapsed to the 47.7 pt round button):** the plate is in the button's row: button x 85…228 px (28.3 pt from the edge), plate x 253…1121 px = **8.3 pt right of the button**, 28.3 pt from the right edge, y 2395…2537 px = the button's own row (centre 2466 px = the bar's centre line), 47.7 pt high. The compact content is shown ("Playing" + play only).
**Transition** (x10 slow-motion, 30 fps): the content swaps to the compact one in the first ≈ 20 % (plate still above), the plate narrows from both sides, travels down over the old bar position (which shrinks into the button) and right to its inline place; back up on expansion with ≈ 2 pt undershoot. Plate top edge T(τ) fitted with the spring form of MORPH_SPEC §2.1:
| direction | x0 → xf (px, crop) | t0 | ω | ζ | rmse |
|---|---|---|---|---|---|
| collapse (plate down) | 105 → 295 | 96 ms after the scroll threshold | 0.012 rad/ms | 0.60 | 1.2 px (to 245 ms only) |
| expand (plate up) | 295 → 105 | 68 ms | 0.022 rad/ms | 0.75 | 1.3 px |
Left and right edges were not tracked separately (the right-rim tracker was lost against the page edge); they interpolate linearly with the same progress in ours.
**Ours** (`GlassTabBar.accessory` / `accessoryBuilder(context, placement)`, `onAccessoryTap`, `accessoryGlass`): expanded plate y 2205…2345 px (native 2205…2347), x 63…1141 (63…1142), bar 2372…2557 (2373…2557) — within 2 px (0.7 pt). Inline in our recording: button 86…226, plate 255…1119 (native 85…228 / 253…1121). The layout height of the bar stays that of the expanded state (plate + gap + bar), so the pages' insets do not change while it collapses (not measured natively how the content insets change). Not measured: the pressed look of the plate, the light theme, a tab change with the plate inline.

### Content of the accessory during the transition (native, ×10 slow motion, 1-frame steps = 3.3 ms real)
The content is **not cross-faded**: "Now Playing / Artist / play / next" is replaced by "Playing / play" **within one frame** (≤ 3.3 ms real) at ≈ 20 % of the plate's travel, while the plate is still above the old bar position and starting to narrow. The note icon and the play button stay at the left/right padding of the plate (14 pt from its ends) and ride with its edges; the next button simply is not in the compact layout; the title is a different text ("Playing", one line, at the same x as the first line of the long title). No scale, blur or alpha ramp on the content was visible; the content is cut by the plate's shape while it narrows.
Ours: `accessoryBuilder` now cross-fades both layouts by default (alpha inside the plate between 10 % and 30 % of the bar's collapse progress, no layer over the glass; content cut to the plate), `accessoryCrossfade: false` gives the native one-frame cut; `accessoryProgressBuilder(context, progress)` (0 = expanded … 1 = inline, continuous, springs included) is for shared elements that travel: the `switcher` example keeps the icon and play button, fades the two-line title out and "Playing" in, and folds the next button by `progress`. Checked frame by frame (our recording, 60 fps): no swap, the title fades through the middle of the travel.
