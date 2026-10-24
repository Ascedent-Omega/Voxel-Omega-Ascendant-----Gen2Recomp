> **Universal RC4:** [VASC 3.0.65-rc.4](https://github.com/Ascedent-Omega/Voxel-Omega-Ascendant-----Gen2Recomp/releases/tag/v3.0.65-rc.4) fixes desktop GPU stalls from animated light uploads. Pair it with [KASC 6.7.35-rc.2](https://github.com/Ascedent-Omega/Omega-Kanto-Ascendant----Gen2Recomp/releases/tag/v6.7.35-rc.2). Each ZIP works in both Recomps. See [installation](INSTALL.txt), [performance measurements and limits](PERFORMANCE_QA.md) and the [geometry report](GEOMETRY_QA.md). Gen2 support remains an RC.

# Voxel Ascendant 3.0.65-rc.4 — Universal RC

**The same ZIP works with Gen1Recomp and Gen2Recomp.** Install this package alongside [Kanto Ascendant 6.7.35-rc.2](https://github.com/Ascedent-Omega/Omega-Kanto-Ascendant----Gen2Recomp/releases/tag/v6.7.35-rc.2); update both mods together.

This release candidate supports **Pokémon Red, Blue and Yellow**. It contains the current shared Kanto runtime and the fix for `SpriteMirrorFetch:9: missing transport dependency`. Gold, Silver and Crystal stay inactive in this RC. For those games, retain the previous Gen1Recomp release.

## Supported engines

| Engine | Version range | Download |
| --- | --- | --- |
| Gen1Recomp | 0.3.96 to below 0.4.0 | The Universal ZIP below |
| Gen2Recomp / Gen2Recomped | 0.8.45 to below 0.9.0 | The identical Universal ZIP |

There are no separate Gen1/Gen2 builds and no launcher modification is needed. Cartridge generation and engine name are different things: Red, Blue and Yellow are Gen 1 games in either engine.

## Installation

1. Close the game. Back up `mods/VOXEL_ASCENDANT`, `mods/kanto_ascendant` and your saves.
2. Download **both Universal ZIP assets** from the two RC release pages. Do not use GitHub's automatic **Source code (zip)** or **Source code (tar.gz)** downloads.
3. Remove the old `VOXEL_ASCENDANT` and `kanto_ascendant` folders from the active engine's `mods/` directory. Remove duplicate older copies of these two mods from any other active mod location.
4. Extract both ZIPs into that `mods/` directory. The resulting files must include:

```text
mods/
  VOXEL_ASCENDANT/
    manifest.json
    main.lua
  kanto_ascendant/
    manifest.json
    entry.lua
```

5. Disable other graphics/gameplay mods for the initial compatibility check, including the bundled **Gen2Recomped-DramaticShapes** mod in Gen2Recomp. It conflicts with VASC/KASC.
6. Keep existing saves, options and `mod_cache`. Enable both mods and start Red, Blue or Yellow. If you have both engines installed, install these **same two ZIPs** into each engine's own mod directory.

## Installation auf Deutsch

Spiel schliessen und beide bisherigen Modordner sowie Spielstaende sichern. Die **zwei Universal-ZIPs** von den RC-Releaseseiten laden, die alten Modordner aus dem aktiven `mods/`-Verzeichnis entfernen und beide ZIPs direkt dort entpacken. Keine zusaetzliche Ordnerebene anlegen. Spielstaende, Optionen und `mod_cache` behalten. Andere Grafik-/Gameplay-Mods beim ersten Test deaktivieren, insbesondere den mitgelieferten **Gen2Recomped-DramaticShapes**-Mod. Er kollidiert mit VASC/KASC. Danach beide Ascendant-Mods aktivieren und Rot, Blau oder Gelb starten. Fuer beide Recomps gelten dieselben ZIPs; nur der Installationsordner ist jeweils der andere.

## RC status and limitations

- See GAMEPLAY_QA.md for the exact tested game, engines, scenarios and platform limits. Transport and Windows file-download regression tests are also included.
- No full playthrough and no physical Android/iOS test has been completed for this RC.
- Gen2Recomp does not expose the optional mod download transport. In-game sprite downloads stay unavailable; bundled graphics remain usable.
- Gen1Recomp keeps its native transport. On Windows without mod-thread permission, binary content uses the engine-owned file-download pool. Windows **portable mode** cannot safely share that pool's native staging root, so optional downloads are unavailable there in this RC.
- Optional geometry/image/light-cache workers use their existing fallback when a host does not expose worker access. The manifest retains mod API 2 and declares only permissions understood by both engines.
- To roll back, close the game and restore the two previous mod folders. Restore your backed-up saves as well if you want to return to their exact earlier state.

## Credits

- **Roxas2712 (Pandy)**: the original Voxel Ascendant and Kanto Ascendant.
- **Omega Ascendant Team (Omega Dias)**: the continuation of both mods.
- **DramaticShape**: the MIT-licensed DramaticShapeVoxelMod foundation.
- **Cedric / UNDERdecoded**: the Gen2Recomp engine.
- **randyadr**: Gen2-3D-Sprites, the origin of the Stadium importer modules.
- **pret** contributors: the pokered disassembly the maps are built from.

Every other asset and its source is listed in [CREDITS.md](CREDITS.md), [ASSET_SOURCES.md](ASSET_SOURCES.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Licence

The code is under the MIT licence: see [LICENSE](LICENSE). Bundled third-party material keeps its own licence (see the notices above). No Nintendo ROM, save file or extracted Stadium model is part of this package.

Pokémon is © Nintendo, Creatures Inc. and GAME FREAK inc. This is an unofficial, non-commercial fan mod, not affiliated with or endorsed by them. Gen2Recomp is a separate project with its own licence; no engine file is included here.
