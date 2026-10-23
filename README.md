# Voxel Ascendant 3.0.64

**Pokémon Red, Blue and Yellow in a full 3D voxel world, for Gen2Recomp.**

Voxel Ascendant (VASC) turns the Kanto of the Gen 1 games into a living voxel world: towns, routes, caves and interiors in 3D, with weather, day and night, scenery on the horizon, animated characters, Pokémon that walk the overworld and 3D battles. It is a mod for the **Gen2Recomp** engine (Gen2Recomped 0.8.45 or newer in the 0.8 line) and plays alongside its companion mod, **[Kanto Ascendant](https://github.com/Ascedent-Omega/Omega-Kanto-Ascendant----Gen2Recomp)**.

> This release is for **Red, Blue and Yellow only**. On Gold, Silver and Crystal the mod stays switched off and says so in the log. Gen 2 support will come later as a separate release.

## What's in it

- **A 3D Kanto.** Every Gen 1 map is rebuilt as voxel geometry, with interiors, doors, roofs, water, caves and seasonal trees, while the game's own collision, events and warps stay in charge.
- **Weather, sky and light.** Rain, snow and sun, a day/night sky, dynamic lights in windows and rooms, and scenery panoramas around the edges of each map.
- **Characters and Pokémon in the world.** Voxel and Cobble character models, a follower Pokémon, wild Pokémon walking the routes (with Kanto Ascendant) and cinematic Fly and Surf scenes for each species.
- **3D battles.** Battle arenas, the ORAS-style battle HUD and, if you import your own Pokémon Stadium cartridge, Stadium battle models.
- **Device profiles.** One setting picks the right quality for your hardware: MINIMUM, LOW, MEDIUM, HIGH and ULTRA, plus AUTO (measures your PC or phone) and CUSTOM (any value you change yourself).
- **Your Look.** A guided setup card to choose your character, the camera and the graphics level, with a live preview.
- **Optional extras.** HD character and Pokémon packages, your own music and sprites, and the Game Corner pinball tables with your own Pokémon Pinball cartridge. No ROM is ever included.

## New in 3.0.64

- **Gen2Recomp support.** Runs on Gen2Recomped 0.8.45. The generation check now reads the cartridge itself, so Red, Blue and Yellow always start the Gen 1 runtime.
- **Gen 1 only.** The Gold/Silver/Crystal runtime is not part of this package, which makes it about 40 MB smaller. The Stadium importer modules that Gen 1 battles use are kept.
- **Device profiles reworked.** The Gen 1 profiles share one core with the rest of VASC: MINIMUM, LOW, MEDIUM, HIGH, ULTRA, AUTO and CUSTOM, with your old choice carried over. AUTO now measures the hardware before it picks.
- **Your Look and menus.** Updated Your Look preview and effects, clearer profile help text and a reworked Errors menu.
- **Characters.** Faster voxel character models, disguised NPCs (such as the Fuchsia ninjas) and NPCs with varied hair and outfit colours.
- **Lighting and loading.** Improved window lights, loading companion and location banner, and more diagnostics for support reports.

See [CHANGELOG.md](CHANGELOG.md) for the full history.

## Install

1. Install **Gen2Recomp** (Gen2Recomped 0.8.45) and import your own Red, Blue or Yellow cartridge in its launcher.
2. Close the game. If you already have Voxel Ascendant, keep a copy of your `mods/VOXEL_ASCENDANT` folder.
3. Download `Voxel-Ascendant-3.0.64.zip` from the [release page](../../releases), delete the old `mods/VOXEL_ASCENDANT` folder and unzip the new one into `mods/`. You should end up with `mods/VOXEL_ASCENDANT/main.lua`.
4. Install **Kanto Ascendant 6.7.34** the same way. Update both mods together.
5. Start the game. Your saves and settings are kept.

## Known limitations

- Tested on Windows PC with Pokémon Yellow. **Android has not been tested on a real phone yet.**
- HD downloads and HD package imports have not been tested on Gen2Recomp yet. Without them the mod uses its built-in characters and Pokémon sprites.
- Weather music falls back to the normal map music on this engine.
- Starting the game takes about 10 seconds on a fast PC, and a map change can stall for a moment while it is built for the first time.

## Credits

- **Roxas2712 (Pandy)**: the original Voxel Ascendant and Kanto Ascendant.
- **Omega Ascendant Team (Omega Dias)**: the continuation of both mods.
- **DramaticShape**: the MIT-licensed DramaticShapeVoxelMod foundation.
- **Cedric / UNDERdecoded**: the Gen2Recomp engine.
- **bryanthaboi and the Pokémon Gen 1 Recompilation Project contributors**: the original engine and mod API.
- **randyadr**: Gen2-3D-Sprites, the origin of the Stadium importer modules.
- **pret** contributors: the pokered disassembly the maps are built from.

Every other asset and its source is listed in [CREDITS.md](CREDITS.md), [ASSET_SOURCES.md](ASSET_SOURCES.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Licence

The code is under the MIT licence: see [LICENSE](LICENSE). Bundled third-party material keeps its own licence (see the notices above). No Nintendo ROM, save file or extracted Stadium model is part of this package.

Pokémon is © Nintendo, Creatures Inc. and GAME FREAK inc. This is an unofficial, non-commercial fan mod, not affiliated with or endorsed by them. Gen2Recomp is a separate project with its own licence; no engine file is included here.
