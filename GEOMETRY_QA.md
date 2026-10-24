> RC4 retains this RC3 geometry evidence under its original scope. The later upload-lifetime change and its additional checks are documented in PERFORMANCE_QA.md.

# Universal RC3 geometry and sharpness verification — 2026-10-24

Tested pair: **Voxel Ascendant 3.0.65-rc.3 + Kanto Ascendant 6.7.35-rc.2**, enabled together. Each mod has one Universal ZIP for both engines. KASC's RC2 ZIP is unchanged.

| Environment | Host | Full geometry/camera matrix | Collision cases | Direct glass/window test | Final frames |
| --- | --- | --- | --- | --- | --- |
| macOS arm64, LÖVE 11.5 | Gen1Recomp 0.3.96 | PASS | 25 | PASS | 49 |
| macOS arm64, LÖVE 11.5 | Gen2Recomped 0.8.45 | PASS | 25 | PASS | 49 |
| Android 15/API 35 arm64 emulator | Gen1Recomp 0.3.96 APK | PASS | 25 | PASS | 49 |
| Android 15/API 35 arm64 emulator | Gen2Recomped 0.8.45 APK | PASS | 25 | PASS | 49 |

## What was checked

The Red fixture visits REDS_HOUSE_2F, PALLET_TOWN, VIRIDIAN_MART and SILPH_CO_2F. Actual final renderer frames cover FULL, 15°, 35°, 50°, 75°, First Person, Third Person and right-stick camera turns. The captures show bedroom/mart architecture, outdoor building facades and Silph partitions. Camera-side cutaways in orbit mode are intentional; the First/Third Person views retain the room enclosure.

Per environment, sixteen grid-walking probes hold normal movement into solid tiles (four directions on each map). Eight further probes use the real free-movement path in First/Third Person: the character moves about 2.49 world pixels toward the wall and stops without crossing the cell boundary. Native Gen1 and Gen2 use the same blocked cells and produce the same movement limits.

A separate Silph probe stands at cell (1,9), looks west through the exterior glazing and records the city view. REAL WINDOWS is switched ON → OFF → ON in the same map: the view is replaced by the opaque wall and restored after preparation. A forward movement attempt against that glass stops at the same boundary; transparency does not remove collision. All four environments pass this test. Total: **100 collision cases and 196 final rendered frames**.

## Confirmed fix

Selecting VOXEL: FULL previously forced T-SHIFT to its maximum, making roofs, signs and foreground/background details blurry. FULL now preserves the independently selected T-SHIFT value. Both OFF and a non-maximum level (2) survive entering FULL in all four environments. Before/after captures show maximum blur and OFF at the same camera/place.

Existing saved blur preferences are retained. Select **T-SHIFT: OFF once** for a sharp image. **3D RESOLUTION: NATIVE** avoids reduced-resolution scaling; AUTO/720P/75%/50% are separate resolution choices. The release does not globally replace the player's saved quality/performance choices.

Scenery failures also log the original build error, and a read-only scenery-status snapshot supports the test's readiness checks. No engine implementation was copied into the mods, and neither engine executable/APK was patched.

## Method and limits

The native runs use the original release .love files. Android runs the original installed release APKs. The earlier installation receipts verify their APK bytes against the downloads. Only mod files and a private test controller were changed. Android's full matrix uses the emulator's hardware GLES 3.0 translator on Apple M2. SwiftShader preliminary captures are not counted as a completed full-geometry run.

Tests use isolated save identities/app fixtures, real warp/fade/reveal lifecycles, the normal input paths and final framebuffer captures. Captures wait for completed scenery, rather than accepting the inexpensive first BODY-only frame. The final collision fixtures avoid Pallet's northern Oak story trigger. The controller does not replace collision, camera, rendering, combat or save implementations. Published native drivers refuse ordinary save identities.

Native comparisons use the same 1024×768 window. Android additionally exercises portrait and landscape; the two direct Android window probes use matching 720×1280 views. Touch controls, NPC movement, random overworld Pokémon and lighting phase can differ between captures; this is a structural/functional comparison, not a claim of pixel-identical animated frames.

This is a focused **Red** verification, not a complete playthrough or a performance benchmark. No physical Android handset was available, so it does not establish compatibility/performance for every phone or GPU. Blue/Yellow retain earlier loader coverage; Gold/Silver/Crystal remain inactive in this Universal RC. RC2's menu/battle/save/load results remain documented separately in GAMEPLAY_QA.md and were not all repeated after this preset-only runtime change.

No ROM, imported ROM cache, progress save or private controller is included. The release's geometry verification JSON records the frame hashes; original captures and logs are retained in the local QA artifact.
