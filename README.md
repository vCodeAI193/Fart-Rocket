# 🚀 Fart Rocket

Ein physikbasiertes 2D-Spiel für **Android-Tablets**, entwickelt mit **Godot 4.3**.
Steuere ein Strichmännchen, das sich mit **Furz-Stößen** wie eine Rakete durch
hindernisreiche Weltraum-Level bewegt. Sammle Münzen, weiche Hindernissen und
Gegnern aus, nutze Power-ups und erreiche die Zielflagge — mit Dutzenden
Spielmodi, einem Fortschritts-/Shop-System, Erfolgen und mehr.

Das Projekt ist aus einem kleinen Prototyp (3 Level, ein Skript) zu einem
umfangreichen Spiel mit über 100 Skripten, ~90 Gameplay-Objekttypen und 7
Leveln gewachsen. 358 von 500 geplanten Features aus
[`BACKLOG.md`](BACKLOG.md) sind bereits umgesetzt.

## 🎮 Spielprinzip

- **Halten & Ziehen** auf dem Touchscreen → Zielrichtung festlegen (gelber Pfeil)
- **Loslassen** → Furz-Stoß propelliert das Männchen in Zugrichtung
- Die **Schwerkraft** zieht das Männchen ständig nach unten
- Das Männchen **rotiert** passend zur Flugrichtung
- **Begrenzte Furz-Ladungen** pro Level (Icons im HUD), die sich mit der Zeit
  wieder aufladen
- **Hindernis oder Gegner berührt** = Level-Neustart (mit Trudel-Animation)
- **Flagge erreicht** = Level geschafft + **Stern-Bewertung (1–3)** je nach
  übrigen Furz-Ladungen
- Über 20 verschiedene **Spielmodi** (Zeitrennen, Endlos, Hardcore, Zen,
  Geister-Rennen, Tages-Lauf, Chaos, …) — siehe unten

## 🏗️ Architektur: Autoloads

Globaler Zustand ist auf sieben Autoload-Singletons aufgeteilt (siehe
`[autoload]` in `project.godot`). Die Ladereihenfolge ist bewusst gewählt:
Jeder Autoload kann nur auf Autoloads verweisen, die *vorher* geladen wurden
oder deren Referenz erst zur Laufzeit (nicht in `_ready()`) gebraucht wird.

| Reihenfolge | Autoload             | Zuständigkeit |
|-------------|-----------------------|---------------|
| 1 | `GameManager.gd`       | Kern-Spielzustand: aktuelles Level, Furz-Ladungen, Combo, Münzen pro Lauf, dauerhaftes Guthaben (`persistent_coins`), Sterne/XP, Gesamtlautstärke (`master_volume`), restliche Steuerungs-/Kamera-/HUD-/Grafik-Einstellungen, zentrale Signale. Bindeglied zwischen den anderen Managern. |
| 2 | `CosmeticsManager.gd`  | Kosmetik-Katalog (`COSMETIC_CATALOG`), Freischaltung, Ausrüstung (Mix&Match: Helm/Anzug/Hut/Pfeil/Tod-Animation/Sieges-Pose/Furz-Farbe/-Sound), Skin-Farben. Bezieht Käufe über `GameManager.persistent_coins`. |
| 3 | `SaveManager.gd`       | Verschlüsseltes, Prüfsummen-gesichertes Mehrfach-Profil-Speichersystem (3 Speicherplätze), atomare Schreibvorgänge, automatische Backups mit Korruptions-Fallback, separate Einstellungen-Datei. Liest/schreibt Felder aus allen anderen Managern per Cross-Reference. |
| 4 | `SoundManager.gd`      | Prozedurale Musik (Menü/Level/Boss), Sieg-Fanfare/Countdown/Combo-Sounds, UI-Klick- und Furz-Sound-Synthese, Stummschaltung, zweiter Audio-Bus ("Music") für eine von der Gesamtlautstärke getrennte Musik-Lautstärke. |
| 5 | `AccessibilityManager.gd` | Barrierefreiheits-/Einstellungs-Felder (Farbenblind-Modus, hoher Kontrast, reduzierte Bewegung, Menü-Skalierung, Sound-Untertitel, Einhand-Modus, Ziel-Assistenz, FPS-Anzeige/-Limit, Sprache, ...). |
| 6 | `GameModeManager.gd`   | Spielmodi (`GameMode`-Enum, `GAME_MODE_INFO`), aktiver Modus, Bestwerte je Modus, Zeitrennen-Bestzeiten, Geister-Pfade, Tages-Seed. |
| 7 | `AchievementManager.gd`| Lokales Achievement-/Herausforderungs-Framework. Abonniert Statistik-Signale von `GameManager` (z.B. `persistent_coins_changed`), vergibt Kosmetik-Belohnungen über `CosmeticsManager.grant_cosmetic_free()`. |
| 8 | `LocalizationManager.gd`| Lokalisierungs-System. Liest `AccessibilityManager.language` beim Start. |

