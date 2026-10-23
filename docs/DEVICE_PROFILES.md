# Device profiles (DEVICE row) — unified model (Stage 1–3, 2026-10-22)

One data model for both editions:

- `lib/DeviceProfileCore.lua` — tiers, labels, aliases, fallback chain,
  binding lookup, `valuesFor`, the shared apply/CUSTOM/restore logic, the
  simple-row cycling rule and the AUTO receipt.
- `lib/DeviceAutoProfile.lua` — AUTO: GPU rule table, CPU tier (cores +
  benchmark), start tier and the measured loop (Stage 3, PERF AUTO FIX).
- `lib/DeviceProfile.lua` (Gen 1) and `gen2/lib/DeviceProfile.lua` (Gen 2)
  — thin edition files (`Core.new{}`), UNCAPED only on Gen 2.
- `main.lua` lists both shared files in `GEN2_SHARED_CARD_CORE`.

## The simple choice (what players see)

| Shown | Stored key | Who it is for |
| --- | --- | --- |
| AUTO | `auto` | Picks a profile for this device |
| MINIMUM | `potato` | Very old phones and weak laptop graphics: smooth first, plain look |
| LOW | `low` (old: light, eco) | Older phones and basic laptops |
| MEDIUM | `medium` (old: balanced, handheld) | Most phones, laptops and Steam Deck |
| HIGH | `high` (old: max) | Gaming PCs and top phones |
| ULTRA | `ultra` | Powerful gaming PCs: everything on |
| CUSTOM | `custom` | Your own mix (set automatically when you change a detail) |

`potato` is only an internal key (kept so other code can read the tier
list); every label and help text comes from `Core.LABELS` /
`Core.DESCRIPTIONS`, which is where a name change is made.

UNCAPED (`uncap`, Gen 2 only) is still a stored DEVICE value, but it is no
longer in the simple ladder: the DEVICE row skips it when cycling
(`Core.skipInSimpleCycle`), and the ADVANCED / TINKERING entry owns it as
"UNLIMITED LOADING" (ON writes `uncap`, OFF returns to AUTO). Old saves that
hold `uncap` keep reading as UNCAPED.

## ADVANCED / TINKERING

One entry next to PERFORMANCE on both hubs, for people who want to push a PC
to the maximum or squeeze an old machine. It only regroups existing rows (no
copies, nothing new to store):

- Gen 2: 3D RESOLUTION, SCENERY DETAIL, ANTI-ALIASING, SHADOWS quality,
  OPEN WORLD, CONNECTED WORLD, OPEN WORLD ZOOM LIMIT, UNLIMITED LOADING.
- Gen 1: 3D RESOLUTION, ANTI-ALIASING, SHADOWS, WATER, PRELOAD, SCENERY,
  OUTDOOR HORIZON, DESKTOP NEIGHBOUR RING.

Changing any of them switches DEVICE to CUSTOM, as before.

## What each tier writes

Gen 1 (`main_gen1.lua`):

| Row | MINIMUM | LOW | MEDIUM | HIGH | ULTRA |
| --- | --- | --- | --- | --- | --- |
| sky | flat | flat | full | full | full |
| clouds | off | off | on | on | on |
| skyEvents | off | off | flyers | full | full |
| weather | auto | auto | auto | auto | auto |
| scenery | **off** | full | full | full | full |
| preload | false | false | true | true | true |
| shadows | false | false | true | true | true |
| water | **off** | sky | sky | sky | full |
| daytime | cycle | cycle | cycle | cycle | cycle |
| sceneResolution | **scale50** | economy (720p) | economy (720p; 1080p on Steam Deck) | balanced (1080p) | native |
| aa | 0 | 0 | 0 | 0 | 2 |

Gen 2 (`gen2/lib/VascRendererOptions.lua`): same rows except weather/daytime
(player's own), plus renderScale (MINIMUM 1/4, LOW 1/3, MEDIUM 1/2, HIGH and
ULTRA FULL) and shadowQuality (MINIMUM off, LOW off, MEDIUM low, HIGH/ULTRA
high); water full and aa 2 from HIGH up; sceneResolution native from HIGH up.
ULTRA on Gen 2 equals HIGH's rows and adds the 4-ring Connected World depth.

Gen 2 budgets (`Gen2PerformancePolicy`): MINIMUM urgent 5 ms / idle 1 ms /
covered 3 ms, apron 1 block, pending 8 ms; LOW 6/1.5/4, apron 1, pending
10 ms; MEDIUM 8/2.5/6, apron 2, pending 14 ms; HIGH and ULTRA 8/3/6, apron
6, pending 14 ms; UNCAPED 30/10/45, apron 6, pending 45 ms (unchanged).
Connected rings (`OpenWorldStreaming`): MINIMUM 1, LOW 1, MEDIUM 2, HIGH 3,
ULTRA 4, UNCAPED unlimited.

