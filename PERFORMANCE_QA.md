# VASC 3.0.65-rc.4 performance QA

**Android remains subject to stutters with FULL scenery and NATIVE resolution. RC4 does not certify 60 FPS or stutter-free play on Android.**

RC4 fixes a demonstrated desktop GPU upload stall: animated packed-light data was repeatedly overwritten in an image still sampled by the preceding GPU frame. Desktop now rotates three bounded images and releases all of them on layout replacement/reset. Live light colours/powers and scene detail are unchanged. Android/iOS keep the original single-image path; exploratory GLES rotation did not establish a benefit and is not shipped.

Pair this Universal ZIP with unchanged KASC 6.7.35-rc.2. The identical VASC ZIP supports Gen1Recomp 0.3.96 and Gen2Recomped 0.8.45.

## Environment and method

- Red, VASC + KASC enabled together; original Gen2Recomped 0.8.45 `.love` and APK. No engine binary was patched.
- Mac: Apple M2, OpenGL 4.1 Metal 89.4. Android: API 35 arm64 emulator, 4 vCPUs/3 GiB, gfxstream / Android Emulator OpenGL ES Translator (Apple M2), GLES 3.0. This is an emulator, not a physical Android phone.
- FULL scenery, REAL WINDOWS ON, CUSTOM profile, NATIVE **1280 × 720 actual world canvas and framebuffer**, AA OFF, T-SHIFT OFF, clear daytime. Native accepted measurements have SHADOWS ON. Android has a seven-case SHADOWS OFF series and an extra two-case SHADOWS ON series; real shadows were active in both extra cases.
- Normal application loop/frame cap. Each accepted segment runs for about 20 seconds after reveal/preparation; movement and look use normal game inputs. Scripted map placement invokes the real fade/reveal lifecycle. No screenshot encoding or result writes occur during steady measurements.
- FPS = rendered application frames / sum of consecutive `love.graphics.present` completion intervals. P95/P99/max expose pacing tails; update/draw/present costs are wall time, not GPU execution timestamps. Android compositor/display cadence and phone GPU performance are not established by these values.
- A 0.5-second process observer covers final measurement windows, with conservative one-second boundaries. Overlapping renderer windows are excluded. The first native camera-look case and its repeat both overlapped short KASC tests; their numbers are not accepted. All 15 rows below have clean observed renderer windows. The raw world_visible flag means the overworld is the top stack state; it is not a pixel-visibility test. Android walking routes include brief native scripted overlays (93.82% / 95.34% overworld-top frames), retained in the route totals and stutter counts. All idle/window measurements are 100% overworld-top. Other normal OS/background load remains a limit of this shared machine.

## Accepted real-game results

| Host / shadows | Scene | FPS | P95 ms | P99 ms | Max ms | >50 ms | >100 ms | World top % |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Mac / ON | bedroom-full-idle | 60.00 | 17.73 | 17.91 | 22.91 | 0 | 0 | 100.00 |
| Mac / ON | pallet-full-idle | 59.80 | 17.62 | 18.35 | 33.44 | 0 | 0 | 100.00 |
| Mac / ON | pallet-full-walk | 58.90 | 17.62 | 33.32 | 34.32 | 0 | 0 | 100.00 |
| Mac / ON | mart-full-idle | 60.00 | 17.56 | 17.84 | 21.76 | 0 | 0 | 100.00 |
| Mac / ON | silph-full-idle | 58.95 | 17.67 | 33.13 | 34.15 | 0 | 0 | 100.00 |
| Mac / ON | silph-window-fp-idle | 59.10 | 17.64 | 33.25 | 34.06 | 0 | 0 | 100.00 |
| Android / OFF | bedroom-full-idle | 56.61 | 20.87 | 37.67 | 290.51 | 7 | 2 | 100.00 |
| Android / OFF | pallet-full-idle | 50.74 | 31.11 | 60.03 | 242.60 | 14 | 3 | 100.00 |
| Android / OFF | pallet-full-walk | 55.84 | 25.79 | 41.11 | 93.33 | 6 | 0 | 93.82 |
| Android / OFF | mart-full-idle | 59.87 | 19.09 | 22.09 | 28.51 | 0 | 0 | 100.00 |
| Android / OFF | silph-full-idle | 58.47 | 24.11 | 28.77 | 32.52 | 0 | 0 | 100.00 |
| Android / OFF | silph-window-fp-idle | 59.10 | 22.41 | 27.18 | 34.39 | 0 | 0 | 100.00 |
| Android / OFF | silph-window-fp-look | 56.08 | 24.16 | 33.50 | 291.30 | 4 | 2 | 100.00 |
| Android / ON | pallet-full-idle | 56.99 | 22.83 | 29.68 | 310.81 | 3 | 2 | 100.00 |
| Android / ON | pallet-full-walk | 56.92 | 23.96 | 31.64 | 66.81 | 2 | 0 | 95.34 |

