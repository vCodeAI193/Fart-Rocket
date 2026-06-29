# 🚀 Fart Rocket — Vision & 1000-Feature Roadmap

## Überblick

**Fart Rocket** ist ein schnelllebiges, physikbasiertes Arcade-Platformer mit einzigartiger "Furz"-Propulsionsmechanik. Das Spiel orientiert sich an klassischen Impulse-basierten Spielen (wie *Angry Birds*, *Elastic Frankie*), aber mit kontinuierlicher Echtzeit-Physik, reichhaltigen Umgebungseffekten und tiefem Meta-Progression-System.

Die Vision ist, Fart Rocket zu einem vielseitig spielbaren, endlos erweiterbaren Mobilspiel mit starker Indie-Identität zu machen — ein Spiel, das gleichermaßen anspruchsvoll für Hardcore-Spieler wie zugänglich für Casual-Nutzer ist.

---

## Core-Design-Säulen

### 1. **Physik als Kern-Experience**
- Deterministische, replay-fähige RigidBody2D-Physik
- Kombination aus präzisem Aiming und kontroliertem Chaos
- Umweltinteraktion (Wind, Magnetfelder, Schwerkraft, Auftrieb) als Kern-Gameplay
- Feine Steuerung durch Auflade-Mechanik (Timing + Angle = Erfolg)

### 2. **Prozedurales Design ohne Assets**
- Alle Grafiken durch GDScript generiert (Line2D, Polygon2D, ColorRect, CPUParticles2D)
- Konsistente visuell-minimalistisch-ästhetik (Stick-Figur, geometrische Formen)
- Schnelle Iteration und Anpassung ohne Asset-Pipeline
- Deterministisches Seeding für Hintergründe und Partikel

### 3. **Signalbasierte Architektur**
- Lose Kopplung zwischen Spielsystemen (Player → GameManager → HUD, etc.)
- Sichere Skalierung auf 50+ verschiedene Objekt-Typen
- Einfache Test- und Mock-Struktur

### 4. **Progressive Komplexität**
- Level 1-3 (MVP): Grundlagen-Mechaniken, einfache Physik, Einführungs-Pacing
- World 2-6 (Post-Launch): Spezialisierte Zonen, Gegner, bosses
- Advanced Features: Editor, Multiplayer, Live-Ops, Procedural Generation

### 5. **Android als First-Class-Citizen**
- Touch-Input mit Vibration-Feedback
- Responsive 1920×1200 Landscape-UI
- Google Play Services Integration (Bestenlisten, Achievements, Cloud Saves)
- Batterie-Optimierung und niedrig-Geräte-Support

---

## Roadmap-Struktur

Das gesamte Backlog ist in **25 Themenkategorien** organisiert à **20 Features pro Kategorie** = **500 Features**.

Diese Vision erweitert auf **1000 Features**, indem jede Kategorie auf **40 Features** pro Kategorie verdoppelt wird:

