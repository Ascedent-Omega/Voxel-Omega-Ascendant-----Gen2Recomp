# Universal RC installation — 2026-10-29

Use Voxel-Ascendant-3.0.65-rc.5-Universal.zip and Kanto-Ascendant-6.7.35-rc.3-Universal.zip. There is ONE ZIP per mod: install these identical files in either Gen1Recomp or Gen2Recomped, for Red/Blue/Yellow content.

1. Close the recompiler and back up saves and the old mod folders.
2. Verify SHA256SUMS.txt. Use the named assets, not GitHub's automatic source archives.
3. Remove older VASC/KASC copies from the active engine's mods directory. Keep backups outside it.
4. Extract both ZIPs directly into that directory: mods/VOXEL_ASCENDANT/manifest.json and mods/kanto_ascendant/manifest.json must exist. Do not add another enclosing directory.
5. Keep existing saves, options and mod_cache. Enable both mods. For the initial comparison disable other graphics/gameplay mods, including the bundled DramaticShapes mod in Gen2Recomped.
6. Confirm versions 3.0.65-rc.5 and 6.7.35-rc.3 in the mod manager. For the measured setup choose CUSTOM device profile, FULL scenery, REAL WINDOWS ON, shadows ON, NATIVE 3D resolution, AA 0 and T-SHIFT OFF.
7. If using both engines, repeat installation in the other engine's own mods directory using the SAME files.

The retained manifest range is Gen1Recomp >=0.3.96,<0.4.0 OR Gen2Recomped >=0.8.45,<0.9.0, API 2. This is a declared range, not a claim that every version was tested. New performance tests used Gen2Recomped 0.8.47 on an Android-15 ARM64 emulator at native1280x720. No new complete Gen1 playthrough or physical Android phone test was performed. Remaining stutters are disclosed in TEST_REPORT_EN.md / TEST_REPORT_DE.md.

Tested Android Gen2 path: Android/data/com.underdecodedhd.gen2recomp/files/save/pokemon-love2d/mods/. Paths and access restrictions vary by app/profile. Use an app/OS-supported folder access or file import if your version offers it; a ZIP left in Downloads is not installed automatically. The extracted folder structure above is required.

Checksum commands: macOS `shasum -a 256 -c SHA256SUMS.txt`; Linux `sha256sum -c SHA256SUMS.txt`. PowerShell `Get-FileHash .\Voxel-Ascendant-3.0.65-rc.5-Universal.zip -Algorithm SHA256` and compare with the matching checksum line. Each ZIP also has its own .sha256 file.

Rollback: close the engine, remove the new folders and restore your backed-up mod folders. The new private cache representation introduces no save migration. If needed, restore the save backup made before installation.

These are release candidates with known remaining stutters. They do not promise constant60FPS or complete stutter elimination. The new manifests and documentation were packaged after the recorded gameplay run; runtime fixes are byte-identical to the accepted tested source, without private QA instrumentation. See package-receipts.json for provenance and verification.
