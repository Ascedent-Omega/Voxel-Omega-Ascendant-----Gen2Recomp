# Your Look / Dein Look

Gen1 visual setup, integrated from the reviewed setup-card prototype. It appears once per playthrough after the initial content offer, and can be reopened through F3 or VASC's main menu. KASC's updated menu opens the same screen when the companion is active. Adding KASC later offers its additional context.

Nine steps cover welcome, device profile, characters, overworld Pokémon, Pokédex, battles, world scenery, optional graphics checks, and Apply. Sources remain independently selectable for followers, wild Pokémon, fixed town Pokémon, and KASC/Wilds town spawns. Real art previews show availability; missing packs are identified, and Cobblemon needs no separate installation.

Opening, postponing or keeping the current setup does not apply graphics settings. Device presets and recommendations are drafts until Apply. Presets explicitly start strong lights off; choose Keep existing graphics settings to retain the current look. No fog profile is owned by this Card.

The optional graphics test uses an isolated temporary game state, repeated OFF/ON/ON/OFF measurements, manual image assessment, and independent effect results. Aborting restores the previous scene and settings. Uncertain measurements preserve choices; a GPU name is not a performance guarantee. Targeted tests last 24 or 40 seconds. Physical-device validation remains necessary.

English is the default. German follows the Universal translation mod's active German boot language. Since Stage 2 (2026-10-22) the same screen also serves Gold/Silver/Crystal: see the Stage 2 section below.

See tests/setup_card/README.md for the isolated native regression drivers.

## 2026-10-22 — Stage 1: device page uses the shared DEVICE profiles

The device page no longer carries its own preset table. Each choice maps to a
DEVICE tier (`SetupCard.DEVICE_TIER`: mobile/safe → LOW, notebook/handheld →
MEDIUM, gaming PC → ULTRA (chosen by Nuno, 22 Oct), plus explicit ULTRA and AUTO rows) and the draft's
managed rows are filled from `DeviceProfile.valuesFor(tier)`, the same table
the DEVICE row in the VASC menu applies. "Keep existing graphics settings"
restores the values seen when setup opened. Strong lights off and the steady
battle camera remain an explicit first-run safety (`SetupCard.DEVICE_SAFETY`),
not part of any tier.

Apply writes the tier through DeviceProfile: the result is the chosen tier,
not CUSTOM. Any override of a managed row (graphics details page, tested
recommendations) makes the draft CUSTOM on Apply, so the profile never
rewrites the override. The hidden duplicate "Graphics profile" row
(`_quality`) was removed. Draft, Cancel, Save-for-later and the transactional
rollback are unchanged. See `docs/DEVICE_PROFILES.md`.

## 2026-10-22 — Stage 2: the same Your Look on Gold/Silver/Crystal

One module set serves both editions. `main.lua` allowlists
`lib/SetupCard.lua`, `SetupPortrait`, `SetupPreview`, `SetupEffects`,
`SetupEffectRules`, `SetupMeasurement`, `SetupImageCheck`, `SetupBenchmark`
and `StartupPrompts` in `GEN2_SHARED_CARD_CORE`, so the Gen 2 facade reads
the shared files (no copies). `gen2/lib/Gen2SetupCard.lua` is the only Gen 2
specific piece: it hands the Johto hub's own ModSetting objects (built by
`VascMenuGen2` from `gen2/options.lua` and the overworld-card schema, with
change callbacks that already route through `VascRendererOptions`) to
`SetupCard.install` together with `src.core.Game2`, `autoOpen=false` and
`benchmark=false`.

Entry points on Johto: the ASCENDANT hub row "YOUR LOOK" (after the
sections, before Errors) and the V/F3 quick menu entry "Your Look" in the
world. There is no first-run auto-open on Gen 2 (existing saves are not
interrupted); `config.isWorld` exists for a later decision.

Differences on Johto, by design: the 120-second graphics check is Gen 1
only (its test scene uses Kanto maps and the Gen 1 battle fixture); the
lighting page keeps the safe recommendation, the 2 × 5 s world-lighting
compare and the visual check; the 10-second world preview works through
`game.world`. Rows whose option does not exist on Gen 2 (arena/platform
artwork, Kanto-only world rows) read "Not available in this version". The
device page maps the same choices to the Gen 2 DEVICE tiers (UNCAPED stays
a DEVICE-row-only advanced value). Pages, previews, Apply/Cancel/Save,
keyboard, controller and touch are the shared implementation.

## 2026-10-22 - Stage 3: simple profiles, MINIMUM, AUTO by hardware

The device page lists the same simple profiles as the DEVICE row: Very old
phone / weak laptop graphics (MINIMUM), Mobile / older device (LOW),
Notebook / handheld (MEDIUM), Gaming PC (ULTRA), Maximum quality (ULTRA),
Automatic (AUTO), Keep existing. Automatic now reads the graphics chip and
CPU (see docs/DEVICE_PROFILES.md) and checks the frame rate once after ten
seconds in the world. Tinkering rows stay in the "Open optional details"
sub-pages and under ADVANCED / TINKERING in the hub; changing one of them
makes the draft CUSTOM on Apply, as before.

## 2026-10-23 - Preview sync on Johto (review fix)

Your Look writes the 10-second preview, the lighting compare and Apply with
the silent flag, so the hub's change callbacks (the route into
VascRendererOptions) never ran for them: on Gen 2 the live Sky / Water /
Shadows / AA modules kept their previous values until the next ordinary
change. gen2/lib/Gen2SetupCard.lua now mirrors every silent write of a
non-DEVICE hub setting into the renderer bridge
(VascRendererOptions.syncKey, which never applies a DEVICE tier and never
marks CUSTOM). Headless check in tests/unit_gen2setup.lua.
