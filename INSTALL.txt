# Installation — Universal-RCs vom 29.10.2026

VASC 3.0.65-rc.5 und KASC 6.7.35-rc.3 sind Vorabversionen (Release Candidates). Pro Mod gibt es genau EIN ZIP für beide Recompiler:

- Voxel-Ascendant-3.0.65-rc.5-Universal.zip
- Kanto-Ascendant-6.7.35-rc.3-Universal.zip

Die gleiche Datei wird in Gen1Recomp und Gen2Recomped installiert. Gemeint sind Rot/Blau/Gelb-Inhalte in beiden Engines. Es gibt keine separate Android- oder Gen2-Ausgabe dieser ZIPs.

## Unterstützter Bereich und tatsächlich geprüft

Die Manifeste behalten den bisherigen Bereich: Gen1Recomp >=0.3.96,<0.4.0 oder Gen2Recomped >=0.8.45,<0.9.0, Mod-API 2. Das ist der deklarierte Kompatibilitätsbereich, keine vollständige Testmatrix aller Zwischenversionen. Die neue Android-Performanceprüfung lief auf Gen2Recomped 0.8.47. Für diese RCs gab es keine neue vollständige Gen1-Spielrunde und keinen Test auf einem physischen Android-Handy. Einzelne Ruckler bleiben; Details stehen in TEST_REPORT_DE.md.

## Schritt für Schritt

1. Recompiler vollständig schließen. Spielstände und bisherige Modordner sichern.
2. Die beiden ZIPs und SHA256SUMS.txt aus den beiden zugehörigen RC-Releases verwenden. Auf GitHub die benannten Release-Assets laden, nicht die automatisch erzeugten „Source code“-Archive.
3. Den mods-Ordner der AKTIVEN Recompiler-Installation öffnen. Bei zwei Installationen hat jede ihren eigenen Modordner. Alte VASC-/KASC-Kopien aus diesem aktiven Ordner herausnehmen; Backups außerhalb des mods-Ordners aufbewahren, damit sie nicht als doppelte Mods erkannt werden.
4. Beide ZIPs direkt in diesen mods-Ordner entpacken. Keine zusätzliche gemeinsame Oberordnerebene anlegen. Das Ergebnis muss so aussehen:

```text
mods/
  VOXEL_ASCENDANT/
    manifest.json      (Version 3.0.65-rc.5)
    main.lua
  kanto_ascendant/
    manifest.json      (Version 6.7.35-rc.3)
    entry.lua
```

5. Spielstände, Optionen und mod_cache behalten; nicht für diese Installation löschen. Recompiler starten und im Modmanager VASC und KASC aktivieren. Für den ersten Vergleich andere Grafik-/Gameplay-Mods deaktivieren, einschließlich des mitgelieferten DramaticShapes-Mods in Gen2Recomped. Das entspricht der Testkonfiguration.
6. Rot, Blau oder Gelb starten. Prüfen, dass genau eine Kopie jedes Mods mit den oben genannten Versionen erscheint und kein Ladefehler gemeldet wird.
7. Für den dokumentierten Grafikvergleich VASC auf DEVICE PROFILE: CUSTOM, SCENERY: FULL, REAL WINDOWS: ON, Schatten an, 3D RESOLUTION: NATIVE, AA aus (0) und T-SHIFT: OFF stellen. Bereits gespeicherte Einstellungen werden nicht automatisch zurückgesetzt. „Nativ“ meint die tatsächliche Auflösung deines Geräts; die Messungen im Bericht verwenden 1280×720 im Emulator.

Für die zweite Engine die gleichen beiden ZIPs in deren eigenen mods-Ordner installieren. Nicht VASC doppelt oder zusätzlich eine ältere Gen1-/Gen2-Spezialausgabe aktivieren.

## Android-Ordner

Im getesteten Gen2Recomped-Paket war der Modordner:

```text
Android/data/com.underdecodedhd.gen2recomp/files/save/pokemon-love2d/mods/
```

Der tatsächliche Pfad kann je App-/Portable-Profil abweichen; maßgeblich ist der Modordner deiner aktiven Installation. Android kann den direkten Zugriff auf Android/data beschränken. Nutze dann einen von App und Betriebssystem angebotenen Ordnerzugriff bzw. Dateiimport, falls deine Version ihn anbietet; ein ZIP nur im Downloadordner wird nicht automatisch installiert. Die oben gezeigte Ordnerstruktur ist das Ziel der Installation.

## Prüfsummen

Im Ordner mit den Downloads unter macOS ausführen:

```sh
shasum -a 256 -c SHA256SUMS.txt
```

Unter Linux: `sha256sum -c SHA256SUMS.txt`. Unter Windows PowerShell etwa `Get-FileHash .\Voxel-Ascendant-3.0.65-rc.5-Universal.zip -Algorithm SHA256`; Ergebnis mit der passenden Zeile in SHA256SUMS.txt vergleichen. Es gibt außerdem je ZIP eine eigene .sha256-Datei. Prüfsummen gelten für das unveränderte heruntergeladene ZIP, nicht für einen nachträglich neu gepackten Ordner.

## Zurückwechseln / Fehlerbericht

Zum Zurückwechseln Recompiler schließen, neue Modordner aus dem aktiven mods-Verzeichnis herausnehmen und gesicherte alte Modordner wiederherstellen. Die interne Cache-Darstellung führt keine Spielstandmigration ein. Wenn du seit dem Wechsel gespielt/gespeichert hast, ist die vorher gesicherte Spielstandkopie dein Rückweg zu diesem früheren Stand.

Bei Problemen Recompiler-Version, Spiel/Edition, Betriebssystem bzw. Android-Gerät, beide Modversionen, genaue Stelle/Kameraperspektive und Fehlermeldung nennen. Die RCs versprechen keine konstante 60-FPS-Darstellung auf allen Geräten.
