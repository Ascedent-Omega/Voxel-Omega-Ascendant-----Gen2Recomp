# Testbericht für die Universal-RCs

VASC **3.0.65-rc.5** + KASC **6.7.35-rc.3** — Release Candidates mit bekannten Rest-Rucklern.

Die Spielmessung vom 29.10.2026 verwendete die übernommenen Laufzeitfixes mit den damaligen Manifestversionen3.0.65-rc.4/6.7.35-rc.2. Für diese Downloads wurden die Versionsmetadaten auf rc.5/rc.3 gesetzt und die Dokumentation erneuert. Alle geprüften Laufzeitdateien sind identisch; ausgenommen sind die beiden Manifest-Versionen und die absichtlich nicht ausgelieferte private QA-Modulregistrierung. Die neu gepackten ZIPs wurden vollständig auf Inhalt/CRC/SHA-256 geprüft, aber nicht nochmals im Spiel gestartet. Gen1-Kompatibilität wird weiter deklariert; eine neue vollständige Gen1-Abnahme ist damit nicht behauptet.

---

# Android: Pallet, FULL, Fenster, native Auflösung — 29.10.2026

**Ergebnis: unnötige Allokationen und Cache-Verweise reduziert; keine vollständige Ruckelfreiheit nachgewiesen.** Die Spielmessung dokumentiert den damaligen lokalen Teststand; die zugehörigen RCs werden mit den im Vorspann genannten Versionsmetadaten veröffentlicht.

## Abschließender normaler Vorher/Nachher-Vergleich

Offizielle Gen2Recomped-APK 0.8.47, SHA-256 `8ba0e211c9a25c74d3080cc6608fa488613cc8a27932974a0535f9ed06295a8b` (132063918 Bytes). Android-15/API-35-ARM64-Emulator auf Apple M2, 4 virtuelle Kerne, 3072 MiB Gast-RAM, Host-GPU. **Kein physisches Smartphone.**

Vier frische Spielprozesse: A1, B1, B2, A2. Je Prozess 120 s echtes Gehen in Pallet und 30 s Kameraschwenken am Fenster in Silph Co. 2F. FULL, echte Fenster, Schatten, native Szene und Framebuffer 1280×720, AA 0, Tiltshift 0, Tag/klares Wetter. Bewegung, tatsächliche Szene, Schatten-Neuzeichnungen und Auflösung wurden geprüft. Alle Prozesse laden denselben per SHA-256 geprüften Ausgangsspielstand.

A ist der eingefrorene Arbeitsstand mit den bereits vorbereiteten Recovery-/Uniform-Fixes, VASC auf e931ebce und KASC auf b6e88a2. B enthält zusätzlich die vier unten beschriebenen Dateien. Die Baseline wird vor jedem Prozess vollständig wiederhergestellt; 1271 Laufzeitdateien und die jeweilige Patch-Überlagerung werden auf dem Gerät byteweise per SHA-256 geprüft. Die Messung nutzt eine private Modulregistrierung und einen privaten QA-Mod; diese kommen nicht in die Produktdateien.

Kein zusätzlicher Profiler, keine GC-Abschaltung, keine umgeleiteten Schreibzugriffe und keine Bildauslesung innerhalb der FPS-Abschnitte. Alle Intervalle einschließlich Dialogen und Ausreißern bleiben enthalten. Die Weltbilder werden außerdem separat ausgewertet. Speicherproben mit jeweils 90 nativen Frames laufen erst nach beiden FPS-Abschnitten und sind keine FPS-Nachweise.

