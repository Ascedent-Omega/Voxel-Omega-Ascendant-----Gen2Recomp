# RC test report — VASC3.0.65-rc.5 / KASC6.7.35-rc.3

These are release candidates with known remaining stutters. The measured runtime fixes are the accepted tested source; only version metadata/documentation changed during packaging. The private QA registry is excluded. The newly packaged ZIPs have full content/CRC/SHA-256 verification, not a new game launch. API2 and the existing dual-engine manifest range are retained; there was no new complete Gen1 playthrough or physical Android phone test.

## Actual setup and results

Official Gen2Recomped0.8.47, Android15/API35 ARM64 emulator on Apple M2, four virtual cores,3072MiB guest RAM, host GPU. Four fresh processes in A1/B1/B2/A2 order, each120s walking in Pallet plus30s window-camera panning in Silph Co.2F. FULL scenery, real windows and shadows enabled, native1280x720 scene/framebuffer, AA0, tiltshift0. Starting-save SHA-256 matched. All frames, including dialogs/outliers, were retained. No concurrent game test renderer was present in the accepted comparison; background host activity remained possible.

| Measurement | Before A | After B |
|---|---:|---:|
| Pallet FPS,4minutes per variant |58.356|59.006|
| Pallet p99 frame,ms |26.462|25.378|
| Pallet worst frame,ms |418.658|211.557|
| Pallet frames >100ms |5|5|
| Pallet frames >250ms |3|0|
| Window FPS,1minute per variant |59.030|59.148|
| Window p99 frame,ms |26.885|26.063|
| Window worst frame,ms |73.646|118.523|
| Window frames >100ms |0|2|

The largest Pallet stalls became smaller in both pairs, but >100ms stalls remain. The window FPS advantage is NOT stable between pairs, and its after group contains two >100ms frames. The affected segment also recorded a Codex-renderer host CPU spike; correlation does not prove each frame's cause and those frames were not discarded. Do not describe this as universally smooth or a guaranteed60FPS fix.

Post-sample live Lua heap fell roughly19%; window transient allocation fell roughly26%. Short diagnostic GC/I/O experiments and forced full collections were separate from FPS acceptance; no GC-disable/log-suppression mode is shipped.

## Evidence and limits

-5,023,502 scalar comparisons across1,351catalog keys and28,281requests, with matching1,268loaded/retained sources; additional format/ownership checks passed.
-15complete frozen native RGBA comparisons were identical, including a repeated-control render. That proof is inherited for the exact same three VASC geometry/light-file hashes in the final cache comparison; KASC's private representation is separately covered by value/ownership contracts and real Android starts.
-Room admission/live-door, recovery/uniform and mobile/desktop light-upload contracts passed.
-The last run is not a new comprehensive battle/save-load/sliding-door/Gen1/physical-phone certification. See TEST_REPORT_DE.md for the full measured table, provenance, intermediate diagnostics and remaining uncertainty.

Private emulator/ROM/save/engine sources, raw QA drivers and private instrumentation are not part of these downloads.
