# Your Look × Performance Profiles — Phase 1 investigation (2026-10-22)

Scope: ASCENDANT Ω request "YOUR LOOK Integration & Performance Profiles".
Investigation only. No code was changed. All paths are relative to
`mods/` in the LÖVE save directory (`%APPDATA%\pokemon-love2d\mods\`).
Versions inspected: VOXEL_ASCENDANT 3.1.0 (VASC), kanto_ascendant 6.7.35 (KASC).

Companion doc: `docs/YOUR_LOOK.md` (user-facing summary, still accurate).

---

## 1. Where Your Look lives

Your Look ("Dein Look", internal name **Setup Card**) is entirely inside
VOXEL_ASCENDANT. KASC does not implement it; it only links to it.

| File | Lines | Role |
| --- | ---: | --- |
| `VOXEL_ASCENDANT/lib/SetupCard.lua` | 835 | The screen: pages, draft, Apply/Cancel, keyboard/pad/touch input, landscape draw, boot-time auto-open, `mod.exports.setupCard` |
| `VOXEL_ASCENDANT/lib/SetupPortrait.lua` | 81 | Same draft/actions in a single-column portrait touch layout (Android/phones) |
| `VOXEL_ASCENDANT/lib/SetupPreview.lua` | 170 | Isolated live previews (sprites, HD, Cobblemon/Stadium models) |
| `VOXEL_ASCENDANT/lib/SetupBenchmark.lua` | 256 | Two-minute in-game graphics check on a throwaway game state |
| `VOXEL_ASCENDANT/lib/SetupMeasurement.lua` | 62 | Paired A/B/B/A frame-time statistics (median, p95, MAD, verdicts) |
| `VOXEL_ASCENDANT/lib/SetupEffects.lua` | 172 | Effect result store, GPU probe, scene observers (shadow/light/water/AA actually ran) |
| `VOXEL_ASCENDANT/lib/SetupEffectRules.lua` | 33 | Compatibility rules (mobile AA blocked, texture limit, conservative profile) |
| `VOXEL_ASCENDANT/lib/SetupImageCheck.lua` | 17 | Coarse flicker / black-ground detection from 16×16 readbacks |
| `VOXEL_ASCENDANT/lib/SetupLocale.lua` | 32 | EN default, DE via `translation-german-universal` |

Key functions in `SetupCard.lua`:

- `M.new(game, settings, opts)` (l.30) builds the page list from the live
  VASC `SETTINGS` entries passed in by `main_gen1.lua`; every row is a
  draft copy of a real setting (`self.draft[key]`).
- `Screen:step(dir)` (l.337) is where composite choices fan out into
  concrete keys: `_device` (l.347–353), `_people`, `_battleGraphics`,
  `_world`, `_quality` (l.375–377).
- `Screen:apply()` (l.412) validates the whole transaction, then writes
  through each setting's owner (`setValue`) and persists `dein-look/v1`.
- `Screen:startBenchmark / stopBenchmark / applyRecommendations`
  (l.507–574) drive the graphics check and copy verdicts into the draft.
- `Screen:update(dt)` (l.583) handles up/down/left/right/a/b/start/select
  via the engine's abstract input, so keyboard and controller work
  through `lib/VascControls.lua` (F3 = START, pad mapping at l.317).
- `Screen:pointer(p)` (l.619) handles mouse and touch; portrait hit
  boxes come from `SetupPortrait.draw`.
- `M.install(mod, config)` (l.768) wraps `Game.draw`, `Game.touchpressed`,
  the `input.pointer` hook and `core.update` (auto-open once per save
  via `StartupPrompts`), registers the `VascSetup` screen and exports
  `mod.exports.setupCard = {title, description, schema='vasc/dein-look/v3', open, new}`.

Wiring:

- Gen 1 host: `VOXEL_ASCENDANT/main_gen1.lua` l.2492 passes
  `setupCard=true` into `VascMenu.install`; `lib/VascMenu.lua` l.2206
  calls `SetupCard.install`, and `newHub` (l.2051–2059) inserts the
  "YOUR LOOK" row beside WARDROBE/SKINS.
- KASC: `kanto_ascendant/ascendant_menu.lua` l.286–293 looks up
  `VOXEL_ASCENDANT` exports and, when `setupCard` exists, inserts a
  `your_look` row before SPRITE DOWNLOADS / DIAGNOSTICS. That is the only
  KASC-side code.
- Gen 2: **no reference at all.** `gen2/main.lua`, `VascMenuGen2.lua`,
  `Gen2QuickMenu.lua` never load SetupCard. `docs/YOUR_LOOK.md` says so
  explicitly: "Gen2 keeps its own existing hub without loading or
  advertising this screen."

Storage (per save, through `V.mod.storage`): `dein-look/v1` (draft,
page, done flag), `dein-look/effects-v1` (benchmark results keyed by a
hardware+settings fingerprint), `dein-look/light-test` (interrupted-test
marker).

Tests: `docs/YOUR_LOOK.md` points to `tests/setup_card/README.md`.
**That folder does not exist in the installed mod** (`VOXEL_ASCENDANT/tests`
is absent). The native regression drivers live only in the source
repository, if anywhere.

### 1.1 What Your Look actually does (verified)

Pages after the compact rewrite (`M.new`, l.134–206): welcome → device →
people → pokémon (per-area sources) → dex → menus (team/PC layouts) →
battle → battle_controls → world → lighting ("Graphics check") →
summary. Optional sub-pages: people_detail, base, finish, battle_art,
world_detail, device_detail, lighting_detail, graphics_override.

Functional and reviewed as working from code:

- Draft/Apply/Cancel/"Save for later" with per-row validation against
  `setting:allows()`.
- Live previews for characters/Pokémon/dex/battle (`SetupPreview`),
  static demo captures for world/battle stages
  (`assets/setup-demo/*.png`), battle-controls canvas preview via
  `orasBattleHud.controlsPreview`.
- Temporary world tests: 10 s world-profile preview, 10 s detail
  compare, 2×5 s lighting compare, 2-minute full graphics check.
- Keyboard, controller, mouse and touch (landscape + portrait).
- German localisation.

### 1.2 Device page vs. DEVICE profile — the duplicate system

The Your Look device page does **not** use `DeviceProfile`. `Screen:step`
l.347–353 hard-codes its own three tiers:

| Your Look `_device` | sceneResolution | shadows | water | aa | lights | arenaCamera | **deviceProfile** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| mobile / safe | economy (720p) | off | sky | 0 | all off | fixed3x | **custom** |
| integrated | balanced (1080p) | on | sky | 0 | all off | fixed3x | **custom** |
| desktop | native | on | full | 0 | all off | fixed3x | **custom** |
| keep | restore initial values | | | | | | initial |

and the optional `_quality` row (l.375–377: low/balanced/high) is a
second copy of the same table without the lighting/camera part.

Consequences:

1. Finishing Your Look always leaves VASC's DEVICE row on **CUSTOM**, so
   AUTO/LIGHT/BALANCED/HIGH never apply again until the player changes
   DEVICE by hand. Rows that DeviceProfile manages but Your Look does not
   touch (sky, clouds, skyEvents, horizon, mesh preload, daynight) keep
   whatever the previous profile wrote.
2. The two tables drift: DeviceProfile HIGH on Gen 1 uses
   `sceneResolution=balanced` (1080p), Your Look "desktop" uses `native`.
3. Your Look's benchmark fingerprint includes `deviceProfile` and
   `_device` (SetupEffects l.333), so a profile change invalidates
   results — correct, but it means a unified profile must be part of the
   draft, not applied behind it.

---

## 2. Device Profiles (the existing performance-preset system)

Two near-identical copies, one per generation, both 252 lines:

- `VOXEL_ASCENDANT/lib/DeviceProfile.lua` — Gen 1 (KASC/VASC Kanto).
- `VOXEL_ASCENDANT/gen2/lib/DeviceProfile.lua` — Gen 2 (Johto).

Shared design (identical in both): `setting` key `deviceProfile`,
hardware signature `_deviceProfileHardwareV1`, `configure(bindings)`,
`apply(game, selected)` writes every bound child row, `markCustom`
flips to CUSTOM when a child changes (ignoring host echoes of the preset's
own values), `restore(game, created)` on boot re-runs AUTO when the save
moved to different hardware, `effective()` resolves AUTO. Internal tier
names are still the legacy `eco / handheld / max`; public names are
`light / balanced / high`.

Differences (from `diff`):

| | Gen 1 `lib/DeviceProfile.lua` | Gen 2 `gen2/lib/DeviceProfile.lua` |
| --- | --- | --- |
| Values | auto, light, balanced, high, ultra, custom | + **uncap** ("UNCAPED") |
| ULTRA | distinct tier: only rows that declare `ultra=` get a value; the rest get `binding[LEGACY_BINDING.ultra]` = `binding[nil]` = **nil → not written** | `PROFILE_ALIAS.ultra = "max"` → visually identical to HIGH; differs only in streaming depth (see §3) |
| AUTO resolution | `Performance.detect`: low→light, balanced→balanced, else **high** | `Gen2PerformancePolicy.resolveAuto`: low→eco, everything else **handheld** (BALANCED) |
| Policy hook | none | `Gen2PerformancePolicy` (build slices, apron, pending slice) |
| Mod id fallback | `VOXEL_ASCENDANT` | `VASC4J` |

Bindings (what each profile actually writes):

Gen 1 — `main_gen1.lua` l.1518–1543 `DeviceProfile.configure{...}`:

| Row | LIGHT (eco) | BALANCED (handheld) | HIGH (max) | ULTRA |
| --- | --- | --- | --- | --- |
| sky | flat | full | full | *(unset)* |
| clouds | off | on | on | *(unset)* |
| skyEvents | off | flyers | full | *(unset)* |
| weather | auto | auto | auto | *(unset)* |
| HorizonWall (scenery) | full | full | full | *(unset)* |
| ChunkMesher.preload | false | true | true | *(unset)* |
| shadows | false | true | true | *(unset)* |
| water | sky | sky | sky | full |
| daytime | cycle | cycle | cycle | *(unset)* |
| sceneResolution | economy | economy (balanced on Steam Deck) | balanced | native |
| aa | 0 | 0 | 0 | 2 |

Gen 2 — `gen2/lib/VascRendererOptions.lua` l.462–496 `configureProfile()`:

| Row | LIGHT | BALANCED | HIGH / ULTRA / UNCAP |
| --- | --- | --- | --- |
| sky | flat | full | full |
| clouds | off | on | on |
| skyEvents | off | flyers | full |
| scenery (HorizonWall) | full | full | full |
| shadows | false | true | true |
| water | sky | sky | full |
| aa | 0 | 0 | 2 |
| sceneResolution | economy | balanced | native |
| renderScale (Quality) | 3 (1/3) | 2 (1/2) | 1 (FULL) |
| shadowQuality | off | low | high |

Gen 2 deliberately does **not** bind WEATHER and DAYTIME any more
(comment "STICKY CHOICES (Nuno 18 Oct)"); Gen 1 still binds both, so a Gen 1
profile switch resets a manual weather/daytime pick. Gen 2 also binds
`renderScale`/`shadowQuality` (Quality module) which Gen 1 lacks.

Menu exposure:

- Gen 1: `main_gen1.lua` l.951 adds `DeviceProfile.setting` with
  `row = DeviceProfile.row` (shows `AUTO/HIGH`). Description text says
  AUTO = HIGH on desktops (true on Gen 1 only).
- Gen 2: schema entry in `gen2/options.lua` l.587–600; appears in
  `VascMenuGen2.lua` PERFORMANCE section (l.59–61) and in the quick menu
  (`Gen2QuickMenu.lua` l.143). Changes flow through
  `VascRendererOptions.handleOptionsChanged` → `DeviceProfile.externalChanged`.
  **Its description is stale**: it claims "AUTO selects LIGHT, BALANCED or
  HIGH from the engine's initial hardware tier" but
  `Gen2PerformancePolicy.resolveAuto` never returns HIGH.

---

## 3. How profiles reach the renderer (Gen 2) — Connected World, LOD, scenery, budgets

Gen 2 is the only generation with profile-driven workload budgets.

`gen2/lib/Gen2PerformancePolicy.lua`:

- `SLICES` (l.313–327): per-frame mesh build budgets `urgent/idle/covered`
  in seconds per tier: max 8/3/6 ms, handheld 8/2.5/6, eco 6/1.5/4,
  custom 8/2.5/6, **uncap 30/10/45 ms**.
- `PENDING` (l.419): mobile "no voxel frame yet" slice 14 ms (10 ms eco, 45 ms uncap).
- `APRON_BLOCKS` (l.334–340): scenery apron around a map in 4-tile blocks:
  max 6, handheld 2, eco 1, custom 2, uncap 6.
- `tuneHorizon` (l.355): UNCAP raises `HorizonWall.BUILD_RESUMES_PER_CALL/BUILD_TIME_BUDGET` to 256 / 20 ms.
- Load timer writes `DATEIEN/VASC-LOAD-TIMES` per build burst (l.371–406).

Consumers of `DeviceProfile.effective()` / `setting:get()`:

- `gen2/lib/ChunkMesher.lua` l.79–86 `apronBlocks()`, l.2203–2209
  `buildSlices()`, l.2247–2254 `pendingSlice()`.
- `gen2/lib/Structures.lua` l.66–73 `configuredRingTiles()` (structure
  analysis ring = apron × 4 tiles).
- `gen2/lib/OpenWorldStreaming.lua` l.42–53: `DESKTOP_DEPTH` — connected
  rings per **selected** value: light 1, balanced 2, high 3, ultra 4,
  uncap ∞; overrides the zoom-based ladder in every camera when
  `openWorld` is on. This is the only place ULTRA differs from HIGH on Gen 2.
- Options that are *not* profile-managed but belong to the same budget
  family (`gen2/options.lua`): `openWorld` (l.68), `connectedWorld` (l.75),
  `worldZoomRange` (l.229), `localLights` (l.705), `shadows` master
  (l.720), `scenery`/`outdoorHorizon`/`cavePanorama` (l.678–698),
  `terarriumLighting`, `liveDisplay/liveFps` (l.19–21).

"LOD" as a user setting does not exist in either generation. The nearest
levers are `renderScale` (SCENERY DETAIL, stars/fog/clouds budget),
`sceneResolution`, apron blocks and connected ring depth. Internal mesh
LOD exists only in `Gen2MeshCache`/`ChunkMesher` without a setting.

Gen 1 has none of this: no `Gen2PerformancePolicy`, no Connected
World/open-world depth, no apron tiers. Gen 1 profile effects stop at the
binding table in §2 plus `ChunkMesher.preloadSetting`.

Related but separate: `mods/potato_voxel/lib/QualityMode.lua` is an
older standalone mod with HIGH/MEDIUM/LOW/POTATO modes over its own
VOXEL SETTINGS knobs. It is **not** loaded by VASC and should not be
merged; it is only a naming precedent for "Potato".

---

## 4. Performance measurement — what exists and what it can report

| Capability | Where | Verified behaviour |
| --- | --- | --- |
| Average FPS, mean frame time | `lib/PerformanceOverlay.lua` (LIVE DISPLAY, both gens via SETTINGS/options), `PerformanceDiagnostics.snapshot` | Half-second windows; `love.timer.getFPS` or 1000/p50 |
| p50 / p95 / p99 frame time | `lib/PerformanceDiagnostics.lua` l.987–1004 `frameWindow()` over a rolling sample ring (`SAMPLE_CAPACITY`) | Available. **"1 % low FPS" = 1000 / p99 ms** is derivable with no new sampling; it is not computed or displayed today |
| Frame-time spikes / hitches | `lib/RuntimePerformanceDiagnostics.lua` `frameBoundary` (>50 ms draw-start intervals, last 24 + worst 8 with per-subsystem CPU breakdown); `PerformanceDiagnostics.observe` logs FRAME-STALL ≥250 ms | Memory-only, Gen 1 + Gen 2 (installed from both `main_gen1.lua` l.193 and `gen2/main.lua` l.551) |
| CPU-side timings | `RuntimePerformanceDiagnostics.wrap` instruments VoxelScene, ChunkMesher.pump, ShadowMap, WaterReflection, HorizonWall, LocalLights, etc.; `PerformanceOverlay` CPU ms via `os.clock` | Wall-clock inclusive/self time; explicitly "GPU execution not measured" |
| Memory | `collectgarbage('count')` (Lua KiB) and `love.graphics.getStats().texturememory` | Texture/canvas memory only, never VRAM or process RSS |
| Loading / streaming interruptions | `PerformanceDiagnostics.beginLoad/endLoad` (startup, map, battle), `sceneryRing` admission/visible/failure tracking, `Gen2PerformancePolicy` load bursts, `ChunkMesher.setPresentationPending` | Available, mobile-oriented ring summary |
| GPU time / utilisation | — | **Not measurable in LÖVE 11.5**; every module already labels this. Keep it that way |
| Paired A/B effect cost | `SetupBenchmark` + `SetupMeasurement.compare` | Gen 1 only (uses `src.battle.BattleState`, `OverworldController`, Gen 1 maps ROUTE_1/PALLET_TOWN/ROUTE_21) |

So the in-game preview system can report average FPS, p95/p99 (hence a
1 % low proxy), spike counts, CPU subsystem time, Lua/texture memory
and load interruptions — all from existing code. The Setup benchmark
itself only keeps median/p95/MAD per 4 s window; it would need
`frameSamples` kept long enough (≥100 samples) for a meaningful p99.

---

## 5. Gen 1 vs Gen 2 comparison

| Aspect | Gen 1 (KASC + VASC `main_gen1.lua`) | Gen 2 (VASC `gen2/`) |
| --- | --- | --- |
| Your Look screen | Yes, full | **Absent** |
| Device profile | `lib/DeviceProfile.lua`, 5 tiers + CUSTOM | `gen2/lib/DeviceProfile.lua`, + UNCAP |
| AUTO on desktop | HIGH | BALANCED |
| ULTRA | Partial (only water/aa/resolution) | = HIGH visuals + 4 rings |
| Profile → budgets | none | slices, apron, pending, ring depth |
| Weather/daytime in profile | yes (resets manual picks) | removed on purpose |
| renderScale / shadowQuality | not present | bound |
| Settings transport | `ModSetting` objects + `SETTINGS` list | static schema in `options.lua` + `VascRendererOptions` bridge |
| Menu | `lib/VascMenu.lua` hub, YOUR LOOK row | `VascMenuGen2.lua` sections (PERFORMANCE, VISUAL SETTINGS), `Gen2QuickMenu` |
| Live display | PerformanceOverlay | same module via options `liveDisplay/liveFps/liveCpu/liveGpu` |
| Benchmark | SetupBenchmark | none |
| Shared code | DeviceProfile core logic, ModSetting, PerformanceOverlay, PerformanceDiagnostics, RuntimePerformanceDiagnostics, Sky/Weather/Shadows/Water/AntiAlias modules (`gen2` reaches them through `BaseV.require`) | |

---

## 6. Findings: functional, incomplete, broken

Functional:

- Your Look on Gen 1: draft flow, previews, tests, Apply, touch/pad/keyboard, DE.
- DeviceProfile apply/CUSTOM detection on both gens, including the
  hardware-signature reset.
- Gen 2 profile → streaming/build budgets.
- Diagnostics stack (overlay, p95/p99 ring, hitch capture, load phases).

Incomplete / inconsistent:

1. Your Look bypasses DeviceProfile and forces CUSTOM (§1.2). Two more
   preset tables (`_device`, `_quality`) duplicate it.
2. Gen 1 ULTRA writes only three rows; sky/clouds/shadows/preload keep
   stale values when switching e.g. LIGHT → ULTRA
   (`lib/DeviceProfile.lua` `bindingValue`, `LEGACY_BINDING` has no `ultra`).
3. AUTO means different things per generation (HIGH vs BALANCED on the
   same desktop). Gen 2 option description claims HIGH is possible.
4. Gen 1 profile resets WEATHER/DAYTIME; Gen 2 fixed this on 18 Oct.
5. Gen 2 has no Your Look entry point at all; Johto players never see the
   guided setup or the graphics check.
6. The graphics check is hard-wired to Gen 1 (`BattleState.newWild`,
   `OverworldController`, Kanto map ids).
7. `docs/YOUR_LOOK.md` references `tests/setup_card/README.md`, which is
   missing from the installed mod.
8. "1 % low", spike counts and load interruptions are collected but not
   surfaced in Your Look; the overlay shows FPS/ms/CPU/texture only.
9. Naming: internal `eco/handheld/max`, public `LIGHT/BALANCED/HIGH`, Your
   Look `mobile/integrated/desktop/safe`, quality `low/balanced/high`,
   potato_voxel `POTATO/LOW/MEDIUM/HIGH`. Four vocabularies for one idea.

Nothing was found that is outright crashing; the issues are coherence and
coverage, not faults.

---

## 7. Reuse map (what to keep as-is)

Reuse directly:

- `SetupCard.lua` page/draft/Apply machinery, `SetupPortrait`, `SetupPreview`, input handling.
- `DeviceProfile.lua` core (both copies are the same algorithm; the
  Gen 2 copy with `PROFILE_ALIAS` + policy hook is the better base).
- `Gen2PerformancePolicy.lua` tables as the budget definition for Gen 2.
- `PerformanceDiagnostics.frameWindow` / `RuntimePerformanceDiagnostics` for metrics.
- `SetupMeasurement.compare` A/B/B/A logic for "compare two profiles".
- `VascRendererOptions.configureProfile` as the Gen 2 binding table.

Do not reuse:

- `potato_voxel/lib/QualityMode.lua` (separate mod, different knobs).
- Your Look's private `_device` / `_quality` tables (replace with DeviceProfile).

---

## 8. Integration plan (proposal, for review before any code)

Priority order; each step is independently shippable.

**P1 — One profile vocabulary (both gens).**
Extend `DeviceProfile.setting` values to
`auto, potato, low, medium, high, ultra, custom` (Gen 2 keeps `uncap` as
an explicit extra after ultra). Keep stored legacy values readable via
`PROFILE_ALIAS` (`light→low`, `balanced→medium`, `eco/handheld/max`
likewise) so existing saves migrate silently. Move the Gen 2 copy's
`PROFILE_ALIAS`/policy hook into the Gen 1 copy or, better, make
`lib/DeviceProfile.lua` the single file and have `gen2/lib/DeviceProfile.lua`
return it (same pattern `gen2` already uses with `BaseV.require`).
Fix Gen 1 ULTRA by giving every binding an explicit `ultra` (and
`potato`) value. Define POTATO as LOW plus: `sceneResolution=scale50`
(Gen 2) / `economy` (Gen 1), `renderScale=4`, `shadowQuality=off`,
`skyEvents=off`, `clouds=off`, `localLights=false`, horizon `bitmap`.
Decide AUTO once: proposal = engine tier low→POTATO/LOW, balanced→MEDIUM,
high→HIGH on desktop, MEDIUM on Android/iOS/Steam Deck; same rule in
both gens.

**P2 — Your Look drives DeviceProfile instead of bypassing it.**
Replace the `_device` fan-out (`SetupCard.lua` l.347–353) and `_quality`
(l.375–377) with `draft.deviceProfile = <tier>` and let the draft preview
rows be filled from `DeviceProfile` bindings (`bindingValue(binding,
tier)`) so the detail pages show what the tier will write. On Apply,
write `deviceProfile` **last** so `markCustom` is not triggered by the
preset's own child writes (the `applying` guard already handles this when
`apply()` is the writer). "Keep existing graphics settings" maps to
leaving `deviceProfile` untouched. Strong lights stay off by default
in every tier as today (`localLights/battleLights/terarriumLighting`
are not profile children; keep them Your Look-owned).

**P3 — Gen 2 entry point.**
Register `VascSetup` on Gen 2 with a reduced page set (device, people,
pokémon, battle, menus, world, summary) and the graphics check disabled
until P5. Blockers to remove first: `SetupCard` requires
`OverworldBattle`, `HorizonWall`, `V.require('Weather').clock` and
Gen 1 setting objects; Gen 2 exposes plain option keys through
`VascRendererOptions`. A thin adapter that wraps `mod.options` keys as
`{key, values, labels, get, setValue}` (the same shape `M.new` already
builds for `PokemonUi` schema entries at l.36–44) is the least invasive
route. Add the row to `VascMenuGen2` (PERFORMANCE or a top-level entry) and
to `Gen2QuickMenu`.

**P4 — Metrics surfaced in Your Look and the overlay.**
Add to `PerformanceOverlay` an optional "1 % LOW" value = 1000 / p99 from
`PerformanceDiagnostics.frameWindow()` and a spike counter from
`RuntimePerformanceDiagnostics.hitches`. In Your Look's device page show
the last 3-second window: avg FPS, 1 % low (only when
`sampleCount ≥ 100`, otherwise "n/a"), hitches >50 ms, Lua KiB, texture
MiB, last map-load ms. Label everything "CPU-side / LÖVE statistics"; no
GPU numbers.

**P5 — Profile compare test (both gens).**
New mode in `SetupBenchmark.plan`: `{profile=A} {profile=B} {B} {A}` in
the current scene, 6 s each, reusing `SetupMeasurement.compare`. Reports
median/p95/p99 delta and hitch count per profile and offers "Keep A /
Keep B". On Gen 2 the throwaway-state part (`M.start` save cloning,
`BattleState.newWild`) must be replaced by a world-only run on the
current map, no battle fixture. Revert path = existing `M.restore`.

**P6 — Cleanup.**
Update the Gen 2 `deviceProfile` option description, Gen 1 SETTINGS text,
`docs/YOUR_LOOK.md`, `docs/CONTENT_PRESETS.md`; remove the dead
`tests/setup_card` reference or restore the drivers.

Out of scope (per request): ORIGAMI_ASCENDANT (Gen 3), potato_voxel,
any renderer optimisation.

---

## 9. Risks

- **Save migration.** `deviceProfile` is persisted in three stores
  (`bucket()` in DeviceProfile: save options, loader, nested loader).
  New value names must be aliased in `resolve`, `apply`, `restore` and
  `externalChanged`, or old saves bounce to AUTO.
- **CUSTOM flapping.** Any writer that sets child rows before the profile
  row triggers `markCustom`. Your Look's Apply must respect the ordering
  or set `applying` through `DeviceProfile.apply`.
- **Gen 2 host echoes.** `mod.options_changed` echoes preset writes after
  `apply()`; `externalChanged` already ignores matching echoes, but new
  child keys (renderScale, shadowQuality on Gen 1) must be added to
  `PROFILE_CHILD` in `VascRendererOptions`.
- **Benchmark validity on Gen 2.** Streaming builds run during the window;
  `SetupMeasurement.compare` will return `stalls`/`drift` unless the map
  is fully resident first (`ChunkMesher` queue empty) — add a readiness
  gate before timing.
- **Android.** AA is blocked on mobile (`SetupEffectRules` mobile-aa);
  POTATO/LOW must not advertise AA. Benchmark pauses on focus loss; a
  profile compare must survive the app being backgrounded.
- **Previously tried approaches** (do not repeat): resolution scaling
  alone (rc19: Celadon tail got worse at 1280×715), shadow re-use
  without geometry invalidation (rc20: "no general FPS gain proven"),
  per-frame light tables (PERFORMANCE_FOLLOWUP §3). Profiles should
  bundle apron/ring/slice budgets with visual rows, not only pixels.

## 10. Required tests before/after each step

1. Profile round-trip: set each tier on Gen 1 and Gen 2, restart, confirm
   every bound row equals the table in §2 and DEVICE is not CUSTOM.
2. Legacy save with `deviceProfile=handheld`/`balanced`/`max` loads as
   MEDIUM/HIGH, not AUTO or CUSTOM.
3. Your Look Apply with tier X leaves DEVICE = X; changing one child row
   afterwards flips to CUSTOM exactly once (`lastCustomReason` logged).
4. Gen 1 ULTRA from LIGHT writes sky/clouds/shadows/preload (regression for §6.2).
5. Gen 2: OpenWorldStreaming depth 1/2/3/4/∞ per tier with `openWorld=on`,
   apron blocks per tier via `ChunkMesher._buildSlices` / `apronBlocks`.
6. Overlay 1 % low shows "n/a" below 100 samples and a value above.
7. Profile compare: cancel mid-run restores previous settings and scene
   (`M.restore`), verified on desktop and one Android device.
8. Touch portrait layout of the new device page on a 1080×2400 phone.
9. German strings present for every new row (SetupLocale).
10. No change in `mods/kanto_ascendant` other than, optionally, the label
    of the existing `your_look` row.
