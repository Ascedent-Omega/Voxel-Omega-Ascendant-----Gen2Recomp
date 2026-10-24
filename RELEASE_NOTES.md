## Gen2Recomp startup transport fix (release candidate)

On engines without mod.fetch, the optional sprite downloader no longer aborts mod initialization. Downloads return a clear unavailable message, while bundled graphics and file imports remain available. Native Gen1 transports and the Windows binary worker retain their existing behavior.

Distribution: retain the unchanged Gen1Recomp packages (VASC 3.0.63 / KASC 6.7.33), and provide separate Gen2Recomp candidates (VASC 3.0.65-rc.1 / KASC 6.7.35-rc.1). Gen2Recomp rejects the compute permission required by the Gen1 packages; one universal ZIP is not supported. Both Gen2 candidates are for Red, Blue and Yellow only.

Validation: the reported failure is reproduced by the actual Gen2Recomped 0.8.45 loader and removed by this patch. Both stable Gen1 packages load in Gen1Recomp 0.3.96. Offline transport tests cover Android, iOS, macOS, Linux and Windows simulations; existing Windows binary-streaming, bounds, timeout and cancellation tests pass. These checks do not constitute a full playthrough or a physical Android/iOS test.

# ASC OMEGA Ver.1.6

Complete Voxel Ascendant package captured from the installed PC mod on 22 October 2026, continuing the private Ver.1.5 release. This is a full mod download. Johto Ascendant / KASC is distributed separately.

## Device profiles and Your Look

- Gen 1 and Gen 2 now share the DeviceProfile core, with legacy stored profile names mapped to the current LOW / MEDIUM / HIGH / ULTRA / AUTO / CUSTOM names. Gen 2 retains its UNCAPED option.
- Your Look uses the same profile values as the main device selector. Gaming PC selects ULTRA; changing an individual managed value switches the profile to CUSTOM.
- Your Look is available through the Gen 2 Ascendant hub and quick menu, with the world preview, lighting comparison and optional detail pages.
- Includes the missing SetupLocale dependency registration that prevented the YOUR LOOK entry from appearing in Crystal.
- The full 120-second graphics check is still unavailable on Gen 2. POTATO remains hidden; the proposed next profile stage is not included.

## Voxel rooms and scenery

- Includes the installed voxel room implementations for all eight Johto gyms, the Elite Four rooms, Lance's room and the Hall of Fame.
- Includes Celadon Mansion's floors and roof terrace, its surrounding roof view, and the latest installed chair/floor cleanup.
- Includes the eight Kanto gym room implementations, with native puzzle, event, NPC, collision and warp ownership retained by the game.
- Includes the Dance Theater stage, Mr. Pokemon's house furniture and Elm's lab furniture changes present in the PC installation.
- Includes Pokemon Center shell handling for runtime room sizes that differ from the original profile table, plus the installed Celadon Game Corner and prize-room changes.

These entries describe the source included in the snapshot. They do not establish visual acceptance of every room.

## Cache, streaming and diagnostics

- Includes the installed persistent Gen 2 mesh-cache guard, cache version and quota/cleanup handling scoped to the mod's mesh-cache keys.
- Includes connected-map retention and the visible-frame cache-write cooldown already present in the installed build.
- Includes the installed frame profiler, renderer diagnostics and battle/render integration changes. No new FPS improvement is claimed for this packaging work.
- Includes the installed Pinball runtime updates. A player-supplied Pokemon Pinball ROM is required; no ROM is bundled. On Android use **CUSTOM CONTENT → POKEMON PINBALL ROM**.

## Installation

Close G1R, back up the existing VOXEL_ASCENDANT mod folder, replace it with the VOXEL_ASCENDANT folder from the complete ZIP, then restart the game. Keep your saves and mod storage in place. This package does not include KASC.

## Validation and limitations

- Gen 2 source check: 397 Lua files compiled, zero failures.
- DeviceProfile unit suite: 99 checks, zero failures.
- Gen 1 Your Look suite: 30 checks, zero failures.
- Gen 2 Your Look suite using the strict module resolver: 65 checks, zero failures.
- DeviceProfile golden comparison: 70 checks, zero unexpected differences.
- These are local source and simulated contract checks. This delivery session does not establish live G1R visual correctness, measured gameplay FPS or physical Android behavior. Earlier experiment names retained in the captured code are not additional validation claims.
- ROMs, saves, backup files, local Live Debug configuration, machine-specific diagnostic transport and the local warp helper are excluded from distribution. The PC installation is preserved.

Private distribution: repository access is required. The release asset is accompanied by its SHA-256 checksum and a package verification receipt.

Final local verification: all 3,142 non-test runtime Lua files across the two captured mods compiled successfully under LuaJIT / LÖVE; the KASC menu navigation regression also passed.