## AUTO: how the tier is chosen (`lib/DeviceAutoProfile.lua`)

Step 1, at boot, from real data only (this table is the **GPU tier**, the
upper bound for the climb, not the starting tier): OS, CPU architecture, processor count,
renderer / vendor / device strings, texture size limit, desktop size, DPI,
and the Steam Deck receipt (`lib/DeviceHardware.lua`). First matching rule
wins; the table is data and can be corrected per device.

PC (Windows, Linux, macOS):

| Device | Tier |
| --- | --- |
| Steam Deck (AMD custom GPU 0405/0932, Van Gogh) | MEDIUM |
| texture size limit ≤ 4096 | LOW |
| ARM Linux handheld (PortMaster) | LOW |
| Apple M3 or newer (≥ 6 cores) | ULTRA; M1/M2 HIGH |
| NVIDIA RTX 30/40/50 series (≥ 6 cores) | ULTRA |
| NVIDIA RTX 20, GTX 16/10/9, Titan | HIGH |
| NVIDIA GTX 5–8 series, GeForce MX, GT | MEDIUM; older GeForce LOW |
| AMD RX 6700+/7000/9000 (≥ 6 cores) | ULTRA |
| AMD RX 6400–6600, RX 5000, RX 470–590, Vega 56/64, Radeon VII | HIGH |
| AMD RX 450–460/550–560, Ryzen "Radeon Graphics"/Vega iGPU, 7xxM/8xxM | MEDIUM; Radeon R2–R7/HD LOW |
| Intel Arc A5/A7/B, Arc Pro | HIGH |
| Intel Arc A3, Iris Xe/Plus, UHD 7xx | MEDIUM; UHD 6xx / HD Graphics LOW |
| software renderers (llvmpipe, SwiftShader, Microsoft Basic, VMware) | MINIMUM |
| unknown GPU | HIGH (MEDIUM with ≤ 2 cores) |

HIGH/ULTRA need at least 4 cores, otherwise MEDIUM.

Phone / tablet (Android, iOS):

| Device | Tier |
| --- | --- |
| texture size limit ≤ 4096, or ≤ 4 cores | MINIMUM |
| Apple A15+/M | HIGH; A12–A14 MEDIUM; A9–A11 LOW; older MINIMUM |
| Adreno 7xx/8xx | HIGH; Adreno 650–690 MEDIUM; Adreno 600–649 LOW; 4xx/5xx MINIMUM |
| Mali-G7x0+/G8xx/G9xx, Immortalis, Samsung Xclipse | HIGH; Mali-G6x0, G77/G78 MEDIUM; G7x (two-digit) / G68 / G57 / G5x LOW; G52 and older, T-series MINIMUM |
| PowerVR IMG B/C | MEDIUM; GT7/GX6/Rogue LOW; GE8/GE9/SGX MINIMUM |
| unknown | LOW |

Step 2, the **CPU tier**: the lower of a core-count tier (≥ 8 threads ULTRA,
≥ 6 HIGH, ≥ 4 MEDIUM, else LOW) and a single-thread Lua micro-benchmark run
once per session (3 runs, each capped at 15 ms wall time, best run counts;
score = work units per ms: ≥ 30000 ULTRA, ≥ 15000 HIGH, ≥ 6000 MEDIUM,
≥ 2000 LOW, below that MINIMUM). Unknown parts are ignored.

Step 3, the **start tier** = the lowest of: the GPU tier, the CPU tier, the
edition's historical AUTO rule (`resolveAuto`: LOW on a low engine tier,
otherwise MEDIUM on Gen 2) and `START_CEILING` = MEDIUM. Nothing starts at
HIGH or ULTRA without a measurement. Unknown GPU and CPU start at MEDIUM;
phones never above HIGH; Steam Deck at most MEDIUM. Weak phones start at
MINIMUM or LOW from the GPU table / benchmark.

Step 4, the **measured loop**, for as long as DEVICE is AUTO. CPU-side frame
time (`getDelta`, no GPU timing) is collected in 8-second windows (≥ 120
frames) of overworld play only: the first 10 s of the session, menus,
battles, the first 3 s after every map change (warps included) and frames
while maps are being meshed are skipped.

| Window | Action |
| --- | --- |
| p95 > 18 ms | one tier DOWN (repeats every window, floor MINIMUM) |
| p95 < 13 ms and p50 < 10 ms, two windows in a row | one tier UP |
| anything else | keep |

- UP never goes above min(GPU tier, CPU tier), never above HIGH on a phone,
  and never back to a tier this session already dropped from.
- The window after any change is a settle window (ignored).
- Still over budget at MINIMUM: the loop stays at MINIMUM with a steady
  30 FPS target and stops climbing for the session.