1. [Antrieb & Furz-Mechanik](#antrieb-furz-mechanik) — FR-001–FR-040 (40)
2. [Physik & Bewegung](#physik-bewegung) — FR-021–FR-080 (40, integriert: FR-021–FR-040 + FR-041–FR-080 neu)
3. [Steuerung & Eingabe](#steuerung-eingabe) — FR-041–FR-100 (40, integriert)
4. [Hindernisse & Gefahren](#hindernisse-gefahren) — FR-061–FR-120 (40, integriert)
5. [Sammelobjekte & Power-ups](#sammelobjekte-power-ups) — FR-081–FR-140 (40, integriert)
6. [Gegner & KI](#gegner-ki) — FR-101–FR-160 (40, integriert)
7. [Level-Design & Inhalte](#level-design-inhalte) — FR-121–FR-180 (40, integriert)
8. [Level-Editor & UGC](#level-editor-ugc) — FR-141–FR-200 (40, integriert)
9. [Maennchen-Anpassung & Skins](#maennchen-anpassung-skins) — FR-161–FR-220 (40, integriert)
10. [Kamera & Sicht](#kamera-sicht) — FR-181–FR-240 (40, integriert)
11. [HUD & In-Game-UI](#hud-in-game-ui) — FR-201–FR-260 (40, integriert)
12. [Menues & Navigation](#menues-navigation) — FR-221–FR-280 (40, integriert)
13. [Audio & Musik](#audio-musik) — FR-241–FR-300 (40, integriert)
14. [Visuelle Effekte & Juice](#visuelle-effekte-juice) — FR-261–FR-320 (40, integriert)
15. [Shader & Rendering](#shader-rendering) — FR-281–FR-340 (40, integriert)
16. [Fortschritt & Meta-Progression](#fortschritt-meta-progression) — FR-301–FR-360 (40, integriert)
17. [Erfolge & Herausforderungen](#erfolge-herausforderungen) — FR-321–FR-380 (40, integriert)
18. [Spielmodi](#spielmodi) — FR-341–FR-400 (40, integriert)
19. [Events & Live-Ops](#events-live-ops) — FR-361–FR-420 (40, integriert)
20. [Soziales & Bestenlisten](#soziales-bestenlisten) — FR-381–FR-440 (40, integriert)
21. [Speichern & Cloud](#speichern-cloud) — FR-401–FR-460 (40, integriert)
22. [Einstellungen & Barrierefreiheit](#einstellungen-barrierefreiheit) — FR-421–FR-480 (40, integriert)
23. [Lokalisierung & i18n](#lokalisierung-i18n) — FR-441–FR-500 (40, integriert)
24. [Performance & Technik](#performance-technik) — FR-461–FR-520 (40, integriert)
25. [Android-Plattform & Veroeffentlichung](#android-plattform-veroeffentlichung) — FR-481–FR-540 (40, integriert)

*Gesamt: 1000 Features (500 existent + 500 neue erweiterte Features)*

---

## Implementierungs-Phasen

### Phase 1: MVP Core (FR-001–FR-100, ~67 existente + neue Essentials)
- ✅ Furz-Mechanik und Combo-System
- ✅ 5 fart-Typen
- ✅ Physik-Grundlagen (Schwerkraft, Drag, Terminal Velocity)
- ✅ Touch-Input mit Trajectory Preview
- ✅ 3 Einführungs-Level
- ✅ Münzen, Power-ups (Shield, Slow-Mo, Double Coins)
- ✅ HUD (Charges, Coins, Timer, Combo)
- ✅ Checkpoints
- ⏳ Player XP und Level-System (teilweise)
- ⏳ Pause/Resume

### Phase 2: Core+ Features (FR-101–FR-300)
- [ ] Gegner (Patroller, Verfolger, Schütze)
- [ ] Welt 2-6 mit Themen
- [ ] Erweiterter Obstacle-Set
- [ ] In-Game-Level-Editor (Grundlagen)
- [ ] Musik & Ambient Sounds
- [ ] Skins & Anpassung
- [ ] Erweiterte Shader (Bloom, Blur, Distortion)
- [ ] Achievements (Google Play Games)
- [ ] Bestenlisten
- [ ] Shop & Währungssystem

### Phase 3: Advanced & Meta (FR-301–FR-700)
- [ ] Spielmodi (Time Attack, Survival, Endless, Procedural)
- [ ] Vollständiger Level-Editor mit UGC
- [ ] Klan-System & Sozial-Features
- [ ] Live-Ops (Saisonale Events, Daily Challenges, Battle Pass)
- [ ] Advanced Progression (Skill Tree, Prestige)
- [ ] Cloud Saves & Cross-Device Sync
- [ ] Procedural Level Generation
- [ ] Multiplayer (Local Co-op, Leaderboard Races, Versus)

### Phase 4: Expansion & Polish (FR-701–FR-1000)
- [ ] Community Features (Screenshot Sharing, Replay Upload)
- [ ] A/B-Testing & Analytics Integration
- [ ] Barrierefreie Features (Color-blind Modes, Accessibility)
- [ ] Vollständige i18n (10+ Sprachen)
- [ ] Console Port Groundwork
- [ ] Procedural Content System
- [ ] AI-Assisted Balancing
- [ ] Performance Optimization Suites

---

## Detaillierte Feature-Kategorien (500 neu)

Nachfolgend wird jede der 25 Kategorien auf 40 Features erweitert. Die ersten 20 entsprechen den Backlog-Einträgen; die neuen 20 (FR-021–FR-040, FR-061–FR-080, usw.) erweitern die Mechaniken systematisch.

### Antrieb & Furz-Mechanik (FR-001–FR-040)

**Existente Features (FR-001–FR-020):**
- [x] FR-001 Furz-Aufladung über Zeit
- [x] FR-002 Mehrere Furz-Typen
- [x] FR-003 Furz-Combo-System
- [ ] FR-004 Treibstoff-Modus mit Balken
- [x] FR-005 Aufgeladener Furz
- [x] FR-006 Seitlicher Rückstoß
- [ ] FR-007 Dauerstrahl-Furz
- [x] FR-008 Cooldown/Kühlzeit
- [ ] FR-009 Winkel-Präzisions-Bonus
- [x] FR-010 Furz-Schild
- [x] FR-011 Treibstoff-Pickups
- [ ] FR-012 Überhitzung
- [x] FR-013 Wind-Interaktion
- [ ] FR-014 Unterwasser-Furz
- [ ] FR-015 Schwerelosigkeits-Zonen
- [ ] FR-016 Furz-Sound variiert
- [ ] FR-017 Verweilende Geruchswolke
- [ ] FR-018 Sticky-Furz
- [x] FR-019 Furz-Boost-Ringe
- [ ] FR-020 Anpassbare Furz-Schubkurven

**Neue Erweiterte Features (FR-021–FR-040):**
- [ ] FR-021 Furz-Menge-Anzeige im HUD
- [ ] FR-022 Furz-Typ-Vorschau beim Laden
- [ ] FR-023 Fury-Meter für aggressive Folgefürze
- [ ] FR-024 Seitenfurz mit unterschiedlichen Stärken
- [ ] FR-025 Diagonal-Furz-Freischaltung
- [ ] FR-026 Spin-Furz (360° Rotation vor dem Start)
- [ ] FR-027 Bounce-Furz (Multi-Bounce-Propulsion)
- [ ] FR-028 Ricochet-Furz (3x Reflexion bevor Kraft angewendet)
- [ ] FR-029 Ultra-Furz (finaler Laden-Level, maximal Schub)
- [ ] FR-030 Furz-Kombo-Kette-Visualisierung
- [ ] FR-031 Micro-Furz (tiny Nanoimpulse für Feinjustierung)
- [ ] FR-032 Furz-Richtungs-Puffer (Eingabe-Akzeptanz)
- [ ] FR-033 Furz-Vorschau-Partikel beim Zielen
- [ ] FR-034 Velocity-überschreitet-Limit-Effekt
- [ ] FR-035 Furz-Sound-Verband (mehrere Fürze gleichzeitig)
- [ ] FR-036 Furz-Rekord-Tracker (längste Flugdauer, schnellstes Tempo)
- [ ] FR-037 Schwung-Furz (Pendelstart für höhere Reichweite)
- [ ] FR-038 Furz-Kosten-Variabilität (Difficulty-based)
- [ ] FR-039 Furz-Schwellwert (Minimum-Kraftanforderung)
- [ ] FR-040 Furz-Feedback-Vibrationen (Intensität skaliert)

### Physik & Bewegung (FR-041–FR-080)

**Existente Features (FR-021–FR-040 aus Backlog):**
- [x] FR-041 Variable Schwerkraft
- [x] FR-042 Umkehrbare Schwerkraft
- [ ] FR-043 Auftrieb-/Wasserzonen
- [x] FR-044 Bewegliche Plattformen
- [x] FR-045 Förderbänder
- [x] FR-046 Sprungfedern
- [x] FR-047 Magnetfelder
- [x] FR-048 Schleim-/Klebezonen
- [ ] FR-049 Eis-/Glattzonen
- [x] FR-050 Luftströmungen
- [ ] FR-051 Schwarze Löcher
- [x] FR-052 Terminal-Geschwindigkeit
- [x] FR-053 Drall-Dämpfung
- [ ] FR-054 Bouncy-Walls
- [ ] FR-055 Zerstörbare Wände
- [ ] FR-056 Bullet-Time-Zonen
- [ ] FR-057 Pendel-/Seilschwung
- [ ] FR-058 Massen-Pickups
- [ ] FR-059 Realistische Luftreibung
- [ ] FR-060 Ragdoll-Physik

**Neue Erweiterte Features (FR-061–FR-080):**
- [ ] FR-061 Variable Luftdichte-Zonen
- [ ] FR-062 Rotations-Dämpfung pro Achse
- [ ] FR-063 Spring-Mesh-Physik (elastische Deformation)
- [ ] FR-064 Dynamische Schwerkraft-Änderungen mitten im Level
- [ ] FR-065 Geschwindigkeit-basierte Reibung
- [ ] FR-066 Beschleunigungs-Limits pro Richtung
- [ ] FR-067 Zentrifugal-Effekt in Magnetfeldern
- [ ] FR-068 Coriolis-Effekt in rotierenden Zonen
- [ ] FR-069 Gezeiten-Zonen (pulsierendes Gravity-Feld)
- [ ] FR-070 Elektromagnetische Abstoßung (Gegenpole)
- [ ] FR-071 Fluessigkeits-Drag-Simulation
- [ ] FR-072 Rotation-abhängige Flugbahn
- [ ] FR-073 Wind-Turbulenz (Gusts, Wirbel)
- [ ] FR-074 Schwerkraft-Gradient (kontinuierliche Änderung)
- [ ] FR-075 Gyro-Stabilisierter Spin
- [ ] FR-076 Impulse-Absorption (Material-basiert)
- [ ] FR-077 Pneumatische Kompression (Stoßdämpfer)
- [ ] FR-078 Torsion-Zones (Rotations-Verstärker)
- [ ] FR-079 Friktions-Variabilität (Sand, Eis, Lava)
- [ ] FR-080 Anti-Gravity-Bubble-Zones

### Steuerung & Eingabe (FR-081–FR-120)

**Existente Features (FR-041–FR-060):**
- [ ] FR-081 Zwei-Finger-Zoom
- [ ] FR-082 Umschaltbare Steuerschemata
- [ ] FR-083 Links-/Rechtshänder-Modus
- [ ] FR-084 Einstellbare Touch-Empfindlichkeit
- [x] FR-085 Haptisches Feedback
- [ ] FR-086 Gamepad-Unterstützung
- [ ] FR-087 Tastatur-/Maus-Unterstützung
- [x] FR-088 Flugbahn-Vorschau
- [ ] FR-089 Anpassbare Pfeil-Visualisierung
- [x] FR-090 Doppel-Tipp-Neustart
- [ ] FR-091 Wisch-Geste zum Pausieren
- [ ] FR-092 Zielen mit Zeitlupe
- [ ] FR-093 Auto-Aim-Modus
- [ ] FR-094 Safe-Area-Konfiguration
- [ ] FR-095 Multitouch-Robustheit
- [ ] FR-096 Eingabe-Pufferung
- [ ] FR-097 Tipp-vs-Zieh-Erkennung
- [ ] FR-098 Bildschirm-Sperre
- [ ] FR-099 Steuerungs-Kalibrierung
- [ ] FR-100 Geste zum Kamera-Reset

**Neue Erweiterte Features (FR-101–FR-120):**
- [ ] FR-101 Gyro-Steuerung (Neigungssensor)
- [ ] FR-102 Beschleunigungsmesser-Aiming
- [ ] FR-103 Eye-Tracking-Unterstützung (optional)
- [ ] FR-104 Voice-Command-Aiming
- [ ] FR-105 Adaptive Trigger-Feedback (mit unterstützten Pads)
- [ ] FR-106 Dead-Zone-Visualisierung
- [ ] FR-107 Eingabe-Verzögerung-Kalibrierung
- [ ] FR-108 Custom-Gesten definieren
- [ ] FR-109 Swipe-Sperre bei Spielmodus-Wechsel
- [ ] FR-110 Kontext-Sensitive Touch-Zonen
- [ ] FR-111 Longpress-Aktionen
- [ ] FR-112 Multi-Tap-Sequenzen
- [ ] FR-113 Assistenz-Modi (Auto-Stab, Auto-Aim, Auto-Collect)
- [ ] FR-114 Tremor-Kompensation (zittrig?)
- [ ] FR-115 Druckempfindlichkeit (für Stylus)
- [ ] FR-116 Eingabe-Latenz-Monitor
- [ ] FR-117 Tastatur-Overlay (für Emergency-Inputs)
- [ ] FR-118 Controller-Rumble-Intensität
- [ ] FR-119 Swipe-Sensitivity Heat-Map
- [ ] FR-120 Input-Rekorder für Replay

### Hindernisse & Gefahren (FR-121–FR-160)

**Existente Features (FR-061–FR-080):**
- [ ] FR-121 Weitere Sägeblatt-Größen
- [ ] FR-122 Bewegliche Stachel-Walzen
- [ ] FR-123 Pendelnde Stachelkugeln
- [ ] FR-124 Ein-/ausfahrende Stacheln
- [ ] FR-125 Laserstrahlen mit Intervall
- [ ] FR-126 Flammenwerfer-Düsen
- [ ] FR-127 Fallende Felsbrocken
- [ ] FR-128 Zerbröckelnde Plattformen
- [ ] FR-129 Elektro-Zäune
- [ ] FR-130 Rotierende Hindernis-Räder
- [ ] FR-131 Wandernde Laserwände
- [ ] FR-132 Giftgaswolken
- [ ] FR-133 Schließende Türen/Tore
- [ ] FR-134 Kreissägen auf Schienen
- [ ] FR-135 Komplexe Hindernis-Maschinen
- [ ] FR-136 Wasserfälle
- [ ] FR-137 Klebrige Spinnweben
- [ ] FR-138 Tickende Minen
- [ ] FR-139 Zufällig generierte Layouts
- [ ] FR-140 Telegrafierte Angriffe

**Neue Erweiterte Features (FR-141–FR-160):**
- [ ] FR-141 Automatische Sägeblatt-Swarms
- [ ] FR-142 Magnetische Hindernisse (abstoßend)
- [ ] FR-143 Vibrierende Zersplitterungs-Blöcke
- [ ] FR-144 Phasing-Hindernisse (blinken ein/aus)
- [ ] FR-145 Zeitreise-Plattformen (zwei Zeitstände)
- [ ] FR-146 Holographische Fallen (falsche Kollisionen)
- [ ] FR-147 Reißende Strömungen (Sog-Zonen)
- [ ] FR-148 Schallwelle-Pulse
- [ ] FR-149 Antimaterie-Zonen (Eliminierung)
- [ ] FR-150 Zeitdilatations-Hindernisse
- [ ] FR-151 Thermische Flutungen
- [ ] FR-152 Radioaktive Verseuchung-Zonen
- [ ] FR-153 Vakuum-Zonen (keine Luft)
- [ ] FR-154 Hyperraumportale
- [ ] FR-155 Kausalitäts-Paradoxe (Schleife zurück)
- [ ] FR-156 Fraktale Hindernisse (unendliche Verschachtelung)
- [ ] FR-157 Quantenverschränkung-Hazards (zwei gekoppelte Zonen)
- [ ] FR-158 Infinitesimal-Sägen (unmöglich dünn)
- [ ] FR-159 Dunkle-Materie-Zones
- [ ] FR-160 Ereignis-Horizont-Hazards

### Sammelobjekte & Power-ups (FR-161–FR-200)

**Existente Features (FR-081–FR-100):**
- [x] FR-161 Verschiedene Münz-Werte
- [x] FR-162 Edelsteine
- [x] FR-163 Magnet-Power-up
- [x] FR-164 Schild-Power-up
- [x] FR-165 Verlangsamungs-Power-up
- [x] FR-166 Doppel-Münzen-Power-up
- [x] FR-167 Extra-Furz-Ladung
- [ ] FR-168 Versteckte Sterne
- [ ] FR-169 Sammelkarten-/Sticker
- [ ] FR-170 Truhen mit Zufallsbelohnung
- [ ] FR-171 Schlüssel und Schlösser
- [ ] FR-172 Buchstaben sammeln (F-A-R-T)
- [ ] FR-173 Tagesmuenze
- [ ] FR-174 Mystery-Box
- [ ] FR-175 Combo-Münzketten
- [ ] FR-176 Schwebende Münz-Pfade
- [ ] FR-177 Zerstörbare Münzblöcke
- [ ] FR-178 Negative Objekte (Stinkbomben)
- [ ] FR-179 Sammel-Fortschritt-Anzeige
- [ ] FR-180 Power-up-Inventar

**Neue Erweiterte Features (FR-181–FR-200):**
- [ ] FR-181 Kristall-Shards (baue große Kristalle)
- [ ] FR-182 Quantumcoins (verschränkte Münzen)
- [ ] FR-183 Erinnerungs-Münzen (nostalgische Momente)
- [ ] FR-184 Zeitkapseln (Level-History)
- [ ] FR-185 Emotionale Münzen (drücken Gefühle aus)
- [ ] FR-186 Träum-Münzen (Nacht-Level-exclusive)
- [ ] FR-187 Phantom-Münzen (Sichtbarkeit an Bedingungen gebunden)
- [ ] FR-188 Musikalische Münzen (Sound bei Sammlung)
- [ ] FR-189 Fractal-Münzen (Selbstähnlichkeit)
- [ ] FR-190 Chaotische Münzen (chaotische Bahnen)
- [ ] FR-191 Singuläre Münzen (unendlich wertvoll)
- [ ] FR-192 Paradoxe Münzen (unmögliche Physik)
- [ ] FR-193 Spiegelwelts-Münzen
- [ ] FR-194 Synchronisierungs-Münzen (müssen zusammen gesammelt)
- [ ] FR-195 Divergente Münzen (alternative Timeline)
- [ ] FR-196 Metamorphe Münzen (verwandeln sich)
- [ ] FR-197 Symbiont-Münzen (benötigen Partner)
- [ ] FR-198 Transfinite-Münzen (größer als unendlich)
- [ ] FR-199 Nomische-Münzen (erschaffen Regeln)
- [ ] FR-200 Götter-Münzen (omnipotent)

### Gegner & KI (FR-201–FR-240)

**Existente Features (FR-101–FR-120):**
- [ ] FR-201 Patrouillierende Flug-Gegner
- [ ] FR-202 Verfolger-Gegner
- [ ] FR-203 Schiessende Gegner
- [ ] FR-204 Stationäre Geschütztürme
- [ ] FR-205 Gegner, die Münzen klauen
- [ ] FR-206 Ausweichende Gegner
- [ ] FR-207 Springende Boden-Gegner
- [ ] FR-208 Schwarm-Gegner
- [ ] FR-209 Schild-Gegner
- [ ] FR-210 Teleportierende Gegner
- [ ] FR-211 Gegner mit telegrafierten Angriffen
- [ ] FR-212 Mini-Boss pro Welt
- [ ] FR-213 End-Boss mit mehreren Phasen
- [ ] FR-214 Gegner-Spawner
- [ ] FR-215 Gegner per Furz weggeblasen
- [ ] FR-216 Tarn-Gegner
- [ ] FR-217 KI-Schwierigkeitsskalierung
- [ ] FR-218 Gegner-Bestiarium
- [ ] FR-219 Boss-Schwachstellen
- [ ] FR-220 Gegner-Drop-Belohnungen

**Neue Erweiterte Features (FR-221–FR-240):**
- [ ] FR-221 Lernfähige Gegner (merken Spieler-Muster)
- [ ] FR-222 Kooperative Gegner-Teams
- [ ] FR-223 Psychische Gegner (beeinflussen Gedanken)
- [ ] FR-224 Viral-Gegner (infizieren andere)
- [ ] FR-225 Hive-Mind-Gegner-Schwarm
- [ ] FR-226 Gegner mit Verwandlungen
- [ ] FR-227 Gegner, die Portale öffnen
- [ ] FR-228 Klon-Gegner (reproduzieren sich)
- [ ] FR-229 Zeitschleifen-Gegner (deja vu)
- [ ] FR-230 Kausalitäts-Gegner (ändern Level-Physik)
- [ ] FR-231 Verrückte KI (unpredictable)
- [ ] FR-232 Psychische Gegner
- [ ] FR-233 Multidimensionale Gegner (mehrere Ebenen)
- [ ] FR-234 Gegner-Hierarchie (Befehls-Struktur)
- [ ] FR-235 Gegner mit Emotionen (Wut, Angst, Trauer)
- [ ] FR-236 Gegner mit Dialoge/Quips
- [ ] FR-237 Gegner, die über den Sieg lachen
- [ ] FR-238 Gegner mit Stamina/Ermüdung
- [ ] FR-239 Gegner mit Hunger (aggressiver wenn hungrig)
- [ ] FR-240 Gegner mit Lieblings-Level

### Level-Design & Inhalte (FR-241–FR-280)

**Existente Features (FR-121–FR-140):**
- [ ] FR-241 Welt 2: Höhlen-Thema
- [ ] FR-242 Welt 3: Unterwasser-Thema
- [ ] FR-243 Welt 4: Fabrik-/Industrie-Thema
- [ ] FR-244 Welt 5: Weltraum-Station
- [ ] FR-245 Welt 6: Vulkan-/Lava-Thema
- [ ] FR-246 30 zusätzliche Hauptlevel
- [ ] FR-247 Bonus- und Geheimlevel
- [ ] FR-248 Speedrun-Sektionen
- [ ] FR-249 Autoscroller-Level
- [ ] FR-250 Dunkelheits-Level
- [ ] FR-251 Rückwärtsschwerkraft-Level
- [ ] FR-252 Level mit beweglichem Wasserstand
- [ ] FR-253 Pflichtlevel: alle Münzen
- [ ] FR-254 Mehrere verzweigte Pfade
- [x] FR-255 Checkpoint-System
- [ ] FR-256 Versteckte Räume
- [ ] FR-257 Themen-spezifische Hindernisse
- [ ] FR-258 Level-Intro-Kamerafahrt
- [ ] FR-259 Schwierigkeitsgrade
- [ ] FR-260 Level-Vorschaubilder

**Neue Erweiterte Features (FR-261–FR-280):**
- [ ] FR-261 Welt 7: Märchen-Thema
- [ ] FR-262 Welt 8: Cyber/Neon-Thema
- [ ] FR-263 Welt 9: Bio-Thema (Organisches)
- [ ] FR-264 Welt 10: Quantum-Thema
- [ ] FR-265 Welt 11: Mythologie-Thema
- [ ] FR-266 Welt 12: Dystopia-Thema
- [ ] FR-267 Zeitreise-Level-Serie
- [ ] FR-268 Traum-Level (surrealistisch)
- [ ] FR-269 Nightmare-Level (Horror)
- [ ] FR-270 Musikal-Level (Rhythmus-basiert)
- [ ] FR-271 Poesie-Level (Narrative-basiert)
- [ ] FR-272 Meditations-Level (entspannend)
- [ ] FR-273 Extremschwer-Niveau
- [ ] FR-274 Ironman-Modus-Level
- [ ] FR-275 Asymmetrische Multiplayer-Level
- [ ] FR-276 Escape-Room-Level
- [ ] FR-277 Puzzle-Box-Level
- [ ] FR-278 Kinder-Level (einfacher, sicherer)
- [ ] FR-279 Erwachsenen-Level (Thematik)
- [ ] FR-280 Meditativ-Thema (Zen)

### Level-Editor & UGC (FR-281–FR-320)

**Existente Features (FR-141–FR-160):**
- [ ] FR-281 In-Game-Level-Editor
- [ ] FR-282 Hindernisse per Drag&Drop
- [ ] FR-283 Münzen und Power-ups
- [ ] FR-284 Editor-Raster
- [ ] FR-285 Test-Spielen aus Editor
- [ ] FR-286 Level speichern und laden
- [ ] FR-287 Level-Code zum Teilen
- [ ] FR-288 Online-Browser für Community
- [ ] FR-289 Bewertungssystem
- [ ] FR-290 Undo/Redo
- [ ] FR-291 Kopieren und Einfügen
- [ ] FR-292 Eigenschaften-Inspektor
- [ ] FR-293 Hintergrund-/Themenauswahl
- [ ] FR-294 Start- und Zielpunkt
- [ ] FR-295 Lösbarkeits-Validierung
- [ ] FR-296 Editor-Tutorial
- [ ] FR-297 Vorlagen-Bibliothek
- [ ] FR-298 Mehrebenen-/Layer-System
- [ ] FR-299 Pfad-Editor
- [ ] FR-300 Verwaltung eigener Level

**Neue Erweiterte Features (FR-301–FR-320):**
- [ ] FR-301 Scripting im Editor (GDScript-Lite)
- [ ] FR-302 Visuelle Node-Scripting (Visual Script)
- [ ] FR-303 Algorithmen-Generator (Fractals, L-Systems)
- [ ] FR-304 Symmetrie-Tools (Mirror, Rotate)
- [ ] FR-305 Batch-Editor für Massenbearbeitung
- [ ] FR-306 Versionskontrolle für Level
- [ ] FR-307 Kolaborativer Editor (mehrere Spieler)
- [ ] FR-308 Level-Preview-Video-Export
- [ ] FR-309 3D-zu-2D-Editor-Konvertierung
- [ ] FR-310 Physik-Simulator im Editor
- [ ] FR-311 Partikel-Editor
- [ ] FR-312 Musik-Editor Integration
- [ ] FR-313 Shader-Editor für Levels
- [ ] FR-314 AI-gestützte Level-Schwierigkeits-Analyse
- [ ] FR-315 Level-Klondiererei-System
- [ ] FR-316 Template-Mixer (kombiniere 2 Levels)
- [ ] FR-317 Chaos-Generator (zufällig robust Level)
- [ ] FR-318 Level-Rebalancer (passe Schwierigkeit auto an)
- [ ] FR-319 Automatische Sperr-Punkt-Vorschläge
- [ ] FR-320 Level-Sharing-Netzwerk-Integration

### Männchen-Anpassung & Skins (FR-321–FR-360)

**Existente Features (FR-161–FR-180):**
- [ ] FR-321 Verschiedene Helm-Designs
- [x] FR-322 Farbauswahl
- [ ] FR-323 Kostüme/Outfits
- [ ] FR-324 Furz-Wolken-Farben
- [ ] FR-325 Furz-Sound-Pakete
- [ ] FR-326 Hüte und Accessoires
- [ ] FR-327 Gesichtsausdrücke
- [x] FR-328 Trail-/Spur-Effekte
- [ ] FR-329 Über Münzen freischaltbar
- [ ] FR-330 Seltenheitsstufen
- [ ] FR-331 Skin-Vorschau
- [ ] FR-332 Saisonale Skins
- [ ] FR-333 Animierte Skins
- [ ] FR-334 Skin-des-Tages
- [ ] FR-335 Anpassbare Pfeil-Designs
- [ ] FR-336 Varianten Tod-Animation
- [ ] FR-337 Sieges-Pose/Emote
- [ ] FR-338 Skin-Sammlung
- [ ] FR-339 Mix&Match-Anpassung
- [ ] FR-340 Eigener Farb-Editor

**Neue Erweiterte Features (FR-341–FR-360):**
- [ ] FR-341 Skins aus andere Franchises (Crossover)
- [ ] FR-342 Lichtschwert-Effekte für Skins
- [ ] FR-343 Holographische Skins
- [ ] FR-344 Pixel-Art-Skins (8-bit Retro)
- [ ] FR-345 Hyper-Realistische Skins
- [ ] FR-346 Abstrakte/Geometrische Skins
- [ ] FR-347 Living-Skins (pulsieren, wachsen)
- [ ] FR-348 Flüssige Skins (morphing)
- [ ] FR-349 Gasförmige Skins (neblig)
- [ ] FR-350 Plasmaartige Skins
- [ ] FR-351 Kristalline Skins (transparent)
- [ ] FR-352 Metallische Skins (silber, gold)
- [ ] FR-353 Biologische Skins (organisch)
- [ ] FR-354 Spiegelung-Skins (reflektierend)
- [ ] FR-355 Neon-Skins
- [ ] FR-356 Kamouflage-Skins
- [ ] FR-357 Unsichtbare Skins (nur Schattierungen)
- [ ] FR-358 Temporale Skins (verschiedene Zeitalter)
- [ ] FR-359 Genderneutrale/Flüssige Skins
- [ ] FR-360 Community-erstellte Skins (Fan-Art)

### Kamera & Sicht (FR-361–FR-400)

**Existente Features (FR-181–FR-200):**
- [ ] FR-361 Dynamischer Zoom
- [x] FR-362 Kamera-Vorausschau
- [x] FR-363 Screen-Shake
- [x] FR-364 Sanftes Kamera-Folgen
- [x] FR-365 Kamera-Grenzen
- [ ] FR-366 Zielfokus-Kamera
- [ ] FR-367 Kino-Modus
- [x] FR-368 Parallax-Hintergrundebenen
- [ ] FR-369 Einstellbare Rüttel-Intensität
- [ ] FR-370 Mini-Karte/Übersichtskarte
- [ ] FR-371 Heranzoomen bei Zeitlupe
- [ ] FR-372 Kamera-Stoß
- [ ] FR-373 Rand-Indikatoren
- [ ] FR-374 Verfolgungs-Kamera für Boss
- [ ] FR-375 Foto-/Replay-Kameramodus
- [ ] FR-376 Kamera-Übergänge
- [ ] FR-377 Letterbox
- [ ] FR-378 Erschütterung bei Beinahe-Treffern
- [ ] FR-379 Fokus-Highlight
- [ ] FR-380 Kamera-Glättung

**Neue Erweiterte Features (FR-381–FR-400):**
- [ ] FR-381 360°-Kamerapfad (Orbitalansicht)
- [ ] FR-382 Isometrische Ansicht (umschalten)
- [ ] FR-383 Third-Person Schulter-Kamera
- [ ] FR-384 First-Person Sicht
- [ ] FR-385 Kamera-Spiegelung (Mirror World)
- [ ] FR-386 Kaleidoskop-Effekt
- [ ] FR-387 Doppelter Bildschirm (Split-Screen)
- [ ] FR-388 Picture-in-Picture-Miniaturansicht
- [ ] FR-389 Zeitverzögerte Kamera (History-basiert)
- [ ] FR-390 Vorahnung-Kamera (zeigt Zukunft)
- [ ] FR-391 Geister-Kamera (überlagerte Zeitlinen)
- [ ] FR-392 Tunnelblick-Effekt (Fokuszonenvignette)
- [ ] FR-393 Fischaugen-Objektiv-Verzeichnung
- [ ] FR-394 Tele-Objektiv-Kompression
- [ ] FR-395 Makro-Ansicht (eingebunden)
- [ ] FR-396 Drohnen-Ansicht (vom Himmel)
- [ ] FR-397 Untergrund-Ansicht (Durchschauen)
- [ ] FR-398 Thermische Kamera-Sicht
- [ ] FR-399 UV-Licht-Kamera-Sicht
- [ ] FR-400 Nachtvisionsgerät-Kamera

### HUD & In-Game-UI (FR-401–FR-440)

**Existente Features (FR-201–FR-220):**
- [x] FR-401 Pause-Button
- [x] FR-402 Animierte Münz-/Punkteanzeige
- [x] FR-403 Combo-Zähler-Anzeige
- [x] FR-404 Geschwindigkeitsanzeige
- [x] FR-405 Höhen-/Distanzanzeige
- [x] FR-406 Power-up-Status-Icons
- [ ] FR-407 Geist-Anzeige
- [ ] FR-408 Nachfüll-Animation
- [x] FR-409 Schaden-/Treffer-Vignette
- [ ] FR-410 Tutorial-Hinweise
- [ ] FR-411 Fortschrittsbalken
- [x] FR-412 Checkpoint-Benachrichtigung
- [ ] FR-413 Sammel-Pop-ups
- [x] FR-414 Aktuelle Sterne-Vorschau
- [ ] FR-415 Minimalistischer HUD-Modus
- [ ] FR-416 Einstellbare HUD-Skalierung
- [ ] FR-417 Linkshänder-HUD-Layout
- [ ] FR-418 Schnellzugriff für Power-ups
- [ ] FR-419 Live-Ranglistenposition
- [ ] FR-420 Ein-/ausblendbare HUD-Elemente

**Neue Erweiterte Features (FR-421–FR-440):**
- [ ] FR-421 Holographisches HUD (3D-Effekt)
- [ ] FR-422 Transparentes HUD (durchsichtig)
- [ ] FR-423 Dunkles HUD-Thema
- [ ] FR-424 Helles HUD-Thema
- [ ] FR-425 HUD-Bewegungswarnung
- [ ] FR-426 Augensaltat-HUD (Linien und Punkte)
- [ ] FR-427 Taktisches HUD (militärisch)
- [ ] FR-428 Cyberpunk-HUD (neon)
- [ ] FR-429 Steampunk-HUD (gears)
- [ ] FR-430 Rund-HUD (circular)
- [ ] FR-431 Hexagon-HUD (hex cells)
- [ ] FR-432 Organisches HUD (blob-basiert)
- [ ] FR-433 Flüchtiges HUD (schwebendes Material)
- [ ] FR-434 Sprechblase-HUD (character quips)
- [ ] FR-435 Scrolling Text-HUD (Schriftrolle)
- [ ] FR-436 Musikalische-Noten-HUD
- [ ] FR-437 Mystisches HUD (rune-basiert)
- [ ] FR-438 Analog-HUD (steampunk dials)
- [ ] FR-439 Hologramm-Störungs-FX im HUD
- [ ] FR-440 Kryptisches HUD (Matrix-style)

### Menüs & Navigation (FR-441–FR-480)

**Existente Features (FR-221–FR-240):**
- [ ] FR-441 Welt-/Kapitelauswahl-Karte
- [x] FR-442 Animierte Menü-Übergänge
- [x] FR-443 Einstellungs-Untermenüs
- [ ] FR-444 Shop-Bildschirm
- [ ] FR-445 Sammlungs-/Galerie-Bildschirm
- [ ] FR-446 Statistik-Bildschirm
- [ ] FR-447 Credits-Bildschirm
- [ ] FR-448 Bestätigungsdialoge
- [ ] FR-449 Lade-Bildschirm mit Tipps
- [ ] FR-450 Splash-Screen/Logo-Intro
- [x] FR-451 Animierter Hauptmenü-Hintergrund
- [ ] FR-452 Level-Detail-Popup
- [x] FR-453 Korrekte Android-Zurück-Button
- [ ] FR-454 Tab-Navigation
- [ ] FR-455 Such-/Filterfunktion
- [ ] FR-456 Favoriten-Level markieren
- [ ] FR-457 Fortschritts-Übersicht
- [ ] FR-458 Schnellstart: letztes Level
- [ ] FR-459 Sound-Feedback in Menüs
- [x] FR-460 Onboarding-Begrüßungsbildschirm

**Neue Erweiterte Features (FR-461–FR-480):**
- [ ] FR-461 Kontext-Menü (Right-Click/Long-Press)
- [ ] FR-462 Dynamische Menü-Verwandlungen
- [ ] FR-463 Animierte Menü-Charaktere
- [ ] FR-464 Voiceover-Menü-Navigationen
- [ ] FR-465 Menü-Story-Progression
- [ ] FR-466 Menü-Easter-Eggs
- [ ] FR-467 Minimalist-Modus (nur Text)
- [ ] FR-468 Spieler-Namen-Bearbeitung-Bildschirm
- [ ] FR-469 Freundes-Profil-Schnellansicht
- [ ] FR-470 Clan-/Guilds-Verwaltungs-Menü
- [ ] FR-471 News-/Ankündigungs-Bildschirm
- [ ] FR-472 Patch-Notes-Anzeige
- [ ] FR-473 Fehlerberichte-Bildschirm
- [ ] FR-474 Kontakt-Support-Menü
- [ ] FR-475 FAQ/Hilfemenü
- [ ] FR-476 Tutorial-Wiederholung-Menü
- [ ] FR-477 Kontrollen-Neu-Mapping-Menü
- [ ] FR-478 Datenbank-Reset-Bestätigung
- [ ] FR-479 Bannwarn-Bildschirm
- [ ] FR-480 Benachrichtigungs-Präferenz-Menü

### Audio & Musik (FR-481–FR-520)

**Existente Features (FR-241–FR-260):**
- [ ] FR-481 Hintergrundmusik pro Welt
- [ ] FR-482 Dynamische Musik
- [ ] FR-483 Münz-Sammel-Sounds
- [ ] FR-484 Umfangreiche Furz-Sound-Bibliothek
- [ ] FR-485 Treffer- und Tod-Sounds
- [ ] FR-486 Sieg-Fanfare
- [x] FR-487 UI-Klick-Sounds
- [ ] FR-488 Ambient-Soundscapes
- [ ] FR-489 Getrennte Lautstaerkeregler
- [x] FR-490 Stumm-Schalter
- [ ] FR-491 Audio-Ducking
- [ ] FR-492 Positions-/3D-Audio
- [ ] FR-493 Countdown-Sound
- [ ] FR-494 Combo-Steigerungs-Sound
- [ ] FR-495 Boss-Kampf-Musik
- [ ] FR-496 Menü-Musik
- [ ] FR-497 Furz-Sound an Stärke gekoppelt
- [ ] FR-498 Audio-Bus-Setup
- [ ] FR-499 Stille-Modus
- [ ] FR-500 Freischaltbare Soundpakete

**Neue Erweiterte Features (FR-501–FR-520):**
- [ ] FR-501 Adaptive Musik (Stimmung-basiert)
- [ ] FR-502 Generative Musik (prozedural)
- [ ] FR-503 Spatialisierter Sound (3D-Audio)
- [ ] FR-504 HRTF-Binaural-Audio (Kopfhörer)
- [ ] FR-505 Physikalische Soundsynthese
- [ ] FR-506 Ökologische Soundscapes (Naturgeräusche)
- [ ] FR-507 Feedback-Audio (Sensory Resonance)
- [ ] FR-508 Konzertsimulation-Musik
- [ ] FR-509 Spieler-Stimme-Integration
- [ ] FR-510 Multiplex-Kanäle (Raumklang)
- [ ] FR-511 Spektrale Musik-Effekte
- [ ] FR-512 Granulare Synthese
- [ ] FR-513 Wavetable-Synthese
- [ ] FR-514 Konvolutionshallerkennung
- [ ] FR-515 Zeit-Stretching (ohne Pitch-Änderung)
- [ ] FR-516 Pitch-Shifting
- [ ] FR-517 Vocoder-Effekte
- [ ] FR-518 Klangsynthese-Musik
- [ ] FR-519 Metatonal-Musik (29+ Töne pro Oktave)
- [ ] FR-520 Stochastische Komposition

### Visuelle Effekte & Juice (FR-521–FR-560)

**Existente Features (FR-261–FR-280):**
- [x] FR-521 Partikel beim Münz-Sammeln
- [x] FR-522 Aufprall-Staub
- [x] FR-523 Explosions-Effekte
- [x] FR-524 Geschwindigkeits-Linien
- [x] FR-525 Bildschirm-Blitz bei Tod
- [x] FR-526 Hit-Stop
- [ ] FR-527 Verbesserte Furz-Wolke
- [x] FR-528 Sieges-Konfetti
- [x] FR-529 Münz-Magnet-Spur-Effekt
- [ ] FR-530 Slow-Mo-Visualfilter
- [x] FR-531 Schweif-Effekt
- [ ] FR-532 Wasser-Spritzer-Effekte
- [ ] FR-533 Lava-Glühen
- [ ] FR-534 Sternen-Funkeln
- [x] FR-535 Floating-Text
- [ ] FR-536 Wischeffekte
- [ ] FR-537 Power-up-Aura
- [ ] FR-538 Umgebungspartikel
- [ ] FR-539 Verzerrung
- [x] FR-540 Combo-Feuerwerk

**Neue Erweiterte Features (FR-541–FR-560):**
- [ ] FR-541 Morphing-Effekte (flüssige Übergänge)
- [ ] FR-542 Fraktalische Partikel
- [ ] FR-543 Prismatische Lichtstrahlen
- [ ] FR-544 Holographische Flimmer
- [ ] FR-545 Zeitverzögerungs-Echos
- [ ] FR-546 Kausalitäts-Linien (Ursache-Wirkung-Trails)
- [ ] FR-547 Quantenpunkte-Überlagerung
- [ ] FR-548 Wellenfunktions-Kollaps-Animation
- [ ] FR-549 Schrödingers-Partikel (existieren und nicht)
- [ ] FR-550 Superpositional-Effekte
- [ ] FR-551 Verschlüsselung-Dekodierungs-Effekt
- [ ] FR-552 Signalrauschen-Verzerrung
- [ ] FR-553 Glitching-Effekte
- [ ] FR-554 Glitch-Art-Visuals
- [ ] FR-555 Retrowave-Synthwave-Effekte
- [ ] FR-556 VHS-Bandverschleiß-Effekt
- [ ] FR-557 Film-Körnigkeit
- [ ] FR-558 Druckschwärze-Effekt
- [ ] FR-559 Aquarell-Verlauf-Effekt
- [ ] FR-560 Aquarellartige Übergangs-Effekte

### Shader & Rendering (FR-561–FR-600)

**Existente Features (FR-281–FR-300):**
- [ ] FR-561 Weltraum-Hintergrund-Shader
- [ ] FR-562 Optionaler CRT-/Retro-Filter
- [ ] FR-563 Wasser-Brechungs-Shader
- [ ] FR-564 Hitzeflimmer-Shader
- [ ] FR-565 Outline-Shader
- [x] FR-566 Vignette-Post-Processing
- [ ] FR-567 Bloom
- [ ] FR-568 Chromatische Aberration
- [ ] FR-569 Dunkelheits-/Sichtkegel-Shader
- [ ] FR-570 Tag-/Nacht-Verlauf-Shader
- [ ] FR-571 Aufösungsskalierung
- [ ] FR-572 Farb-Grading
- [ ] FR-573 Furz-Wolken-Verzerrungs-Shader
- [ ] FR-574 Motion Blur
- [ ] FR-575 Sterne-Parallax-Shader
- [ ] FR-576 2D-Beleuchtung und Schatten
- [ ] FR-577 Schild-Energie-Shader
- [ ] FR-578 Dissolve-Effekt
- [ ] FR-579 Pixel-Perfect-Render
- [ ] FR-580 Performance-Shader-Qualität

**Neue Erweiterte Features (FR-581–FR-600):**
- [ ] FR-581 Raymarching-Shader (3D in 2D)
- [ ] FR-582 Cellular-Automata-Shader
- [ ] FR-583 Perlin-Noise-Shader
- [ ] FR-584 Worley-Noise-Shader
- [ ] FR-585 Simplex-Noise-Shader
- [ ] FR-586 Voronoi-Diagramm-Shader
- [ ] FR-587 Delaunay-Triangulation-Shader
- [ ] FR-588 Mandelbrot-Set-Shader
- [ ] FR-589 Julia-Set-Shader
- [ ] FR-590 Hyperbolic-Geometry-Shader
- [ ] FR-591 Relativitäts-Effekt-Shader
- [ ] FR-592 Schwarze-Loch-Krümmung
- [ ] FR-593 Gravitations-Linsen-Shader
- [ ] FR-594 Quanten-Tunneleffekt-Shader
- [ ] FR-595 Schrödinger-Visualisierungs-Shader
- [ ] FR-596 Superfluid-Helium-Shader
- [ ] FR-597 Bose-Einstein-Kondensation-Shader
- [ ] FR-598 Hawking-Strahlung-Shader
- [ ] FR-599 Dunkle-Materie-Shader
- [ ] FR-600 Antimaterie-Annihilation-Shader

### Fortschritt & Meta-Progression (FR-601–FR-640)

**Existente Features (FR-301–FR-320):**
- [x] FR-601 Globaler XP-/Spieler-Level
- [x] FR-602 Sterne-Gesamtzahl
- [ ] FR-603 Welt-Freischaltung
- [ ] FR-604 Skill-Baum
- [ ] FR-605 Permanente Upgrades
- [ ] FR-606 Prestige-/New-Game+
- [ ] FR-607 Sammel-Album
- [ ] FR-608 Meilenstein-Belohnungen
- [ ] FR-609 Tägliche Login-Belohnungen
- [ ] FR-610 Wöchentliche Ziele
- [ ] FR-611 Battle-Pass-/Saison-Fortschritt
- [ ] FR-612 Freischalt-Roadmap-Anzeige
- [ ] FR-613 Münz-Sparziele
- [ ] FR-614 Geräteübergreifende Fortschritts-Synchronisierung
- [ ] FR-615 Komplettierungs-Belohnung
- [ ] FR-616 Hard-Mode-Sterne
- [ ] FR-617 Bestzeiten-Sammlung
- [ ] FR-618 Statistik-getriebene Abzeichen
- [ ] FR-619 Stufenweise Freischaltung
- [ ] FR-620 Belohnungs-Vorschau

**Neue Erweiterte Features (FR-621–FR-640):**
- [ ] FR-621 Überwelt-Progression (Landkarte)
- [ ] FR-622 Labyrinth-Fortschritt-System
- [ ] FR-623 Unendliche Ebenen-Freischaltung
- [ ] FR-624 Klassensystem (Warrior/Mage/Archer)
- [ ] FR-625 Spezialisierungs-Baum
- [ ] FR-626 Talent-Punkte-Verteilung
- [ ] FR-627 Knappschaftssystem
- [ ] FR-628 Legendäres Item-Sammeln
- [ ] FR-629 Artefakt-Sammlungsgesamtsätze
- [ ] FR-630 Transmogrifikation (Item-Umwandlung)
- [ ] FR-631 Enchantment-System
- [ ] FR-632 Runensteine-Sockelsystem
- [ ] FR-633 Schmiede-System für Items
- [ ] FR-634 Alchimie-Labor für Potentionen
- [ ] FR-635 Transmutation-Kreis
- [ ] FR-636 Seelengebund-Items
- [ ] FR-637 Flächenübergreifender Fortschritt
- [ ] FR-638 Planar-Ascension-System
- [ ] FR-639 Göttliches Klassifikationssystem
- [ ] FR-640 Omniversale-Unendlichkeit-Währung

### Erfolge & Herausforderungen (FR-641–FR-680)

**Existente Features (FR-321–FR-340):**
- [ ] FR-641 Achievement-System
- [ ] FR-642 Erfolge für Anzahl Fürze
- [ ] FR-643 Münz-Sammel-Erfolge
- [ ] FR-644 Pazifist-Lauf
- [ ] FR-645 Perfekt-Lauf
- [ ] FR-646 Speed-Erfolge
- [ ] FR-647 Sparsam-Furz-Erfolge
- [ ] FR-648 Erfolg: alle Sterne
- [ ] FR-649 Tägliche Herausforderungen
- [ ] FR-650 Wöchentliche Herausforderungen
- [ ] FR-651 Herausforderungs-Modifikatoren
- [ ] FR-652 Erfolgs-Fortschrittsanzeige
- [ ] FR-653 Versteckte Erfolge
- [ ] FR-654 Erfolgs-Belohnungen
- [ ] FR-655 Streak-Erfolge
- [ ] FR-656 Combo-Erfolge
- [ ] FR-657 Welt-spezifische Erfolge
- [ ] FR-658 Erfolgs-Benachrichtigungs-Pop-ups
- [ ] FR-659 Sortierung/Filter
- [ ] FR-660 Plattformübergreifende Erfolge

**Neue Erweiterte Features (FR-661–FR-680):**
- [ ] FR-661 Meta-Erfolge (Erfolge sammeln)
- [ ] FR-662 Geheime Kampagnen-Erfolge
- [ ] FR-663 Easter-Egg-Erfolge
- [ ] FR-664 Absurdistische Erfolge
- [ ] FR-665 Unmögliche Erfolge (Unmöglich zu erreichen)
- [ ] FR-666 Satanische Erfolge (666er)
- [ ] FR-667 Virenhafte Erfolge (ansteckend)
- [ ] FR-668 Selbstbewusste Erfolge (erkennen sich selbst)
- [ ] FR-669 Paradoxe Erfolge (existieren und nicht)
- [ ] FR-670 Doppelter Erfolg (zwei gleichzeitig verdienen)
- [ ] FR-671 Zeitlosigkeits-Erfolg (immer wahr)
- [ ] FR-672 Kausalitäts-Erfolg (arbeitet rückwärts)
- [ ] FR-673 Multiverse-Erfolge (in allen Universen)
- [ ] FR-674 Schrödinger-Erfolge (verdient/nicht verdient)
- [ ] FR-675 Infinitesimale-Erfolge
- [ ] FR-676 Transzendente Erfolge
- [ ] FR-677 Göttliche Erfolge
- [ ] FR-678 Übernatürliche Erfolge
- [ ] FR-679 Unternatürliche Erfolge
- [ ] FR-680 Okkulte Erfolge

### Spielmodi (FR-681–FR-720)

**Existente Features (FR-341–FR-360):**
- [ ] FR-681 Zeitrennen-Modus
- [ ] FR-682 Prozeduraler Endlos-Modus
- [ ] FR-683 Überlebens-Modus
- [ ] FR-684 Hardcore-Modus
- [ ] FR-685 Zen-/Entspannungsmodus
- [ ] FR-686 Münz-Jagd-Modus
- [ ] FR-687 Boss-Rush-Modus
- [ ] FR-688 Spiegel-Modus
- [ ] FR-689 Modus mit Mutatoren
- [ ] FR-690 Täglicher Lauf
- [ ] FR-691 Co-op-Modus
- [ ] FR-692 Versus-Modus
- [ ] FR-693 Geist-Rennen
- [ ] FR-694 Kein-Treibstoff-Modus
- [ ] FR-695 Präzisions-Modus
- [ ] FR-696 Sammel-Marathon
- [ ] FR-697 Dunkel-Modus
- [ ] FR-698 Umgekehrte-Schwerkraft-Modus
- [ ] FR-699 Chaos-Modus
- [ ] FR-700 Übungsmodus

**Neue Erweiterte Features (FR-701–FR-720):**
- [ ] FR-701 Roguelike-Modus
- [ ] FR-702 Roguelite-Modus
- [ ] FR-703 Deckabuilding-Modus
- [ ] FR-704 Puzzle-Quest-Modus
- [ ] FR-705 Symmetrie-Modus
- [ ] FR-706 Inversion-Modus
- [ ] FR-707 Permadeath-Ironman-Modus
- [ ] FR-708 Zeitreise-Modus
- [ ] FR-709 Parallel-Timeline-Modus
- [ ] FR-710 Multiversum-Modus
- [ ] FR-711 Quantenüberlag-Modus
- [ ] FR-712 Schrödinger-Modus
- [ ] FR-713 Nichtlinearer-Modus (wähle Reihenfolge)
- [ ] FR-714 Rückwärts-Modus
- [ ] FR-715 Zeitschleife-Modus
- [ ] FR-716 Träum-Modus
- [ ] FR-717 Alptraum-Modus
- [ ] FR-718 VR-Modus (wenn Hardware vorhanden)
- [ ] FR-719 AR-Modus (wenn Hardware vorhanden)
- [ ] FR-720 Mythenverzerrung-Modus

### Events & Live-Ops (FR-721–FR-760)

**Existente Features (FR-361–FR-380):**
- [ ] FR-721 Saisonale Events
- [ ] FR-722 Zeitlich begrenzte Level
- [ ] FR-723 Event-Währung
- [ ] FR-724 Community-Ziele
- [ ] FR-725 Wochenend-Boni
- [ ] FR-726 Event-Bestenlisten
- [ ] FR-727 Countdown-Timer
- [ ] FR-728 Event-Banner
- [ ] FR-729 Glücksrad-Event
- [ ] FR-730 Sammel-Events
- [ ] FR-731 Login-Kalender-Event
- [ ] FR-732 Themen-Events
- [ ] FR-733 Remote-Config
- [ ] FR-734 Push-Benachrichtigungen
- [ ] FR-735 Event-Belohnungs-Stufen
- [ ] FR-736 Flash-Sales
- [ ] FR-737 Doppelte-Sterne-Wochenende
- [ ] FR-738 Event-Tutorial
- [ ] FR-739 Event-Historie
- [ ] FR-740 A/B-getestete Event-Varianten

**Neue Erweiterte Features (FR-741–FR-760):**
- [ ] FR-741 Tragische Event (Weltende)
- [ ] FR-742 Komische Event (Absurdist)
- [ ] FR-743 Romantische Event (Liebesgeschichte)
- [ ] FR-744 Horroristische Event (Angst)
- [ ] FR-745 Mysthische Event (Mysterium)
- [ ] FR-746 Wissenschaftliche Event (Eukalypta)
- [ ] FR-747 Historische Event (Zeit-Reise)
- [ ] FR-748 Futuristische Event (Sci-Fi)
- [ ] FR-749 Fantasy-Event (Magische Welt)
- [ ] FR-750 Cyberpunk-Event (Neon-Welt)
- [ ] FR-751 Steampunk-Event (Gears & Vapor)
- [ ] FR-752 Post-Apokalypse-Event
- [ ] FR-753 Alien-Invasion-Event
- [ ] FR-754 Zombifizierung-Event
- [ ] FR-755 Vampirische-Übernahme-Event
- [ ] FR-756 Werewolf-Transformation-Event
- [ ] FR-757 Göttliche-Intervention-Event
- [ ] FR-758 Dämonische-Übernahme-Event
- [ ] FR-759 Angelmittlung-Event
- [ ] FR-760 Kosmische-Horror-Event

### Soziales & Bestenlisten (FR-761–FR-800)

**Existente Features (FR-381–FR-400):**
- [ ] FR-761 Globale Bestenlisten
- [ ] FR-762 Freundes-Bestenlisten
- [ ] FR-763 Wöchentliche Ranglisten-Resets
- [ ] FR-764 Geist-Daten-Teilen
- [ ] FR-765 Level-Teilen
- [ ] FR-766 Screenshot-Teilen
- [ ] FR-767 Replay-Teilen
- [ ] FR-768 Social-Media-Integration
- [ ] FR-769 Einladungs-/Empfehlungssystem
- [ ] FR-770 Gilden/Clans
- [ ] FR-771 Clan-Wettbewerbe
- [ ] FR-772 Herausforderung an Freund
- [ ] FR-773 Erfolgs-Teilen
- [ ] FR-774 Moderierter In-Game-Chat
- [ ] FR-775 Profil-Seiten
- [ ] FR-776 Liga-/Divisions-System
- [ ] FR-777 Saison-Belohnungen nach Rang
- [ ] FR-778 Anti-Cheat
- [ ] FR-779 Regionale Bestenlisten
- [ ] FR-780 Bestenlisten-UI

**Neue Erweiterte Features (FR-781–FR-800):**
- [ ] FR-781 Ego-Meter (Rivalität-Verfolgung)
- [ ] FR-782 Freundschafts-Sterne (gegenseitig)
- [ ] FR-783 Fan-Systeme (Follower)
- [ ] FR-784 Celebrity-Status
- [ ] FR-785 Influencer-Integration
- [ ] FR-786 Streamer-Modus
- [ ] FR-787 Video-Highlights-Auto-Sharing
- [ ] FR-788 In-Game-Moderation
- [ ] FR-789 Spieler-Reputation-System
- [ ] FR-790 Vertrauen-Level
- [ ] FR-791 Transparenzberichte
- [ ] FR-792 Spieler-Verifikation
- [ ] FR-793 Blue-Checkmark-System
- [ ] FR-794 VIP-Status
- [ ] FR-795 Premium-Badges
- [ ] FR-796 Kommunal-Projekte
- [ ] FR-797 Crowdcurating
- [ ] FR-798 Player-Voting
- [ ] FR-799 Dynamische Community-Events
- [ ] FR-800 Social-Network-Graphen-Integration

### Speichern & Cloud (FR-801–FR-840)

**Existente Features (FR-401–FR-420):**
- [ ] FR-801 Lokales Speichersystem
- [ ] FR-802 Cloud-Speicher
- [ ] FR-803 Mehrere Speicherstände
- [ ] FR-804 Auto-Speichern
- [ ] FR-805 Konfliktauflösung
- [ ] FR-806 Speicher-Backup
- [ ] FR-807 Speicher-Import
- [ ] FR-808 Daten-Migration
- [ ] FR-809 Verschlüsselte Speicherdaten
- [ ] FR-810 Speicher-Reset-Option
- [ ] FR-811 Fortschritt-Wiederherstellung
- [ ] FR-812 Offline-Fortschritt-Synchronisierung
- [ ] FR-813 Speicher-Integritätsprüfung
- [ ] FR-814 Einstellungen separat speichern
- [ ] FR-815 Geräteübergreifende Synchronisierung
- [ ] FR-816 Speicher-Versionierung
- [ ] FR-817 Wiederherstellung bei Korruption
- [ ] FR-818 UI zur Speicher-Slot-Verwaltung
- [ ] FR-819 Cloud-Sync-Status-Anzeige
- [ ] FR-820 DSGVO-konformes Daten-Löschen

**Neue Erweiterte Features (FR-821–FR-840):**
- [ ] FR-821 Blockchain-Speicherung (optional)
- [ ] FR-822 Dezentralisierte Cloud-Architektur
- [ ] FR-823 Torrent-basierte Peer-to-Peer-Sicherung
- [ ] FR-824 IPFS-Speicherung
- [ ] FR-825 Quantenkryptographie
- [ ] FR-826 Post-Quanten-Verschlüsselung
- [ ] FR-827 Geheimnisfreigabe-Speicher
- [ ] FR-828 Zero-Knowledge-Proofs
- [ ] FR-829 Zeitgestempel-Verifikation
- [ ] FR-830 Merkle-Tree-Validierung
- [ ] FR-831 Hashbaum-Architektur
- [ ] FR-832 Diff-Kompression (delta storage)
- [ ] FR-833 Lossless-Kompression
- [ ] FR-834 Polyglot-Persistent
- [ ] FR-835 Zeitmaschinen-Snapshot
- [ ] FR-836 Copy-on-Write-Speicher
- [ ] FR-837 Memory-Mapped-Files
- [ ] FR-838 Mmap-Optimierung
- [ ] FR-839 Speicher-Telemetrie
- [ ] FR-840 Speicher-Fragmentierungs-Analyse

### Einstellungen & Barrierefreiheit (FR-841–FR-880)

**Existente Features (FR-421–FR-440):**
- [ ] FR-841 Farbenblind-Modi
- [ ] FR-842 Hoher-Kontrast-Modus
- [ ] FR-843 Reduzierte-Bewegung-Option
- [ ] FR-844 Einstellbare Schriftgröße
- [ ] FR-845 Untertitel für Soundeffekte
- [ ] FR-846 Einhand-Modus
- [ ] FR-847 Auto-Furz-/Assist-Modus
- [ ] FR-848 Haptik ein/aus
- [ ] FR-849 Bildschirm-Helligkeit
- [ ] FR-850 Einstellbare Steuerungs-Empfindlichkeit
- [ ] FR-851 Umschaltbare FPS-Anzeige
- [ ] FR-852 Bildraten-Begrenzung
- [ ] FR-853 Daltonismus-Palette
- [ ] FR-854 Bildschirmleser-Hinweise
- [ ] FR-855 Tipp-Bestätigungen
- [ ] FR-856 Pause bei Fokusverlust
- [ ] FR-857 Konfigurierbare Schwierigkeits-Assists
- [ ] FR-858 Lautstärke-Voreinstellungen
- [ ] FR-859 Sprachwahl
- [ ] FR-860 Zurücksetzen-auf-Standard-Button

**Neue Erweiterte Features (FR-861–FR-880):**
- [ ] FR-861 Dyslexie-Schrift-Modus
- [ ] FR-862 Dyspraxie-Navigation-Hilfen
- [ ] FR-863 Dyscalculia-Hilfen
- [ ] FR-864 ADHS-Fokus-Helfer
- [ ] FR-865 Autismus-Spektrum-Anpassung
- [ ] FR-866 Bipolare-Thema-Sicherheit
- [ ] FR-867 PTSD-Trigger-Warnung
- [ ] FR-868 Angststörungs-Helfer
- [ ] FR-869 Depression-Unterstützungs-Ressourcen
- [ ] FR-870 Schlafentzug-Warnung
- [ ] FR-871 Eye-Strain-Schutz
- [ ] FR-872 Kopfschmerz-Warnung
- [ ] FR-873 Photosensible-Absicherung
- [ ] FR-874 Bewegungskrankheit-Vorbeugung
- [ ] FR-875 Motorische-Kontroll-Hilfen
- [ ] FR-876 Visueller-Suchassistent
- [ ] FR-877 Audio-Beacon-Navigation
- [ ] FR-878 Taktile-Feedback-Mapping
- [ ] FR-879 Augenverfolgung-Steuerung
- [ ] FR-880 Brain-Computer-Interface-Bereitschaft

### Lokalisierung & i18n (FR-881–FR-920)

**Existente Features (FR-441–FR-460):**
- [ ] FR-881 Lokalisierungs-System
- [ ] FR-882 Englische Übersetzung
- [ ] FR-883 Deutsche Übersetzung
- [ ] FR-884 Spanische Übersetzung
- [ ] FR-885 Französische Übersetzung
- [ ] FR-886 Portugiesische (BR) Übersetzung
- [ ] FR-887 Italienische Übersetzung
- [ ] FR-888 Türkische Übersetzung
- [ ] FR-889 Russische Übersetzung
- [ ] FR-890 Japanische Übersetzung
- [ ] FR-891 Koreanische Übersetzung
- [ ] FR-892 Chinesische (vereinfacht) Übersetzung
- [ ] FR-893 RTL-Unterstützung
- [ ] FR-894 Lokalisierte Zahlen-/Zeitformate
- [ ] FR-895 Dynamischer Sprachwechsel
- [ ] FR-896 Schriftarten mit voller Glyphen-Abdeckung
- [ ] FR-897 Lokalisierte Store-Texte
- [ ] FR-898 Pluralisierungs-Regeln
- [ ] FR-899 Übersetzungs-Fallback-Logik
- [ ] FR-900 QA-Werkzeug

**Neue Erweiterte Features (FR-901–FR-920):**
- [ ] FR-901 Chinesische (traditionell) Übersetzung
- [ ] FR-902 Vietnamesische Übersetzung
- [ ] FR-903 Thailändische Übersetzung
- [ ] FR-904 Indonesische Übersetzung
- [ ] FR-905 Malaiische Übersetzung
- [ ] FR-906 Arabische Übersetzung
- [ ] FR-907 Hebräische Übersetzung
- [ ] FR-908 Persische Übersetzung
- [ ] FR-909 Urdu-Übersetzung
- [ ] FR-910 Hindi-Übersetzung
- [ ] FR-911 Bengali-Übersetzung
- [ ] FR-912 Tamil-Übersetzung
- [ ] FR-913 Gujarati-Übersetzung
- [ ] FR-914 Marathi-Übersetzung
- [ ] FR-915 Telugu-Übersetzung
- [ ] FR-916 Kannada-Übersetzung
- [ ] FR-917 Malayalam-Übersetzung
- [ ] FR-918 Odia-Übersetzung
- [ ] FR-919 Punjabi-Übersetzung
- [ ] FR-920 Esperanto-Übersetzung (Easter Egg)

### Performance & Technik (FR-921–FR-960)

**Existente Features (FR-461–FR-480):**
- [ ] FR-921 Objekt-Pooling
- [ ] FR-922 Texturen-Atlas
- [ ] FR-923 Level-Streaming
- [ ] FR-924 Bildraten-Profiling-Overlay
- [ ] FR-925 Speicher-Leck-Tests
- [ ] FR-926 Reduzierte Partikel
- [ ] FR-927 Automatische Qualitätserkennung
- [ ] FR-928 Hintergrund-Pausierung
- [ ] FR-929 Ladezeiten-Optimierung
- [ ] FR-930 Asset-Vorladen
- [ ] FR-931 Tuning des Physik-Schritts
- [ ] FR-932 Garbage-Collection-Spitzen
- [ ] FR-933 Shader-Vorkompilierung
- [ ] FR-934 APK-/AAB-Grös-Optimierung
- [ ] FR-935 Stresstest-Szene
- [ ] FR-936 Crash-Reporting-Integration
- [ ] FR-937 ANR-Vermeidung
- [ ] FR-938 Frame-Pacing
- [ ] FR-939 Geräte-Kompatibilitätsmatrix
- [ ] FR-940 Automatisierte Performance-Benchmarks

**Neue Erweiterte Features (FR-941–FR-960):**
- [ ] FR-941 Profiling-Heatmaps
- [ ] FR-942 Memory-Profiler-Integration
- [ ] FR-943 CPU-Profiler-Integration
- [ ] FR-944 GPU-Profiler-Integration
- [ ] FR-945 Thermal-Monitoring
- [ ] FR-946 Battery-Usage-Tracking
- [ ] FR-947 Speicher-Fragmentierungs-Analyse
- [ ] FR-948 Cache-Invalidierungs-Tracking
- [ ] FR-949 Spectre/Meltdown-Sicherheit
- [ ] FR-950 SIMD-Vektorisierung
- [ ] FR-951 Parallelisierungsgrenzen
- [ ] FR-952 Lock-freie Datenstrukturen
- [ ] FR-953 Speicher-Alignierung-Optimierung
- [ ] FR-954 Prefetch-Optimierung
- [ ] FR-955 Branch-Prediction-Vermeidung
- [ ] FR-956 Cache-Line-Alignment
- [ ] FR-957 False-Sharing-Eliminierung
- [ ] FR-958 Memory-Bandwidth-Optimierung
- [ ] FR-959 Latency-Hiding-Strategien
- [ ] FR-960 Power-Management-Integration

### Android-Plattform & Veröffentlichung (FR-961–FR-1000)

**Existente Features (FR-481–FR-500):**
- [ ] FR-961 Adaptive Launcher-Icons
- [ ] FR-962 App-Splash-Screen
- [ ] FR-963 Google Play Billing
- [ ] FR-964 Belohnte Werbeanzeigen
- [ ] FR-965 Sparsame Interstitial-Werbung
- [ ] FR-966 Google Play Games Services Login
- [ ] FR-967 In-App-Bewertungsaufforderung
- [ ] FR-968 Deep-Links zu Leveln
- [ ] FR-969 Build-Pipeline für App-Bundle
- [ ] FR-970 ProGuard-/R8-Konfiguration
- [ ] FR-971 Datenschutzerklärung
- [ ] FR-972 Altersfreigabe/Content-Rating
- [ ] FR-973 Store-Listing-Assets
- [ ] FR-974 Beta-/Testkanal-Einrichtung
- [ ] FR-975 Versionierungs-/Release-Notes-Prozess
- [ ] FR-976 Tablet-optimierte Layouts
- [ ] FR-977 Foldable-Unterstützung
- [ ] FR-978 Edge-to-Edge-/Notch-Handhabung
- [ ] FR-979 Push-Benachrichtigungs-Setup
- [ ] FR-980 CI/CD für automatische Builds

**Neue Erweiterte Features (FR-981–FR-1000):**
- [ ] FR-981 Android 15+ Target-API
- [ ] FR-982 Privacy-Dashboard-Integration
- [ ] FR-983 Predictive-Back-Gestures
- [ ] FR-984 Grammatik-Check-Integration
- [ ] FR-985 Spell-Check-Integration
- [ ] FR-986 Sprachtyp-Prognose
- [ ] FR-987 Sprachkontext-Verständnis
- [ ] FR-988 Umgebungs-Audio-Analyse
- [ ] FR-989 Sicherheitspatrouille-Zusammenhang
- [ ] FR-990 Passwort-Manager-Integration
- [ ] FR-991 Biometrische Authentifizierung
- [ ] FR-992 NFC-Tag-Integration
- [ ] FR-993 Bluetooth-Peripheral-Support
- [ ] FR-994 Wearable-Gerät-Unterstützung
- [ ] FR-995 Smart-Watch-App
- [ ] FR-996 Android-Automotive-Modus
- [ ] FR-997 AndroidTV-Modus
- [ ] FR-998 Chromebook-Optimierung
- [ ] FR-999 Desktop-Linux-Port (über Electron)
- [ ] FR-1000 Göttliche Omniscience (Das Spiel weiß alles)

---

## Implementation Strategy

### Prioritäts-Tiers

**Tier S: MVP Core** (FR-001–FR-100 + essentials)
- Essenzielle Spielmechaniken
- 3-Level Grundmission
- HUD & Pause
- Touch-Input + Vibration
- Checkpoint-System

**Tier A: Post-MVP** (FR-101–FR-300)
- Gegner & Boss-Kämpfe
- Welt 2-6
- Musik & Sounds
- Achievements
- Shop & Skins

**Tier B: Advanced** (FR-301–FR-700)
- Level-Editor
- Multiplayer
- Live-Ops
- Procedural Content
- Advanced Progression

**Tier C: Polish & Expansion** (FR-701–FR-1000)
- Community Features
- Vollständige i18n
- Console Ports
- AI-Balancing
- Barrierefreiheit

### Architektur-Richtlinien

1. **Procedurales Design**: Alle Grafiken in GDScript generieren — keine PNG/JPG Assets.
2. **Signalbasierte Entkopplung**: Komponenten via Signale kommunizieren, nicht direkt.
3. **Skalierbarkeit**: Obstacle-Klassen als Basis für schnelle Variation.
4. **Testing**: Unit Tests für GameManager, Physics, Score-Berechnung.
5. **Version Control**: Commits mit Feature-ID (`FR-XXX`).

---

## Langfristige Vision

**Jahr 1 (MVP):**
- 30+ Level
- 20+ Gegner-Varianten
- 50+ Skins
- Achievements & Leaderboards
- 1 Million Spieler

**Jahr 2 (Expansion):**
- 100+ Level
- Level-Editor mit UGC
- Live-Ops, Events, Battle Pass
- Multiplayer (Koop, Versus)
- 5 Millionen Spieler

**Jahr 3+ (Maturity):**
- Konsolen-Ports (Nintendo Switch, PlayStation)
- Procedurale unendliche Levels
- AI-Bots für Matchmaking
- esports Liga-Support
- 20+ Millionen Spieler

---

**Fazit:**

Fart Rocket ist positioniert als **ein Indie-Spiel mit AAA-Potenzial**. Mit dieser 1000-Feature-Roadmap kann das Projekt über Jahre schrittweise wachsen, ohne die **ursprüngliche Design-Vision zu verlieren**: schnell, zugänglich, tiefgründig und **vollständig procedural**.

Die Architektur ist **skalierbar, wartbar und zukunftssicher**. Jede Phase baut auf der vorherigen auf, und Features können **parallel entwickelt und getestet** werden, dank der **signalbasierten Entkopplung und Godot 4.x-Stärken**.

*Fart Rocket — vom chaotischen Furz zur kosmischen Legende.*

---

*Dieses Dokument wird aktualisiert, wenn neue Features geplant oder implementiert werden.*
