# 🎯 Fart Rocket — 50-Feature-Batch

Konkrete, in dieser Entwicklungsumgebung umsetzbare Features (kein Backend,
kein Play-Konto, kein echtes Gerät). Ergänzt [`BACKLOG.md`](BACKLOG.md) um
Spielgefühl-/Grafik-/Design-Verbesserungen, die dort nicht als eigene
FR-IDs geführt werden, und schließt gezielt noch offene FR-Punkte.

**Legende:** `[ ]` offen · `[x]` erledigt

---

## A. Spielgefühl & "Juice" (Player.gd)

Das Spiel hat bereits Screen-Shake, Flug-Trail, Speed-Lines, Hit-Stop beim
Tod und Ragdoll. Was fehlt, ist Lebendigkeit am Männchen selbst.

- [x] **F01** Squash & Stretch beim Furz-Stoß (Stauchen im Moment des Impulses)
- [x] **F02** Stretch in Flugrichtung bei hoher Geschwindigkeit
- [x] **F03** Dynamische Mimik: Angst-Gesicht bei hoher Geschwindigkeit
- [x] **F04** Dynamische Mimik: Konzentrations-Gesicht beim Zielen
- [x] **F05** Dynamische Mimik: Schreck-Gesicht bei Beinahe-Treffer
- [x] **F06** Landungs-Staubwolke bei Bodenkontakt
- [x] **F07** Aufprall-Funken beim Abprallen an Wänden
- [x] **F08** Kurzer Hit-Stop bei Beinahe-Treffern (nicht nur beim Tod)
- [x] **F09** Blinzel-Animation im Ruhezustand
- [x] **F10** Arm-Rudern beim freien Fall

## B. Grafik & Atmosphäre

- [x] **F11** Vordergrund-Parallax-Ebene (Silhouetten nahe der Kamera)
- [x] **F12** Themen-abhängige Vordergrund-Elemente je Level
- [x] **F13** Bildschirm-Flash bei Beinahe-Treffer
- [x] **F14** Kamera-Zoom-Punch beim Furz-Stoß
- [x] **F15** Münz-Sammel-Funken skalieren mit der Combo-Stufe
      (ein Basis-Burst existierte bereits als FR-261, war aber bei jeder
      Münze identisch — jetzt Umfang/Farbe je nach Serie)
- [x] **F16** Boss-Einführungs-Kamerafahrt beim Levelstart
- [x] **F17** Level-Start-Einblendung mit Level-Name/Nummer
- [x] **F18** Farb-Puls-Effekt beim Levelabschluss

## C. Audio (offene BACKLOG-Punkte)

- [x] **F19** FR-243 Münz-Sammel-Sounds mit steigender Tonleiter
- [x] **F20** FR-244 Erweiterte Furz-Sound-Bibliothek (mehr Varianten)
- [x] **F21** FR-245 Treffer- und Tod-Sounds
- [x] **F22** FR-248 Ambient-Soundscapes pro Level-Thema
- [x] **F23** FR-258 Audio-Bus-Setup mit Reverb-Effekt
- [x] **F24** FR-016 Furz-Sound an Aufladungsgrad koppeln
- [x] **F25** Boss-Besiegt-Fanfare (eigener Stinger)

## D. Gameplay & Mechanik

- [x] **F26** FR-017 Nachziehende Geruchswolke (verzögerte Rest-Wolke)
- [x] **F27** FR-018 Klebriger Furz: kurzes Haften an Wänden
- [x] **F28** Risiko/Belohnung auf dem verzweigten Pfad (Level5)
- [x] **F29** Zweites Boss-Level (Level8 mit EndBoss)
- [x] **F30** Tutorial-Hinweis beim ersten Gegner-Kontakt
- [x] **F31** Mehrere Boss-Level unterstützen (BOSS_LEVEL_INDEX → Liste)
- [x] **F32** Combo-Verlust-Warnung kurz vor Ablauf des Zeitfensters
- [x] **F33** Münz-Magnet: sichtbarer Wirkradius beim Aufsammeln

## E. UI-Deduplizierung fertigstellen

`UIHelpers.gd` existiert, aber bislang wurde nur `make_close_button()`
migriert — 45 rohe `Label.new()` und 25 rohe `Button.new()` verbleiben.

- [ ] **F34** `UIHelpers.make_label()` ergänzen
- [ ] **F35** `UIHelpers.make_title_label()` ergänzen
- [ ] **F36** ShopScreen.gd auf UIHelpers migrieren
- [ ] **F37** ProgressionScreen.gd migrieren
- [ ] **F38** CollectionScreen.gd migrieren
- [ ] **F39** MainMenu.gd + GameModeScreen.gd migrieren

## F. Tests (Abdeckungslücken schließen)

Drei Autoloads haben aktuell null dedizierte Tests.

- [ ] **F40** `test_accessibility_manager.gd`
- [ ] **F41** `test_game_mode_manager.gd`
- [ ] **F42** `test_localization_manager.gd`
- [ ] **F43** `test_level_config.gd` (TOTAL_LEVELS/LEVEL_SCENES/level_stars konsistent)
- [ ] **F44** `test_cosmetics_catalog.gd` (Katalog-Integrität)
- [ ] **F45** `test_ui_helpers.gd` (UIHelpers-Fabrikfunktionen)

## G. Performance & Technik (offene BACKLOG-Punkte)

- [x] **F46** FR-466 Reduzierte Partikelmenge auf schwachen Geräten
- [x] **F47** FR-467 Automatische Qualitätserkennung beim Start
- [ ] **F48** FR-470 Asset-Vorladen für das nächste Level
- [ ] **F49** FR-473 Shader-Vorkompilierung beim Start
- [ ] **F50** FR-477 ANR-Vermeidung: teure Schleifen entzerren

---

## Umsetzungs-Hinweis

Verifikation erfolgt wie im gesamten Projekt statisch (Grep-Konsistenz-
prüfungen: doppelte Funktionsnamen, Tab-Einrückung, Klammer-Balance) —
ein echter Godot-Lauf passiert ausschließlich in der GitHub-Actions-CI
(`.github/workflows/tests.yml`) nach dem Push.