**Warum die ausgelagerten Manager kaum eigenen Zustand besitzen, den nicht
schon ihr Name beschreibt:** Alle wurden aus `GameManager.gd` herausgelöst
(das war auf über 2100 Zeilen angewachsen), lesen/schreiben aber teils
weiterhin Felder, die inhaltlich zu einem anderen Manager gehören (z.B.
`persistent_coins` bleibt in `GameManager`, obwohl `CosmeticsManager` und
`GameModeManager` es für Käufe/Bestwerte lesen), über `Manager.xxx`-Cross-
Referenzen statt physischer Verschiebung. Das hält jeden einzelnen
Refactoring-Schritt überschaubar. `master_volume`/`set_master_volume()`
bleiben bewusst in `GameManager.gd` (nicht in `SoundManager`/
`AccessibilityManager`), da sie denselben Master-Bus (Index 0) steuern, den
`SoundManager.apply_mute()` stummschaltet — beides über zwei Dateien zu
verteilen hätte die Kontrolle über einen einzelnen Audio-Bus aufgespalten.

## 💾 Speichersystem (SaveManager.gd)

- **3 Speicherplätze** (`SAVE_SLOT_COUNT`), umschaltbar über
  `SaveManager.switch_save_slot(slot)`.
- Spielstände werden **verschlüsselt** (`ConfigFile.save_encrypted_pass`)
  unter `user://fartrocket_save_slot<N>.cfg` abgelegt, mit einer eigenen
  **Prüfsumme** über den Inhalt.
- **Atomares Schreiben**: Erst in eine temporäre Datei schreiben, dann
  umbenennen — verhindert korrupte Spielstände bei Absturz/Stromausfall
  mitten im Schreibvorgang.
- **Automatische Backups** (bis zu 5 pro Speicherplatz) nach jedem
  erfolgreichen Speichern. Schlägt das Laden der Primärdatei fehl (fehlende
  Datei, ungültige Prüfsumme, korrupter Inhalt), fällt `_load_progress()`
  automatisch auf das letzte gültige Backup zurück.
- **Einstellungen** (Steuerung, Kamera, HUD, Grafik, Audio, Barrierefreiheit)
  liegen in einer eigenen, vom Spielfortschritt unabhängigen Datei
  (`fartrocket_settings.cfg`) — ein Fortschritts-Reset wirkt sich nie auf
  Einstellungen aus und umgekehrt.
- Öffentliche Einstiegspunkte: `save_now()`, `load_now()`,
  `save_settings()`, `load_settings()`, `export_save()`, `list_backups()`,
  `restore_backup()`, `reset_all_progress()`, `delete_all_user_data()`.

## 🕹️ Spielmodi (GameManager.GameMode)

Über `GameModeScreen.gd` wählbar, `GameManager.active_game_mode` steuert das
Verhalten in `Main.gd`/`Player.gd`. Auszug aus den 19 Modi (vollständige
Liste + Beschreibungen in `GameManager.GAME_MODE_INFO`):

Normal · Zeitrennen · Endlos · Überleben · Hardcore (1 Ladung) · Zen
(kein Tod) · Münzjagd · Boss-Rush · Spiegel · Mutator (zufälliger Modifikator)
· Tages-Lauf (täglicher Seed für alle) · Geister-Rennen (Bestzeit-Geist) ·
Kein Treibstoff · Präzision · Marathon · Dunkel · Umgekehrte Schwerkraft ·
Chaos · Übung (Soforts-Neustart).

## 🧩 Ein neues Level hinzufügen

1. Neue Szene unter `levels/LevelN.tscn` anlegen (an bestehenden Leveln
   orientieren: `Obstacle`-, `Coin`-, Gegner- und Power-up-Instanzen als
   Kindknoten, `LevelEnd`-Zielflagge, Start-Ladungsanzahl).