Accepted: **17,339 application frames**, 299.9 seconds across 15 segments. Completion PASS means the recording and functional preconditions completed; it is not a 60-FPS performance pass.

## Baseline and diagnosed change

Exploratory SHADOWS OFF Mac captures at the same 1280 × 720 view recorded Alabastia at 37.91 FPS idle / 40.87 FPS walking before the change, and 59.42 / 58.92 FPS with desktop upload rotation. Phase probes localized roughly 7.3 ms/frame to packed-light colour upload; scene-start cost then fell to about 0.5 ms/frame. These earlier diagnostic runs did not yet have continuous process observation and are not substituted for the accepted final rows.

The first profiling wrapper was rejected because it truncated a fifth return value; subsequent phase probes preserve all returns. Supplementary `jit.profile` sampling did not produce a completed Android sample and blocked QA progression; that private diagnostic was force-stopped and discarded. No product crash or FPS result is inferred from it. The optional statistical sampler is removed from the published test driver. API reference: [LuaJIT profiler](https://luajit.org/ext_profiler.html).

The experimental three-image Android candidate included a transient 26.10-FPS market result and other outliers. It was not accepted as an Android optimization. The shipped mobile branch deliberately preserves the prior upload semantics; CPU contracts pass for both the parent and RC4 mobile path. The clean final market result is recorded above, without erasing the earlier failed candidate observations from the private test record.

## Loading and remaining limits

Covered map transitions are recorded separately in the raw CSVs, not mixed into the steady-state rows. The final Android SHADOWS OFF transitions include a maximum 450.42-ms frame. Long preparation frames and the 0.29–0.31-second outliers during visible Android play remain. Their precise device-versus-emulator cause is not established; RC4 must not be advertised as eliminating Android stutter.

These are four prepared places (bedroom, Alabastia, Vertania market, Silph 2F), a short walking route and a west-facing real window with camera look. They are not a complete playthrough, whole-world performance proof, phone thermal/battery test, 1080p/1440p phone-panel benchmark, or a new sliding-door interaction test. Blue/Yellow have earlier loader checks, not this Red performance matrix. Gold/Silver/Crystal remain inactive in the Universal RC.

## Correctness and reproducibility

- CPU contract: exact current colour/power, bounded retention, stable indices while flickering, unchanged-data reuse, complete pool retirement on layout/reset, idempotent reset. The parent desktop path fails the in-flight-retention negative control; parent and RC4 mobile paths pass the mobile contract.
- Real GPU contract: 54 actual texture readbacks across 18 live power changes, correct within RGBA8 precision; no stale colours/powers.
- Gen1Recomp 0.3.96 native post-change regression: Silph windows ON/OFF/ON, real outside view, and solid glass after normal movement; four final captures. Earlier RC3 geometry/gameplay evidence retains its original version/scope.
- The final runtime SHA-256 matches both native installed profiles and the Android readback receipt. Packaging verification additionally compares every archive member to the staged source.

Commands from the mod root:

```sh
luajit tests/local_light_upload_slots_test.lua .
luajit tests/local_light_upload_slots_test.lua . mobile
QA_VASC_ROOT="$PWD" love tests/light_upload_gpu
```

`tests/universal_performance_driver.lua` is guarded for a dedicated private QA controller/identity and requires an already imported private cartridge/save fixture. Neither that controller, the ROM/import cache nor saves are in the release ZIP.

Runtime `lib/LocalLightGrid.lua` SHA-256: `0fe8d7b9d71b4f6b11b4d9a8e005ee4bc1bd9b62c90fb69ce7287f89256a82c5`.