| Szene / Messwert | Vorher A | Nachher B |
|---|---:|---:|
| Pallet, 4 Minuten je Variante: FPS | 58.356 | 59.006 |
| Pallet, 4 Minuten je Variante: 99. Perzentil, ms | 26.462 | 25.378 |
| Pallet, 4 Minuten je Variante: längster Frame, ms | 418.658 | 211.557 |
| Pallet, 4 Minuten je Variante: Frames >50 ms | 11 | 12 |
| Pallet, 4 Minuten je Variante: Frames >100 ms | 5 | 5 |
| Pallet, 4 Minuten je Variante: Frames >250 ms | 3 | 0 |
| Fenster, 1 Minute je Variante: FPS | 59.030 | 59.148 |
| Fenster, 1 Minute je Variante: 99. Perzentil, ms | 26.885 | 26.063 |
| Fenster, 1 Minute je Variante: längster Frame, ms | 73.646 | 118.523 |
| Fenster, 1 Minute je Variante: Frames >50 ms | 2 | 3 |
| Fenster, 1 Minute je Variante: Frames >100 ms | 0 | 2 |
| Fenster, 1 Minute je Variante: Frames >250 ms | 0 | 0 |

Pallet: Beide Laufpaare zeigen leicht höhere FPS (+0,78 % bzw. +1,45 %) und etwa 4,1 % niedrigere p99-Zeiten. In beiden Paaren wird die stärkste Pause kleiner; über 250 ms tritt nachher kein Frame auf. Die Zahl der Frames über 100 ms bleibt insgesamt jedoch 5.

Fenster: Der FPS-Unterschied ist nicht über beide Paare stabil. Nachher treten zwei Frames über 100 ms auf, vorher keiner. Das ist ausdrücklich kein Nachweis einer vollständig behobenen Fenster-Ruckelproblematik. Während des betroffenen Nachher-Abschnitts erreicht der Codex-Renderer laut Hostbeobachtung bis zu etwa 219 % CPU. Diese Korrelation beweist nicht die Ursache jedes Frames; die Frames wurden deshalb nicht entfernt. Auch Pallet enthält zeitweise Hostlast. Keine parallelen Spieltests bedeutet nicht völlige Host-Leerlaufgarantie.

## Übernommene Änderungen

- VASC `Gen1InteriorPanoramas.matches` prüft Raumzulassung ohne neue Tür-/Öffnungsprofile; `HorizonWall.classFor` nutzt diese reine Abfrage. `profileFor` liefert weiterhin vollständige frische abgeleitete Türdaten. Live-Änderungen an Warps, Eigentümer, Abmessungen, Tileset und Verbindungen bleiben wirksam.
- VASC `LocalLightGrid` verwendet ausschließlich private Vergleichsdatensätze für Lichtquellen und Blocker erneut. Eingabevektoren, öffentliche Ergebnisse, Lichtwerte und Textur-Upload-Verhalten bleiben unabhängig.
- KASC hält wiederholte historische Lernzeilen als private skalare Bytewerte und Gruppen-IDs statt vieler Tabellenverweise. Alle Quellen, Versionsgruppen, Reihenfolge und Duplikate bleiben erhalten. Öffentliche Resultate sind neue unabhängige Tabellen. Nicht passende Formate, große/gebrochene/nicht endliche Zahlen, negative Null und Metatabellen verwenden den bisherigen Kopierpfad. Kein Speichern des internen Formats, keine Datenmigration, kein LRU-Verwerfen und keine globale GC-Änderung.

Vorbereitete Recovery-Marker-Deduplizierung und optionale Uniform-Verfügbarkeitsabfragen bleiben erhalten. Fehlgeschlagene/abweichende Persistenzzustände werden weiter erneut geschrieben.

## Speicher und Ursachenbelege

- Pallet: Lua-Heap nach Vollbereinigung im Mittel 306.34 → 248.30 MiB (18.95 % weniger). Post-Sample-Allokationen 339.46 → 336.10 KiB/nativem Frame (0.99 % weniger).
- Fenster: Lua-Heap nach Vollbereinigung im Mittel 294.47 → 239.91 MiB (18.53 % weniger). Post-Sample-Allokationen 394.64 → 291.47 KiB/nativem Frame (26.14 % weniger).