2. Pfad in `GameManager.LEVEL_SCENES` (bzw. der levelbezogenen Konstante in
   `GameManager.gd`) ergänzen — `get_level_scene_path()` liest daraus.
3. Falls das Level neue Hindernis-/Gegnertypen einführt: ggf. in
   `OBSTACLE_UNLOCK_LEVELS` (FR-319, stufenweise Freischaltung) eintragen.
4. Stern-Schwellen ergeben sich automatisch aus den Start-Ladungen über
   `GameManager.calculate_stars()` — keine manuelle Konfiguration nötig.
5. Die über 90 Gameplay-Objektskripte (`scripts/*.gd`: Hindernisse, Gegner,
   Power-ups, Umgebungszonen wie `WindZone`/`IceZone`/`BuoyancyZone`, …)
   lassen sich als vorgefertigte Szenen in jedes Level einsetzen.

## 🧪 Tests & CI

Da in dieser Entwicklungsumgebung kein Godot-Editor/-Binary verfügbar ist,
gibt es ein schlankes, selbstgeschriebenes GDScript-Test-Framework unter
`tests/` (kein Drittanbieter-Addon):

- `tests/TestCase.gd` — Basisklasse mit `assert_eq`/`assert_true`/
  `assert_false`/`assert_almost_eq`/`assert_gt`.
- `tests/TestMain.gd` (+ `TestMain.tscn`) — Test-Runner: entdeckt alle
  `tests/test_*.gd`-Dateien, ruft per Reflection alle `test_*()`-Methoden
  auf, fasst Fehlschläge zusammen und beendet den Prozess mit Exit-Code `0`
  (alle bestanden) oder `1` (mindestens ein Fehlschlag) — für CI.
- Kern-Tests: Sternebewertung, Erfolgs-Freischaltung, Speichern/Laden inkl.
  Backup-Wiederherstellung bei korrupter Datei, Kosmetik-Kauf-/Freischalt-Logik.

`.github/workflows/tests.yml` lädt bei jedem Push/PR ein Godot-4.3-Headless-
Build herunter, führt zunächst einen reinen Import-/Parse-Durchlauf als
Compile-Smoke-Test aus (fängt z.B. doppelt deklarierte Funktionen ab) und
führt danach `tests/TestMain.tscn` aus.

## 📁 Projektstruktur

```
Fart-Rocket/
├── project.godot          # Projektkonfiguration (Landscape, Touch, 1920x1200, Autoloads)
├── export_presets.cfg     # Android-Export (API 21+)
├── BACKLOG.md             # 500-Feature-Backlog (Fortschritt: 358/500)
├── icon.svg               # App-Icon
├── scripts/                       # >100 GDScript-Dateien
│   ├── GameManager.gd             # Autoload: Kern-Zustand
│   ├── CosmeticsManager.gd        # Autoload: Kosmetik/Skins
│   ├── SaveManager.gd             # Autoload: Speichersystem
│   ├── SoundManager.gd            # Autoload: Musik/Audio
│   ├── AccessibilityManager.gd    # Autoload: Barrierefreiheit/Einstellungen
│   ├── GameModeManager.gd         # Autoload: Spielmodi
│   ├── AchievementManager.gd      # Autoload: Erfolge/Herausforderungen
│   ├── LocalizationManager.gd     # Autoload: Übersetzungen
│   ├── Player.gd                  # Männchen (RigidBody2D), Furz-Antrieb, Kosmetik-Rendering
│   ├── Main.gd                    # Level-Lader & Spielablauf
│   ├── HUD.gd, MainMenu.gd, ShopScreen.gd, SettingsScreen.gd,
│   │   GameModeScreen.gd, ProgressionScreen.gd, CollectionScreen.gd,
│   │   BestiaryScreen.gd, …       # Bildschirme/UI
│   └── Obstacle.gd, *Enemy.gd, *Zone.gd, *Pickup.gd, …
│                                   # ~90 Gameplay-Objekttypen (Hindernisse,
│                                   # Gegner, Umgebungszonen, Power-ups)
├── scenes/                # ~90 zugehörige .tscn-Szenen
├── levels/
│   ├── Level1.tscn        # Weite Lücken, wenig Hindernisse, 5 Ladungen
│   ├── Level2.tscn        # Enge Gänge, rotierende Sägen, 4 Ladungen
│   ├── Level3.tscn        # Kombination aus allem, 3 Ladungen
│   ├── Level4.tscn        # Höhlen-Thema, erste Gegner (Patrol/Jumping), 4 Ladungen
│   ├── Level5.tscn        # Verzweigter Pfad (FR-134): obere/untere Route, 4 Ladungen
│   ├── Level6.tscn        # Erster Bosskampf (MiniBoss), 3 Ladungen
│   └── Level7.tscn        # Bonus-/Geheimlevel, münzlastig, 5 Ladungen
└── tests/                 # Eigenes Test-Framework (siehe oben)
```

