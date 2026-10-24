# VASC 3.0.65-rc.4 — Universal performance RC

Pair this ZIP with unchanged KASC 6.7.35-rc.2. The same VASC ZIP works in both supported Recomps.

RC4 rotates three packed-light upload images on desktop to avoid overwriting data still sampled by the GPU. Android/iOS retain their established single-image path; the exploratory GLES rotation was not validated and is not shipped. Resolution, geometry, window visibility and live lamp colour/power stay unchanged.

See PERFORMANCE_QA.md for measured FPS, frame-time tails, actual hardware/backend and remaining limitations. Emulator results do not establish performance on a physical phone or all Android GPUs. The earlier geometry/gameplay reports below keep their original version and scope.

## 3.0.65-rc.3 — Universal sharpness and geometry follow-up (RC)

- FULL preserves the selected T-SHIFT level instead of forcing maximum blur. For a sharp image, select T-SHIFT: OFF once; existing saved preferences are retained.
- Verified walls, windows, all 3D camera stages and collision in four Red locations on Gen1Recomp 0.3.96 and Gen2Recomped 0.8.45, both natively and in the Android 15 emulator: 100 collision cases and 196 final frames.
- Direct Silph exterior-glass tests verify the city view, ON/OFF/ON switching and solid collision in every environment.
- Adds scenery failure diagnostics, readiness visibility, reproducible isolated drivers and a precise QA report. No geometry/collision rules or engine binaries are changed.
- Same VASC Universal ZIP for both Recomps. Pair with unchanged KASC 6.7.35-rc.2 Universal ZIP. Gen2 compatibility remains a prerelease; no physical Android phone was tested.

# Promoted to public VASC 3.0.60

The tested 3.0.60-rc.1 candidate was promoted without runtime code or asset changes. Earlier candidate history follows.

# VASC 3.0.60-rc.1 — Pyro MAP court and Sea Terrarium

Local test candidate based on public VASC 3.0.59. Pair with KASC 6.7.32-rc.1 for the narrower volcanic platform. Replace the existing mod copies; retain saves and settings.

- Blaine's owned volcano MAP battle uses the central Pokéball marking. Both Pokémon stand on the marking; the two trainers stand just outside it. A raised camera shows the surrounding lava.
- The KASC v3 platform is 14 rather than 18 cells wide; the bridge, leader identity, stairs, quiz and rewards retain their positions and behavior. VASC also recognizes the earlier v1/v2 geometry.
- Four retained lava fountains animate outside the court during MAP battles. The lava surface now participates in the MAP render. The whole platform is no longer removed by the foreground-obstruction filter.
- Integrates ODias' supplied Sea Terrarium module unchanged: submerged reef, Pokémon shelves, trainer pillars, one transparent animated water surface, neutral front button and original credits. Both side and behind-Red layouts honor their actor heights; the sea has no closed dome.
- Sea selection is limited to surfing encounters on Routes 12, 13, 19, 20, 21, Pallet Town, Cinnabar Island and Vermilion City. Land, inland water, interiors and Gen 2 retain their existing scenes. Fishing from land currently retains the existing scene.
- All public 3.0.59 changes, including Gorochu's Crystal colour fix, remain included. No stats, abilities or battle rules changed.

See PYRO_SEA_QA.md for coverage. This candidate has not been publicly released.

---

Historical notes:

# Promoted to public VASC 3.0.59

The tested 3.0.59-rc.1 candidate was promoted without runtime code or asset changes. Earlier candidate history follows.

# VASC 3.0.59-rc.1 — Gorochu Crystal selection

Local candidate based on the complete public VASC 3.0.58. Use with existing KASC 6.7.31; KASC does not require another update for this fix.

KASC's modern battle rules legitimately detach battle-only stats from the saved Pokémon to split Special Attack and Special Defense. VASC treated every detached stats table as Transform and discarded an explicit Crystal or HD appearance. With a saved Classic preference underneath, Gorochu consequently remained monochrome despite the visible Crystal battle choice.

The appearance guard now recognises native Transform through its copied move list and retains explicit transformation, Mega and ghost guards. Normal stat copies no longer suppress the selected graphics or HD preloading. No species stats, abilities, battle rules, or saved Pokémon are changed.

Not automatically installed or published. Replace the existing VASC mod only; keep KASC, saves and options.

---

# Promoted to public VASC 3.0.58

The tested 3.0.58-rc.1 candidate was promoted without runtime code or asset changes. Earlier candidate history follows.

# Lokaler Teststand 3.0.58-rc.1

Zusammen mit KASC 6.7.31-rc.1 verwenden. Vollständiger Nachfolger des letzten öffentlichen Pakets. Enthält die Wärterhaus-/Glastür-, Pyro-Treppen-/Arena-, Hoenn-Besucherin- und Rivalen-Darstellungskorrekturen. Details und Testgrenzen: POSTRELEASE_QA.md.

Bestehende Mods im Launcher ersetzen/aktualisieren, keine zweite Kopie aktivieren. Spielstände und Optionen behalten. Nicht automatisch installiert oder veröffentlicht.

---

# Promoted to public VASC 3.0.57

The tested 3.0.57-rc.15 candidate was promoted without runtime code or asset changes. Earlier candidate history follows.

# Lokaler VASC 3.0.57-rc.15

Baut vollständig auf VASC 3.0.57-rc.14 auf. Normale Holztüren bleiben einflügelig und erhalten auch bei zwei benachbarten Ausgangsfeldern ein normales Breiten-/Höhenverhältnis. Außenliegende Glastürscheiben folgen der vorhandenen zeitabhängigen Fensterbeleuchtung; Rahmen und Griffe werden nicht mit aufgehellt.

Zusammen mit dem korrigierten KASC 6.7.30-rc.1 verwenden. Dieser KASC-Begleiter enthält wieder die vollständige neuere Integrations-/6.7.29-Basis plus Hoenn-NG+, Pyro und Gorochu. Der bisherige Begleiter 6.7.29-rc.4.pyro.2 war unvollständig.

Vorhandene Mods aktualisieren/ersetzen. Keine Spielstände oder Einstellungen löschen. Nur lokaler Teststand; nicht veröffentlicht oder automatisch installiert. Siehe docs/rc15-door-proportions-lighting.md und den KASC-Prüfbericht.