All thresholds are named constants in the measured-loop section of
`lib/DeviceAutoProfile.lua`. The current tier is stored as the AUTO receipt
`_deviceProfileAutoV2` (`version = 2`, hardware signature) and resumed next
launch on the same hardware. Older `_deviceProfileAutoV1` receipts (written
by the Stage 3 one-shot rule that started PCs at their GPU-table tier) are
deleted on load and never trusted. Logged as `[VASC] AUTO profile: …`
(start) and `[VASC] AUTO profile measured: …` (each change); diagnostics
events `device-auto-start` / `device-auto-step`. The DEVICE row shows
AUTO/<tier>. Moving the save to other hardware starts over. Selecting any
tier by hand ends AUTO and stops the loop; CUSTOM is still set when a
managed row is changed.

## Binding tables and the fallback chain

A binding is `{ setting = <ModSetting>, <tier> = <value>, ... }` with new
keys (`potato, low, medium, high, ultra, uncap`) or historical ones
(`eco, light, handheld, balanced, max`). Missing values fall through:
`potato → low → medium → high`, `ultra → high`, `uncap → ultra → high`.
Gen 1 ULTRA therefore receives HIGH's values for rows without an ULTRA
value (since Stage 1).

API (stable for other threads): `Core.TIERS`, `Core.LABELS`,
`Core.DESCRIPTIONS`, `Core.canonical`, `Core.bindingValue`,
`DeviceProfile.valuesFor(selection)`, `managedKeys()`, `bindings()`,
`effective()`, `autoFromTable()` (now the climb ceiling), `autoStart()`,
`autoDetect()`, `autoReceipt()`, `helpText()`.

## CUSTOM detection (unchanged)

Changing a bound row through its own setting or a host options event with a
value that differs from the preset marks CUSTOM; echoes of the preset's own
values do not. A stored CUSTOM whose hardware signature differs from the
current machine falls back to AUTO.

## AUTO view budget and load score (Gen 2)

Inside a tier, AUTO first makes the view lighter through the residency
budget (`Gen2SpatialResidency.setBudget`) and only drops a whole tier when
the budget is at its floor. Each bad window (p95 > 18 ms) moves one rung
down, each two quiet windows move one rung back up, and every change is
followed by one settle window:

| Rung | Budget |
| --- | --- |
| 0 | none (the tier as it is) |
| 1 | maps drawn × 0.75 |
| 2 | maps drawn × 0.5 |
| 3 | + full-detail radius × 0.75 |
| 4 | + full-detail radius × 0.5 |
| 5 | + camera reach × 0.75 |
| 6 (floor) | + camera reach × 0.5 |

"Maps drawn" is the tier's own count (never below 2). After a tier drop
the lower tier starts at rung 0; a step up happens only at rung 0. The
budget is cleared (`setBudget(nil)`) whenever DEVICE is not AUTO (any manual
tier or CUSTOM) and while any ADVANCED view row (range, detail, maps) is set
by hand; then the loop moves whole tiers as before. Gen 1 has no budget.

Saving: a measured window (and a ladder rung) only updates the AUTO receipt
in memory. The options are written at once when the tier changes, and
otherwise at the next covered moment (a menu, a battle or another screen on
top, a warp fade or map setup), never while walking: an options write is a
storage append that some hosts take tens of milliseconds for.

Load score: every real BODY build of the current map (the existing
`gen2-map-warmup` event, `result=ready`, `frames > 0`; cache hits are
ignored) adds its build time to a rolling list of the last 9 builds, kept in
the AUTO receipt (`loadMs`). It is RECORDED ONLY and never chooses or
changes a tier: wall-clock build time depends on the tier's own build
slices, the map's size, pauses and covers, so a lower tier would measure
itself as slower again. It will be replaced by a build CPU ping measured
inside the mesher. With at least 3 builds the median is logged:
`[VASC] AUTO load-score (record only): …`.

## Cache prebuild: goal, not a time limit (`gen2/lib/Gen2CachePrebuild.lua`)

Each off-screen map has a goal: its BODY mesh built and the cache entry
committed. There is no per-map time limit, so a slow device simply takes
longer. A map fails only when it **stalls**: no mesher or cache-writer
progress at all for a window that depends on the DEVICE tier
(`STALL_SECONDS`: ULTRA/UNCAPED 30 s, HIGH 45 s, MEDIUM 60 s, LOW 120 s,
MINIMUM 240 s, unknown 120 s). Only unpaused time counts. The prebuild pauses
while live map jobs are queued (the scene always has priority), during fades,
map setup and pending warps, and for any gap between ticks longer than 0.5 s
(menus, battles, loading). New maps are not started while paused. A failed
map is logged (`pc3-cache-prebuild-job`, result `failed`, `detail` with the
stall summary, `progressPct`) and the next map starts. Stops and the end of
the run are logged too (`pc3-cache-prebuild-stopped` / `-finished`).
