# Universal RC2 gameplay verification — 2026-10-24

Packages: Voxel Ascendant 3.0.65-rc.2 and Kanto Ascendant 6.7.35-rc.2. Each mod has one Universal ZIP for both engines. Both mods are enabled together; other mods, including Gen2Recomped-DramaticShapes, are disabled.

| Environment | Engines | Game | Gameplay and same-process load | Fresh-process load |
| --- | --- | --- | --- | --- |
| macOS arm64, LÖVE 11.5 | Gen1Recomp 0.3.96 | Red | PASS | PASS |
| macOS arm64, LÖVE 11.5 | Gen2Recomped 0.8.45 | Red | PASS | PASS |
| Android 15/API 35 arm64 emulator | Gen1Recomp 0.3.96 APK | Red | PASS | PASS |
| Android 15/API 35 arm64 emulator | Gen2Recomped 0.8.45 APK | Red | PASS | PASS |

The desktop tests use the original release .love files, and Android uses the original APKs. Production engine source is not patched. The Android emulator uses SwiftShader/ANGLE OpenGL ES 3.1. No physical Android handset was available.

## What was actually exercised

- Real game load with both mods, final rendered frames captured.
- Genuine New Game creation, with the native opening speech skipped after its save is created. The shared Gen2 entry sequence is allowed to finish/skip through its normal controls before the fixture is installed.
- A controlled party containing Bulbasaur, Tackle and Potions; this is a gameplay fixture rather than a complete story playthrough.
- START menu, party, party actions, status screen, bag, KASC ASCENDANT menu and VASC Your Look menu, including return to the world.
- Walking through collision in Red's bedroom, stairs to REDS_HOUSE_1F, and the front door to PALLET_TOWN. Story dialogue is advanced normally. The test reroutes around KASC's wardrobe rather than disabling collision.
- A native wild Rattata battle, FIGHT/move selection, actual attacks, enemy defeat, PP spending, experience gain and normal battle exit. Enemy HP/results are not forced.
- Real save serialization and restoration, then another process/app launch that restores map, party/move PP and a saved QA flag, and reopens ASCENDANT.
- Legacy archive storage write/readback and lineage validation; Gen2's flat record backend is adapted without changing Gen1's native storage.

Native tests run through the engine's frame-driver entry point. Android uses an additional private QA controller mod that queues normal game input and records frames/results; it does not replace combat, collision, rendering or persistence implementations, and does not spoof the operating system. Android app restarts use force-stop and relaunch. The controller is not part of either Universal ZIP.

## Findings and fixes

RC1's missing optional download transport is already handled without aborting mod startup. This follow-up found that Gen2 0.8.x's mod-wide storage was being treated as Gen1's opaque playthrough storage. A real New Game followed by save/load reproduced the false Legacy migration rejection in RC1. RC2 stores its compatibility namespace inside KASC's saved mod data, scopes every archive operation to that namespace and edition, and keeps the existing transaction/readback checks.

Eligible RC1 first campaigns are adopted only with a valid fresh New Game receipt, no Legacy run/handoff/binding, and no older lineage records. Started, imported, unknown or conflicting Legacy archives are not silently replaced. Unit checks cover slot/edition isolation, Continue on a replaced save, rejecting unverified scope writes, safe RC1 adoption and unchanged Gen1 delegation. A save produced by the Android RC1 test was also loaded and saved successfully through the compatibility path on the native Gen2 host.

The official Gen2 release includes DramaticShapes; enabling it together with VASC/KASC produces an intentional conflict. INSTALL.txt now explicitly requires disabling it for the compatibility test.

## Limits

This verifies the listed Red scenario. It is not a full playthrough, all moves/trainers, all Legacy/NG+ cycles, every game edition, a performance benchmark or a guarantee for every phone/GPU. Blue and Yellow retain the earlier loader checks; they did not receive this full gameplay run. Gold/Silver/Crystal remain inactive in this Universal RC. Physical Android/iOS and Windows gameplay are not covered. Gen2 optional online sprite downloads remain unavailable; bundled assets and fallback sprites are used. The battle fixture can use the documented terrarium fallback when the immediate map geometry cannot host the requested MAP arena.

No ROM, generated ROM cache or progress save is included in the release or this report.