Ein separater Allokationslauf mit 6 kurzen Abschnitten zeigt am Fenster etwa 85 Raumprofil-Abfragen und 123,55 KiB deren eigene Allokationen pro nativem Frame; in Pallet entstehen etwa 33–34 KiB bei den privaten Lichtvergleichen. Der Profiler wurde vor den normalen Vergleichen vollständig entfernt.

Ein vorheriger balancierter GC-/Mod-I/O-Diagnoselauf (26 Abschnitte) deutet auf GC-Druck als einen Beitrag zu großen Pausen hin; zeitweise GC-Abschaltung und RAM-Schreibumleitung dienten nur der Diagnose und werden nicht ausgeliefert. Die erzwungenen kurzen Abschnitte sind keine normalen FPS-Vergleiche.

Die spätere reine Beobachtungsdiagnose misst an einem Restframe 181 ms; expliziter GC-Schritt und Dateizugriffe erklären diesen Frame nicht. Ein unabhängiger Android-Thread läuft währenddessen weiter. Die weitere Core-Phasenmessung erfasst Restframes bis 164 ms überwiegend im Voxel-Weltdurchlauf. Eine **nach** den Samples erzwungene Vollbereinigung dauert 270–375 ms. Dies belegt hohen Bereinigungsaufwand, weist aber nicht automatisch jedem einzelnen Restframe dieselbe Ursache zu.

Die begrenzte, überlappende Datenbestandszählung erfasst beim KASC-Lernlisten-Cache mehr als 500000 Einträge und erreicht dort die Zählgrenze. Sie ist keine additive oder exakte Speichergrößenmessung. Der kompakte Cache besteht denselben vollständigen Katalogvergleich; ein separater CPU-Versuch reduziert seinen gebundenen Mehrbedarf von 11,38 auf 6,46 MiB und die mittlere Vollbereinigungszeit dieses isolierten Modells von 4,934 auf 3,808 ms. Das sind **keine** Android-FPS-Zahlen.

## Funktionsnachweise und Grenzen

- 5.023.502 skalare Vergleiche über 1351 Katalogeinträge und 28281 Anfragen: gleiche automatischen/ausdrücklichen Versionen, Form-Overrides, Fehlerantworten und Rückwärtstraversierung; beide Varianten laden und behalten dieselben 1268 Quellen.
- 11569 zusätzliche private Randfall-/Besitzvergleiche; die ins Produkt übernommenen Tests bestehen 2719 Format-/Grenzwertvergleiche und die unabhängigen Kopierprüfungen.
- 2613 Raumzulassungs-/Live-Türprüfungen; frühere differenzielle Prüfung von 145 Raumprofilen ×12 Varianten und 2500 animierten/wachsenden/schrumpfenden Licht-/Blockersnapshots: 1107199 skalare Gleichheiten.
- 30106 Recovery-/Uniform-Prüfungen; mobile und Desktop-Licht-Upload-Verträge bestanden.
- 15 eingefrorene vollständige native RGBA-Vergleiche einschließlich Pallet, 12 Fensterwinkeln und Fenster an/aus sind bitgleich und haben einen stabilen Wiederholungs-Kontrollrender. Der abschließende Cachevergleich übernimmt diesen Nachweis für die **exakt gleichen drei VASC-Dateihashes**; KASCs zusätzliche Repräsentationsänderung wird separat durch Katalog-/Kopiertests und vier echte Android-Spielstarts geprüft.
- Keine neue vollständige Gen1-Spielrunde, keine neue umfassende Kampf-/Speicher-/Schiebetür-Abnahme und kein physisches Android-Gerät in diesem Durchgang. Keine Zusage konstanter 60 FPS oder vollständiger Ruckelfreiheit auf allen Geräten.


Die privaten Rohdaten werden separat beim Maintainer aufbewahrt; keine Engine-/ROM-/Spielstanddateien sind Teil dieser Änderung.