## 🛠️ Technische Eckdaten

| Eigenschaft        | Wert                                  |
|--------------------|---------------------------------------|
| Engine             | Godot 4.3 (GL Compatibility Renderer) |
| Basisauflösung     | 1920 × 1200 (16:10)                   |
| Stretch-Modus      | `canvas_items` / `expand`             |
| Orientierung       | Nur Querformat (Landscape)            |
| Eingabe            | Touch (Maus-Emulation am Desktop)     |
| Min. Android API   | 21                                    |
| Package-Name       | `com.fartrocket.game`                 |
| Version            | `0.2.0` (Code 2)                      |

## ▶️ Starten

1. Projekt in **Godot 4.3** öffnen (`project.godot`).
2. Mit **F5** starten – auf dem Desktop emuliert die Maus die Touch-Eingabe.
3. Für Android: Android-Build-Vorlage installieren und über
   **Projekt → Exportieren → Android** exportieren.

## 📦 Android-Veröffentlichung: Stand & offene Schritte

`export_presets.cfg` ist so weit vorbereitet, wie es ohne echtes Android-
Gerät/-Konto in dieser Umgebung möglich ist:

- **Package-Name** (`com.fartrocket.game`) ist kein Platzhalter mehr,
  sollte vor einer echten Veröffentlichung aber final auf eine Domain
  festgelegt werden, die ihr tatsächlich kontrolliert.
- **Berechtigungen**: `vibrate` korrigiert auf `true` (Haptik wird an
  über 100 Stellen im Code genutzt, war aber nie freigegeben).
  `internet`/`access_network_state`/`write_external_storage` bleiben
  `false` — das Spiel macht keine Netzwerkaufrufe und speichert
  ausschließlich in den app-eigenen `user://`-Pfad.
- **Launcher-Icons**: `icons/android/*.png` wurden prozedural (reines
  Python, ohne Bildbearbeitungs-Tools/-Bibliotheken) im selben Flach-
  Design wie `icon.svg` erzeugt — Haupt-Icon (192×192) sowie adaptive
  Vordergrund-/Hintergrund-/Monochrom-Varianten (432×432) für Android 8+/
  13+. Bewusst ehrlich: das ist einfache Geometrie, kein illustriertes
  App-Icon — vor einer echten Store-Veröffentlichung lohnt sich ein
  Durchgang mit echtem Grafik-Werkzeug.
- **Versionierung**: `version/code`/`version/name` folgen ab jetzt
  Semantic Versioning (`MAJOR.MINOR.PATCH`) mit einem bei jeder
  Veröffentlichung um 1 erhöhten `version/code` — z.B. `0.2.0`/Code 2 für
  diesen Batch.
- **Nicht Teil dieser Vorbereitung** (liegt außerhalb der Sandbox):
  Signing-Keystore, Gradle-Build-Aktivierung, Google Play Billing/Play
  Games Login, Store-Listing (Screenshots/Video), sowie das eigentliche
  Erstellen/Hochladen eines Android-Builds.

## 🔊 Audio

Sämtliche Sounds (Furz-Stöße, UI-Feedback, Untertitel-Texte für
Barrierefreiheit) werden **prozedural per Code** erzeugt (`AudioStreamWAV`/
`AudioStreamGenerator`), keine externen Audio-Assets.

## 🎨 Grafik

Es werden **keine externen Assets** verwendet – alle Grafiken (Strichmännchen,
Kosmetik-Items, Münzen, Hindernisse, Furz-Wolke, Hintergrund) werden per Code
aus `Line2D`, `Polygon2D`, `CPUParticles2D` und Farbverläufen erzeugt.
