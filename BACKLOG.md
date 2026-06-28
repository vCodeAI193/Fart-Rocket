# 🚀 Fart Rocket — Feature-Backlog (500 offene Features)

Dieses Backlog sammelt **500 offene Features** fuer Fart Rocket, gruppiert in 25 Themenbereiche. Jedes Feature hat eine stabile ID (`FR-001` … `FR-500`), mit der es spaeter einzeln angegangen und umgesetzt werden kann.

## Legende

- `[ ]` offen · `[~]` in Arbeit · `[x]` erledigt
- IDs sind stabil und werden **nicht** neu vergeben, auch wenn Features erledigt werden.

## Inhaltsverzeichnis

1. [Antrieb & Furz-Mechanik](#antrieb-furz-mechanik) — FR-001–FR-020 (20)
2. [Physik & Bewegung](#physik-bewegung) — FR-021–FR-040 (20)
3. [Steuerung & Eingabe](#steuerung-eingabe) — FR-041–FR-060 (20)
4. [Hindernisse & Gefahren](#hindernisse-gefahren) — FR-061–FR-080 (20)
5. [Sammelobjekte & Power-ups](#sammelobjekte-power-ups) — FR-081–FR-100 (20)
6. [Gegner & KI](#gegner-ki) — FR-101–FR-120 (20)
7. [Level-Design & Inhalte](#level-design-inhalte) — FR-121–FR-140 (20)
8. [Level-Editor & UGC](#level-editor-ugc) — FR-141–FR-160 (20)
9. [Maennchen-Anpassung & Skins](#maennchen-anpassung-skins) — FR-161–FR-180 (20)
10. [Kamera & Sicht](#kamera-sicht) — FR-181–FR-200 (20)
11. [HUD & In-Game-UI](#hud-in-game-ui) — FR-201–FR-220 (20)
12. [Menues & Navigation](#menues-navigation) — FR-221–FR-240 (20)
13. [Audio & Musik](#audio-musik) — FR-241–FR-260 (20)
14. [Visuelle Effekte & Juice](#visuelle-effekte-juice) — FR-261–FR-280 (20)
15. [Shader & Rendering](#shader-rendering) — FR-281–FR-300 (20)
16. [Fortschritt & Meta-Progression](#fortschritt-meta-progression) — FR-301–FR-320 (20)
17. [Erfolge & Herausforderungen](#erfolge-herausforderungen) — FR-321–FR-340 (20)
18. [Spielmodi](#spielmodi) — FR-341–FR-360 (20)
19. [Events & Live-Ops](#events-live-ops) — FR-361–FR-380 (20)
20. [Soziales & Bestenlisten](#soziales-bestenlisten) — FR-381–FR-400 (20)
21. [Speichern & Cloud](#speichern-cloud) — FR-401–FR-420 (20)
22. [Einstellungen & Barrierefreiheit](#einstellungen-barrierefreiheit) — FR-421–FR-440 (20)
23. [Lokalisierung & i18n](#lokalisierung-i18n) — FR-441–FR-460 (20)
24. [Performance & Technik](#performance-technik) — FR-461–FR-480 (20)
25. [Android-Plattform & Veroeffentlichung](#android-plattform-veroeffentlichung) — FR-481–FR-500 (20)

## Antrieb & Furz-Mechanik

- [x] **FR-001** Furz-Aufladung ueber Zeit — optional regenerierende Ladungen pro Level
- [x] **FR-002** Mehrere Furz-Typen (Mega-Furz, Mini-Furz, Doppel-Stoss)
- [x] **FR-003** Furz-Combo-System — schnelle Folgefuerze geben Bonus-Schub
- [ ] **FR-004** Treibstoff-Modus mit Ladungsbalken statt fester Ladungen
- [x] **FR-005** Aufgeladener Furz — laenger halten ergibt staerkeren Stoss
- [x] **FR-006** Seitlicher Furz-Rueckstoss dreht das Maennchen kontrolliert
- [ ] **FR-007** Dauerstrahl-Furz bei gehaltenem Finger (kontinuierlicher Schub)
- [x] **FR-008** Cooldown/Kuehlzeit zwischen einzelnen Furz-Stoessen
- [ ] **FR-009** Winkel-Praezisions-Bonus — perfekter Zielwinkel gibt mehr Schub
- [x] **FR-010** Furz-Schild — kurzer Schutz unmittelbar nach einem Stoss
- [x] **FR-011** Treibstoff-Pickups fuellen Ladungen mitten im Level auf
- [ ] **FR-012** Ueberhitzung bei zu vielen Fuerzen (Risiko/Belohnung)
- [x] **FR-013** Wind-Interaktion — Gegenwind reduziert den Furz-Schub
- [ ] **FR-014** Unterwasser-Furz mit Blasen und Auftriebsverhalten
- [ ] **FR-015** Schwerelosigkeits-Zonen veraendern die Furz-Wirkung
- [ ] **FR-016** Furz-Sound variiert dynamisch mit der Stoss-Staerke
- [ ] **FR-017** Verweilende Geruchswolke als optionale Schadenszone
- [ ] **FR-018** Sticky-Furz — kurzes Haften an Waenden nach Aufprall
- [x] **FR-019** Furz-Boost-Ringe laden beim Durchfliegen sofort eine Ladung
- [ ] **FR-020** Anpassbare Furz-Schubkurven fuer Tuning im Editor

## Physik & Bewegung

- [x] **FR-021** Variable Schwerkraft pro Level (Mond, Jupiter, ...)
- [x] **FR-022** Umkehrbare Schwerkraftrichtung fuer Decken-Sektionen
- [ ] **FR-023** Auftrieb-/Wasserzonen mit eigener Physik
- [x] **FR-024** Bewegliche Plattformen als sichere Landeflaechen
- [x] **FR-025** Foerderbaender, die das Maennchen verschieben
- [x] **FR-026** Sprungfedern/Trampoline zum Abprallen
- [x] **FR-027** Magnetfelder, die das Maennchen ziehen oder abstossen
- [x] **FR-028** Schleim-/Klebezonen verlangsamen die Bewegung
- [ ] **FR-029** Eis-/Glaettezonen mit reduzierter Reibung
- [x] **FR-030** Luftstroemungen und Wind-Tunnel
- [ ] **FR-031** Schwarze Loecher mit Anziehungskraft
- [x] **FR-032** Konfigurierbare Terminalgeschwindigkeit/Speed-Limit
- [x] **FR-033** Einstellbare Drall-Daempfung (abklingende Rotation)
- [ ] **FR-034** Bouncy-Walls mit Energieerhalt beim Abprall
- [ ] **FR-035** Zerstoerbare Waende abhaengig von der Aufprallgeschwindigkeit
- [ ] **FR-036** Bullet-Time-/Zeitlupen-Zonen
- [ ] **FR-037** Pendel-/Seilschwung-Mechanik an Greifpunkten
- [ ] **FR-038** Massen-Pickups veraendern kurzzeitig die Traegheit
- [ ] **FR-039** Umschaltbare realistische Luftreibung
- [ ] **FR-040** Ragdoll-Physik fuer die Tod-Animation

## Steuerung & Eingabe

- [ ] **FR-041** Zwei-Finger-Zoom der Kamera
- [ ] **FR-042** Umschaltbare Steuerschemata (Slingshot vs. Direktstoss)
- [ ] **FR-043** Links-/Rechtshaender-Modus mit gespiegeltem HUD
- [ ] **FR-044** Einstellbare Touch-Empfindlichkeit und Dead-Zone
- [x] **FR-045** Haptisches Feedback (Vibration) bei Furz und Treffer
- [ ] **FR-046** Optionale Gamepad-Unterstuetzung
- [ ] **FR-047** Tastatur-/Maus-Unterstuetzung fuer Desktop-Tests
- [x] **FR-048** Flugbahn-Vorschau (Trajektorie) beim Zielen
- [ ] **FR-049** Anpassbare Visualisierung von Pfeil-Laenge und -Staerke
- [x] **FR-050** Doppel-Tipp fuer Schnell-Neustart
- [ ] **FR-051** Wisch-Geste zum Pausieren
- [ ] **FR-052** Zielen mit Zeitlupe zur Feinjustierung
- [ ] **FR-053** Auto-Aim-Unterstuetzung als Assist-Modus
- [ ] **FR-054** Konfigurierbare Safe-Area fuer Notch/Raender
- [ ] **FR-055** Multitouch-robuste Eingabe (zweiter Finger ignoriert)
- [ ] **FR-056** Eingabe-Pufferung fuer reaktionsschnelle Stoesse
- [ ] **FR-057** Verbesserte Tipp-vs-Zieh-Erkennung mit UI-Schwellwert
- [ ] **FR-058** Bildschirm-Sperre waehrend kritischer Aktionen
- [ ] **FR-059** Steuerungs-Kalibrierung im Optionsmenue
- [ ] **FR-060** Geste zum Zuruecksetzen der Kamera

## Hindernisse & Gefahren

- [ ] **FR-061** Weitere Saegeblatt-Groessen und -Muster
- [ ] **FR-062** Bewegliche Stachel-Walzen
- [ ] **FR-063** Pendelnde Stachelkugeln (Morgenstern)
- [ ] **FR-064** Ein-/ausfahrende Stacheln als Timing-Raetsel
- [ ] **FR-065** Laserstrahlen mit Intervall-Schaltung
- [ ] **FR-066** Feuerspeier-/Flammenwerfer-Duesen
- [ ] **FR-067** Fallende Felsbrocken und Truemmer
- [ ] **FR-068** Zerbroeckelnde Plattformen
- [ ] **FR-069** Elektro-Zaeune und Stromfelder
- [ ] **FR-070** Rotierende Hindernis-Raeder mit Luecken
- [ ] **FR-071** Wandernde Laserwaende (Quetsch-Gefahr)
- [ ] **FR-072** Giftgaswolken als zeitbegrenzte Zonen
- [ ] **FR-073** Schliessende Tueren/Tore mit Timing
- [ ] **FR-074** Kreissaegen auf Schienen
- [ ] **FR-075** Komplexe Hindernis-Maschinen (Verbuende)
- [ ] **FR-076** Wasserfaelle, die nach unten druecken
- [ ] **FR-077** Klebrige Spinnweben (Verzoegerung oder Tod)
- [ ] **FR-078** Tickende Minen, die bei Naehe explodieren
- [ ] **FR-079** Zufaellig generierte Hindernis-Layouts per Seed
- [ ] **FR-080** Telegrafierte Angriffe mit Vorwarn-Animationen

## Sammelobjekte & Power-ups

- [x] **FR-081** Verschiedene Muenz-Werte (Bronze/Silber/Gold)
- [x] **FR-082** Edelsteine als Premium-Sammelobjekt
- [ ] **FR-083** Magnet-Power-up zieht Muenzen an
- [x] **FR-084** Schild-Power-up ueberlebt einen Treffer
- [x] **FR-085** Verlangsamungs-Power-up (Zeitlupe)
- [x] **FR-086** Zeitlich begrenztes Doppel-Muenzen-Power-up
- [x] **FR-087** Extra-Furz-Ladung als Pickup
- [ ] **FR-088** Versteckte Sterne als Sammelobjekt pro Level
- [ ] **FR-089** Sammelkarten-/Sticker-System
- [ ] **FR-090** Truhen mit Zufallsbelohnung
- [ ] **FR-091** Schluessel und Schloesser (Tuer-Mechanik)
- [ ] **FR-092** Buchstaben sammeln (F-A-R-T Bonus)
- [ ] **FR-093** Tagesmuenze als Login-Bonus-Objekt
- [ ] **FR-094** Mystery-Box mit Power-up-Roulette
- [ ] **FR-095** Combo-Muenzketten (alle in Folge = Bonus)
- [ ] **FR-096** Schwebende Muenz-Pfade als Wegweiser
- [ ] **FR-097** Zerstoerbare Muenzbloecke
- [ ] **FR-098** Negative Objekte (Stinkbomben ziehen Punkte ab)
- [ ] **FR-099** Sammel-Fortschritt pro Level anzeigen (x/y)
- [ ] **FR-100** Power-up-Inventar zum manuellen Einsetzen

## Gegner & KI

- [ ] **FR-101** Patrouillierende Flug-Gegner
- [ ] **FR-102** Verfolger-Gegner, die dem Maennchen folgen
- [ ] **FR-103** Schiessende Gegner mit Projektilen
- [ ] **FR-104** Stationaere Geschuetztuerme
- [ ] **FR-105** Gegner, die Muenzen klauen
- [ ] **FR-106** Ausweichende Gegner
- [ ] **FR-107** Springende Boden-Gegner
- [ ] **FR-108** Schwarm-Gegner (Insekten)
- [ ] **FR-109** Schild-Gegner (nur von hinten verwundbar)
- [ ] **FR-110** Teleportierende Gegner
- [ ] **FR-111** Gegner mit telegrafierten Angriffen
- [ ] **FR-112** Mini-Boss pro Welt
- [ ] **FR-113** End-Boss mit mehreren Phasen
- [ ] **FR-114** Gegner-Spawner und Nester
- [ ] **FR-115** Gegner, die per Furz weggeblasen werden
- [ ] **FR-116** Tarn-Gegner, die bei Naehe sichtbar werden
- [ ] **FR-117** KI-Schwierigkeitsskalierung
- [ ] **FR-118** Gegner-Bestiarium/Sammlung
- [ ] **FR-119** Boss-Schwachstellen-System
- [ ] **FR-120** Gegner-Drop-Belohnungen

## Level-Design & Inhalte

- [ ] **FR-121** Welt 2: Hoehlen-Thema
- [ ] **FR-122** Welt 3: Unterwasser-Thema
- [ ] **FR-123** Welt 4: Fabrik-/Industrie-Thema
- [ ] **FR-124** Welt 5: Weltraum-Station
- [ ] **FR-125** Welt 6: Vulkan-/Lava-Thema
- [ ] **FR-126** 30 zusaetzliche Hauptlevel
- [ ] **FR-127** Bonus- und Geheimlevel
- [ ] **FR-128** Speedrun-Sektionen
- [ ] **FR-129** Autoscroller-Level
- [ ] **FR-130** Dunkelheits-Level mit begrenzter Sicht
- [ ] **FR-131** Rueckwaerts-Schwerkraft-Level
- [ ] **FR-132** Level mit beweglichem Wasserstand
- [ ] **FR-133** Pflichtlevel: alle Muenzen sammeln
- [ ] **FR-134** Mehrere verzweigte Pfade pro Level
- [x] **FR-135** Checkpoint-System in langen Leveln
- [ ] **FR-136** Versteckte Raeume mit Belohnungen
- [ ] **FR-137** Themen-spezifische Hindernis-Sets
- [ ] **FR-138** Level-Intro-Kamerafahrt
- [ ] **FR-139** Schwierigkeitsgrade pro Level (leicht/normal/schwer)
- [ ] **FR-140** Level-Vorschaubilder im Menue

## Level-Editor & UGC

- [ ] **FR-141** In-Game-Level-Editor fuer Touch
- [ ] **FR-142** Hindernisse per Drag&Drop platzieren
- [ ] **FR-143** Muenzen und Power-ups platzieren
- [ ] **FR-144** Editor-Raster und Snapping
- [ ] **FR-145** Test-Spielen direkt aus dem Editor
- [ ] **FR-146** Level als Datei speichern und laden
- [ ] **FR-147** Level-Code zum Teilen (Export/Import-String)
- [ ] **FR-148** Online-Browser fuer Community-Level
- [ ] **FR-149** Bewertungssystem fuer Community-Level
- [ ] **FR-150** Editor-Undo/Redo
- [ ] **FR-151** Kopieren und Einfuegen von Elementen
- [ ] **FR-152** Eigenschaften-Inspektor fuer Objekte
- [ ] **FR-153** Hintergrund-/Themenauswahl im Editor
- [ ] **FR-154** Start- und Zielpunkt setzen
- [ ] **FR-155** Loesbarkeits-Validierung des Levels
- [ ] **FR-156** Editor-Tutorial
- [ ] **FR-157** Vorlagen-Bibliothek
- [ ] **FR-158** Mehrebenen-/Layer-System
- [ ] **FR-159** Pfad-Editor fuer bewegliche Objekte
- [ ] **FR-160** Verwaltung eigener Level (Liste/Loeschen)

## Maennchen-Anpassung & Skins

- [ ] **FR-161** Verschiedene Helm-Designs
- [x] **FR-162** Farbauswahl fuer das Maennchen
- [ ] **FR-163** Kostueme/Outfits (Astronaut, Superheld, Tier)
- [ ] **FR-164** Furz-Wolken-Farben und -Effekte
- [ ] **FR-165** Furz-Sound-Pakete
- [ ] **FR-166** Huete und Accessoires
- [ ] **FR-167** Gesichtsausdruecke und Emotes
- [x] **FR-168** Trail-/Spur-Effekte beim Fliegen
- [ ] **FR-169** Ueber Muenzen freischaltbare Skins
- [ ] **FR-170** Seltenheitsstufen fuer Skins
- [ ] **FR-171** Skin-Vorschau im Menue
- [ ] **FR-172** Saisonale Skins
- [ ] **FR-173** Animierte Skins
- [ ] **FR-174** Skin-des-Tages
- [ ] **FR-175** Anpassbare Pfeil-Designs
- [ ] **FR-176** Varianten der Tod-Animation
- [ ] **FR-177** Sieges-Pose/Emote bei Levelende
- [ ] **FR-178** Skin-Sammlung mit Fortschrittsanzeige
- [ ] **FR-179** Mix&Match-Anpassung (Teile kombinieren)
- [ ] **FR-180** Eigener Farb-Editor fuer den Standard-Skin

## Kamera & Sicht

- [ ] **FR-181** Dynamischer Zoom je nach Geschwindigkeit
- [x] **FR-182** Kamera-Vorausschau in Bewegungsrichtung
- [x] **FR-183** Screen-Shake bei Treffern und Explosionen
- [x] **FR-184** Sanftes Kamera-Folgen mit Totzone
- [ ] **FR-185** Kamera-Grenzen (Bounds) pro Level
- [ ] **FR-186** Zielfokus-Kamera beim Zielen
- [ ] **FR-187** Kino-Modus fuer das Levelende
- [x] **FR-188** Parallax-Hintergrundebenen
- [ ] **FR-189** Einstellbare Ruettel-Intensitaet
- [ ] **FR-190** Mini-Karte/Uebersichtskarte
- [ ] **FR-191** Heranzoomen bei Zeitlupe
- [ ] **FR-192** Kamera-Stoss beim Furz-Start
- [ ] **FR-193** Rand-Indikatoren fuer Off-Screen-Objekte
- [ ] **FR-194** Verfolgungs-Kamera fuer Boss-Kaempfe
- [ ] **FR-195** Foto-/Replay-Kameramodus
- [ ] **FR-196** Kamera-Uebergaenge zwischen Sektionen
- [ ] **FR-197** Letterbox bei Zwischensequenzen
- [ ] **FR-198** Erschuetterung bei Beinahe-Treffern
- [ ] **FR-199** Fokus-Highlight auf wichtige Objekte
- [ ] **FR-200** Kamera-Glaettung in den Einstellungen

## HUD & In-Game-UI

- [x] **FR-201** Pause-Button im Spiel
- [x] **FR-202** Animierte Muenz-/Punkteanzeige
- [x] **FR-203** Combo-Zaehler-Anzeige
- [x] **FR-204** Geschwindigkeitsanzeige
- [x] **FR-205** Hoehen-/Distanzanzeige
- [x] **FR-206** Power-up-Status-Icons mit Timer
- [ ] **FR-207** Geist-Anzeige der Bestzeit
- [ ] **FR-208** Nachfuell-Animation der Furz-Ladungen
- [x] **FR-209** Schaden-/Treffer-Vignette
- [ ] **FR-210** Tutorial-Hinweis-Overlays
- [ ] **FR-211** Fortschrittsbalken zum Muenz-Ziel
- [x] **FR-212** Checkpoint-Benachrichtigung
- [ ] **FR-213** Sammel-Pop-ups (+10)
- [x] **FR-214** Aktuelle Sterne-Vorschau im HUD
- [ ] **FR-215** Minimalistischer HUD-Modus
- [ ] **FR-216** Einstellbare HUD-Skalierung
- [ ] **FR-217** Linkshaender-HUD-Layout
- [ ] **FR-218** Schnellzugriff fuer Power-up-Einsatz
- [ ] **FR-219** Live-Ranglistenposition im HUD
- [ ] **FR-220** Ein-/ausblendbare HUD-Elemente

## Menues & Navigation

- [ ] **FR-221** Welt-/Kapitelauswahl als Karte
- [x] **FR-222** Animierte Menue-Uebergaenge
- [x] **FR-223** Einstellungs-Untermenues
- [ ] **FR-224** Shop-Bildschirm
- [ ] **FR-225** Sammlungs-/Galerie-Bildschirm
- [ ] **FR-226** Statistik-Bildschirm
- [ ] **FR-227** Credits-Bildschirm
- [ ] **FR-228** Bestaetigungsdialoge (Beenden/Zuruecksetzen)
- [ ] **FR-229** Lade-Bildschirm mit Tipps
- [ ] **FR-230** Splash-Screen/Logo-Intro
- [x] **FR-231** Animierter Hauptmenue-Hintergrund
- [ ] **FR-232** Level-Detail-Popup (Sterne/Bestzeit)
- [x] **FR-233** Korrekte Android-Zurueck-Button-Behandlung
- [ ] **FR-234** Tab-Navigation in Menues
- [ ] **FR-235** Such-/Filterfunktion fuer Level
- [ ] **FR-236** Favoriten-Level markieren
- [ ] **FR-237** Fortschritts-Uebersicht (Gesamt-Prozent)
- [ ] **FR-238** Schnellstart: letztes Level fortsetzen
- [ ] **FR-239** Sound-Feedback in Menues
- [x] **FR-240** Onboarding-Begruessungsbildschirm

## Audio & Musik

- [ ] **FR-241** Hintergrundmusik pro Welt
- [ ] **FR-242** Dynamische Musik (Intensitaet bei Gefahr)
- [ ] **FR-243** Muenz-Sammel-Sounds mit steigender Tonleiter
- [ ] **FR-244** Umfangreiche Furz-Sound-Bibliothek
- [ ] **FR-245** Treffer- und Tod-Sounds
- [ ] **FR-246** Sieg-Fanfare beim Levelende
- [ ] **FR-247** UI-Klick-Sounds
- [ ] **FR-248** Ambient-Soundscapes pro Thema
- [ ] **FR-249** Getrennte Lautstaerkeregler (Musik/SFX)
- [x] **FR-250** Stumm-Schalter
- [ ] **FR-251** Audio-Ducking (Musik leiser bei SFX)
- [ ] **FR-252** Positions-/3D-Audio fuer Hindernisse
- [ ] **FR-253** Countdown-Sound beim Start
- [ ] **FR-254** Combo-Steigerungs-Sound
- [ ] **FR-255** Boss-Kampf-Musik
- [ ] **FR-256** Menue-Musik
- [ ] **FR-257** Furz-Sound an Stoss-Staerke koppeln
- [ ] **FR-258** Audio-Bus-Setup mit Effekten (Reverb)
- [ ] **FR-259** Stille-Modus fuer Hintergrund-Spielen
- [ ] **FR-260** Freischaltbare Soundpakete

## Visuelle Effekte & Juice

- [x] **FR-261** Partikel beim Muenz-Sammeln
- [x] **FR-262** Aufprall-Staub und Truemmer-Partikel
- [x] **FR-263** Explosions-Effekte
- [x] **FR-264** Geschwindigkeits-Linien bei hohem Tempo
- [x] **FR-265** Bildschirm-Blitz bei Tod
- [x] **FR-266** Hit-Stop fuer mehr Wucht
- [ ] **FR-267** Verbesserte Furz-Wolke mit mehreren Layern
- [x] **FR-268** Sieges-Konfetti am Levelende
- [ ] **FR-269** Muenz-Magnet-Spur-Effekt
- [ ] **FR-270** Slow-Mo-Visualfilter
- [x] **FR-271** Schweif hinter dem Maennchen
- [ ] **FR-272** Wasser-Spritzer-Effekte
- [ ] **FR-273** Lava-Gluehen/Hitzeflimmern
- [ ] **FR-274** Sternen-Funkeln im Hintergrund
- [x] **FR-275** Floating-Text/Schadenszahlen
- [ ] **FR-276** Wischeffekte beim Szenenwechsel
- [ ] **FR-277** Power-up-Aura um das Maennchen
- [ ] **FR-278** Umgebungspartikel (Staub, Funken)
- [ ] **FR-279** Verzerrung bei schwarzen Loechern
- [x] **FR-280** Combo-Feuerwerk bei hohen Ketten

## Shader & Rendering

- [ ] **FR-281** Weltraum-Hintergrund-Shader (Nebel/Sterne)
- [ ] **FR-282** Optionaler CRT-/Retro-Filter
- [ ] **FR-283** Wasser-Brechungs-Shader
- [ ] **FR-284** Hitzeflimmer-Shader fuer Lava
- [ ] **FR-285** Outline-Shader fuer wichtige Objekte
- [ ] **FR-286** Vignette-Post-Processing
- [ ] **FR-287** Bloom fuer Glueh-Effekte
- [ ] **FR-288** Chromatische Aberration bei hohem Tempo
- [ ] **FR-289** Dunkelheits-/Sichtkegel-Shader
- [ ] **FR-290** Tag-/Nacht-Verlauf-Shader
- [ ] **FR-291** Aufloesungsskalierung fuer schwache Geraete
- [ ] **FR-292** Farb-Grading pro Welt
- [ ] **FR-293** Furz-Wolken-Verzerrungs-Shader
- [ ] **FR-294** Motion Blur (Geschwindigkeits-Unschaerfe)
- [ ] **FR-295** Sterne-Parallax-Shader
- [ ] **FR-296** 2D-Beleuchtung und Schatten
- [ ] **FR-297** Schild-Energie-Shader
- [ ] **FR-298** Dissolve-Effekt bei Tod
- [ ] **FR-299** Pixel-Perfect-Render-Option
- [ ] **FR-300** Performance-Schalter fuer Shader-Qualitaet

## Fortschritt & Meta-Progression

- [x] **FR-301** Globaler XP-/Spieler-Levelaufstieg
- [x] **FR-302** Sterne-Gesamtzahl als Freischalt-Waehrung
- [ ] **FR-303** Welt-Freischaltung ueber Sterne-Schwellen
- [ ] **FR-304** Skill-Baum fuer Maennchen-Faehigkeiten
- [ ] **FR-305** Permanente Upgrades (z.B. Furz-Staerke kaufen)
- [ ] **FR-306** Prestige-/New-Game+-Modus
- [ ] **FR-307** Sammel-Album-Fortschritt
- [ ] **FR-308** Meilenstein-Belohnungen
- [ ] **FR-309** Taegliche Login-Belohnungen
- [ ] **FR-310** Woechentliche Ziele
- [ ] **FR-311** Battle-Pass-/Saison-Fortschritt
- [ ] **FR-312** Freischalt-Roadmap-Anzeige
- [ ] **FR-313** Muenz-Sparziele (Sparschwein)
- [ ] **FR-314** Geraeteuebergreifende Fortschritts-Synchronisierung
- [ ] **FR-315** Komplettierungs-Belohnung bei 100 Prozent
- [ ] **FR-316** Hard-Mode-Sterne (Schwierigkeits-Sterne)
- [ ] **FR-317** Sammlung der Bestzeiten
- [ ] **FR-318** Statistik-getriebene Abzeichen
- [ ] **FR-319** Stufenweise Freischaltung neuer Hindernisse
- [ ] **FR-320** Belohnungs-Vorschau fuer das naechste Ziel

## Erfolge & Herausforderungen

- [ ] **FR-321** Achievement-System (Google Play Games)
- [ ] **FR-322** Erfolge fuer Anzahl der Fuerze
- [ ] **FR-323** Muenz-Sammel-Erfolge
- [ ] **FR-324** Pazifist-Lauf (keine Muenzen sammeln)
- [ ] **FR-325** Perfekt-Lauf (kein Schaden, alle Sterne)
- [ ] **FR-326** Speed-Erfolge (unter Zeit X)
- [ ] **FR-327** Sparsam-Furz-Erfolge (wenige Stoesse)
- [ ] **FR-328** Erfolg: alle Sterne sammeln
- [ ] **FR-329** Taegliche Herausforderungen
- [ ] **FR-330** Woechentliche Herausforderungen
- [ ] **FR-331** Herausforderungs-Modifikatoren (Mutatoren)
- [ ] **FR-332** Erfolgs-Fortschrittsanzeige
- [ ] **FR-333** Versteckte Erfolge
- [ ] **FR-334** Erfolgs-Belohnungen (Skins/Muenzen)
- [ ] **FR-335** Streak-Erfolge (Tage in Folge)
- [ ] **FR-336** Combo-Erfolge
- [ ] **FR-337** Welt-spezifische Erfolge
- [ ] **FR-338** Erfolgs-Benachrichtigungs-Pop-ups
- [ ] **FR-339** Sortierung/Filter fuer Erfolge
- [ ] **FR-340** Plattformuebergreifende Erfolge

## Spielmodi

- [ ] **FR-341** Zeitrennen-Modus (Time Attack)
- [ ] **FR-342** Prozeduraler Endlos-Modus
- [ ] **FR-343** Ueberlebens-Modus
- [ ] **FR-344** Hardcore-Modus (eine Furz-Ladung)
- [ ] **FR-345** Zen-/Entspannungsmodus ohne Tod
- [ ] **FR-346** Muenz-Jagd-Modus
- [ ] **FR-347** Boss-Rush-Modus
- [ ] **FR-348** Spiegel-Modus (Level gespiegelt)
- [ ] **FR-349** Modus mit zufaelligen Mutatoren
- [ ] **FR-350** Taeglicher Lauf mit gleichem Seed fuer alle
- [ ] **FR-351** Co-op-Modus (zwei Maennchen)
- [ ] **FR-352** Versus-Modus (Split-Screen)
- [ ] **FR-353** Geist-Rennen gegen die Bestzeit
- [ ] **FR-354** Begrenzter Kein-Treibstoff-Modus
- [ ] **FR-355** Praezisions-Modus (winzige Luecken)
- [ ] **FR-356** Sammel-Marathon (alle Level am Stueck)
- [ ] **FR-357** Dunkel-Modus mit begrenzter Sicht
- [ ] **FR-358** Umgekehrte-Schwerkraft-Modus
- [ ] **FR-359** Chaos-Modus (alles schneller)
- [ ] **FR-360** Uebungsmodus mit freiem Neustart

## Events & Live-Ops

- [ ] **FR-361** Saisonale Events (Halloween, Weihnachten)
- [ ] **FR-362** Zeitlich begrenzte Level
- [ ] **FR-363** Event-Waehrung und Event-Shop
- [ ] **FR-364** Community-Ziele mit globalem Fortschritt
- [ ] **FR-365** Wochenend-Boni (doppelte Muenzen)
- [ ] **FR-366** Event-Bestenlisten
- [ ] **FR-367** Countdown-Timer fuer Events
- [ ] **FR-368** Event-Banner im Hauptmenue
- [ ] **FR-369** Gluecksrad-Event
- [ ] **FR-370** Sammel-Events (sammle X)
- [ ] **FR-371** Login-Kalender-Event
- [ ] **FR-372** Themen-Events pro Saison
- [ ] **FR-373** Remote-Config fuer Live-Konfiguration
- [ ] **FR-374** Push-Benachrichtigungen fuer Events
- [ ] **FR-375** Event-Belohnungs-Stufen
- [ ] **FR-376** Flash-Sales im Shop
- [ ] **FR-377** Doppelte-Sterne-Wochenende
- [ ] **FR-378** Event-Tutorial/Erklaerung
- [ ] **FR-379** Event-Historie/Archiv
- [ ] **FR-380** A/B-getestete Event-Varianten

## Soziales & Bestenlisten

- [ ] **FR-381** Globale Bestenlisten (Punkte/Zeit)
- [ ] **FR-382** Freundes-Bestenlisten
- [ ] **FR-383** Woechentliche Ranglisten-Resets
- [ ] **FR-384** Geist-Daten von Freunden teilen
- [ ] **FR-385** Level-Teilen ueber Link
- [ ] **FR-386** Screenshot-Teilen-Funktion
- [ ] **FR-387** Replay-Teilen
- [ ] **FR-388** Social-Media-Integration
- [ ] **FR-389** Einladungs-/Empfehlungssystem
- [ ] **FR-390** Gilden/Clans
- [ ] **FR-391** Clan-Wettbewerbe
- [ ] **FR-392** Herausforderung an Freund senden
- [ ] **FR-393** Erfolgs-Teilen
- [ ] **FR-394** Moderierter In-Game-Chat
- [ ] **FR-395** Profil-Seiten
- [ ] **FR-396** Liga-/Divisions-System
- [ ] **FR-397** Saison-Belohnungen nach Rang
- [ ] **FR-398** Anti-Cheat fuer Bestenlisten
- [ ] **FR-399** Regionale Bestenlisten
- [ ] **FR-400** Bestenlisten-UI mit Filtern

## Speichern & Cloud

- [ ] **FR-401** Lokales Speichersystem haerten
- [ ] **FR-402** Cloud-Speicher (Google Play Games Saves)
- [ ] **FR-403** Mehrere Speicherstaende/Profile
- [ ] **FR-404** Auto-Speichern nach jedem Level
- [ ] **FR-405** Konfliktaufloesung bei Speicherstaenden
- [ ] **FR-406** Speicher-Backup/Export
- [ ] **FR-407** Speicher-Import
- [ ] **FR-408** Daten-Migration zwischen Versionen
- [ ] **FR-409** Verschluesselte Speicherdaten
- [ ] **FR-410** Speicher-Reset-Option
- [ ] **FR-411** Fortschritt-Wiederherstellung
- [ ] **FR-412** Offline-Fortschritt-Synchronisierung
- [ ] **FR-413** Speicher-Integritaetspruefung
- [ ] **FR-414** Einstellungen separat speichern
- [ ] **FR-415** Geraeteuebergreifende Synchronisierung
- [ ] **FR-416** Speicher-Versionierung
- [ ] **FR-417** Wiederherstellung bei Korruption
- [ ] **FR-418** UI zur Speicher-Slot-Verwaltung
- [ ] **FR-419** Anzeige des Cloud-Sync-Status
- [ ] **FR-420** DSGVO-konformes Daten-Loeschen

## Einstellungen & Barrierefreiheit

- [ ] **FR-421** Farbenblind-Modi
- [ ] **FR-422** Hoher-Kontrast-Modus
- [ ] **FR-423** Reduzierte-Bewegung-Option (weniger Screen-Shake)
- [ ] **FR-424** Einstellbare Schriftgroesse
- [ ] **FR-425** Untertitel fuer Soundeffekte
- [ ] **FR-426** Einhand-Modus
- [ ] **FR-427** Auto-Furz-/Assist-Modus
- [ ] **FR-428** Haptik ein/aus
- [ ] **FR-429** Bildschirm-Helligkeit im Spiel
- [ ] **FR-430** Einstellbare Steuerungs-Empfindlichkeit
- [ ] **FR-431** Umschaltbare FPS-Anzeige
- [ ] **FR-432** Bildraten-Begrenzung zum Akkusparen
- [ ] **FR-433** Daltonismus-Palettenvorschau
- [ ] **FR-434** Bildschirmleser-Hinweise (TalkBack)
- [ ] **FR-435** Tipp-Bestaetigungen fuer Aktionen
- [ ] **FR-436** Pause bei Fokusverlust
- [ ] **FR-437** Konfigurierbare Schwierigkeits-Assists
- [ ] **FR-438** Lautstaerke-Voreinstellungen
- [ ] **FR-439** Sprachwahl
- [ ] **FR-440** Zuruecksetzen-auf-Standard-Button

## Lokalisierung & i18n

- [ ] **FR-441** Lokalisierungs-System (CSV/PO)
- [ ] **FR-442** Englische Uebersetzung
- [ ] **FR-443** Deutsche Uebersetzung (Standard) pflegen
- [ ] **FR-444** Spanische Uebersetzung
- [ ] **FR-445** Franzoesische Uebersetzung
- [ ] **FR-446** Portugiesische (BR) Uebersetzung
- [ ] **FR-447** Italienische Uebersetzung
- [ ] **FR-448** Tuerkische Uebersetzung
- [ ] **FR-449** Russische Uebersetzung
- [ ] **FR-450** Japanische Uebersetzung
- [ ] **FR-451** Koreanische Uebersetzung
- [ ] **FR-452** Chinesische (vereinfacht) Uebersetzung
- [ ] **FR-453** RTL-Unterstuetzung (Arabisch)
- [ ] **FR-454** Lokalisierte Zahlen-/Zeitformate
- [ ] **FR-455** Dynamischer Sprachwechsel ohne Neustart
- [ ] **FR-456** Schriftarten mit voller Glyphen-Abdeckung
- [ ] **FR-457** Lokalisierte Store-Texte
- [ ] **FR-458** Pluralisierungs-Regeln
- [ ] **FR-459** Uebersetzungs-Fallback-Logik
- [ ] **FR-460** QA-Werkzeug fuer fehlende Uebersetzungs-Keys

## Performance & Technik

- [ ] **FR-461** Objekt-Pooling fuer Partikel/Hindernisse
- [ ] **FR-462** Texturen-Atlas/Sprite-Sheets
- [ ] **FR-463** Level-Streaming fuer grosse Level
- [ ] **FR-464** Bildraten-Profiling-Overlay
- [ ] **FR-465** Speicher-Leck-Tests
- [ ] **FR-466** Reduzierte Partikel auf schwachen Geraeten
- [ ] **FR-467** Automatische Qualitaetserkennung
- [ ] **FR-468** Hintergrund-Pausierung/Akku-Optimierung
- [ ] **FR-469** Ladezeiten-Optimierung
- [ ] **FR-470** Asset-Vorladen pro Welt
- [ ] **FR-471** Tuning des Physik-Schritts
- [ ] **FR-472** Garbage-Collection-Spitzen vermeiden
- [ ] **FR-473** Shader-Vorkompilierung
- [ ] **FR-474** APK-/AAB-Groessen-Optimierung
- [ ] **FR-475** Stresstest-Szene
- [ ] **FR-476** Crash-Reporting-Integration
- [ ] **FR-477** ANR-Vermeidung (Main-Thread nicht blockieren)
- [ ] **FR-478** Frame-Pacing/VSync-Handhabung
- [ ] **FR-479** Geraete-Kompatibilitaetsmatrix
- [ ] **FR-480** Automatisierte Performance-Benchmarks

## Android-Plattform & Veroeffentlichung

- [ ] **FR-481** Adaptive Launcher-Icons
- [ ] **FR-482** App-Splash-Screen (Android 12+)
- [ ] **FR-483** Google Play Billing fuer kosmetische Kaeufe
- [ ] **FR-484** Optionale belohnte Werbeanzeigen
- [ ] **FR-485** Sparsame Interstitial-Werbung
- [ ] **FR-486** Google Play Games Services Login
- [ ] **FR-487** In-App-Bewertungsaufforderung
- [ ] **FR-488** Deep-Links zu Leveln
- [ ] **FR-489** Build-Pipeline fuer App-Bundle (AAB)
- [ ] **FR-490** ProGuard-/R8-Konfiguration
- [ ] **FR-491** Datenschutzerklaerung und Einwilligung
- [ ] **FR-492** Altersfreigabe/Content-Rating
- [ ] **FR-493** Store-Listing-Assets (Screenshots, Video)
- [ ] **FR-494** Beta-/Testkanal-Einrichtung
- [ ] **FR-495** Versionierungs-/Release-Notes-Prozess
- [ ] **FR-496** Tablet-optimierte Layouts (grosse Bildschirme)
- [ ] **FR-497** Foldable-Unterstuetzung
- [ ] **FR-498** Edge-to-Edge-/Notch-Handhabung
- [ ] **FR-499** Push-Benachrichtigungs-Setup (FCM)
- [ ] **FR-500** CI/CD fuer automatische Builds

---
*Gesamt: 500 Features.*
