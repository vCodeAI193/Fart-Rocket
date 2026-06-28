# 🚀 Fart Rocket

Ein physikbasiertes 2D-Spiel für **Android-Tablets**, entwickelt mit **Godot 4.x**.
Steuere ein Strichmännchen (Männchen), das sich mit **Furz-Stößen** wie eine Rakete
durch hindernisreiche Weltraum-Level bewegt. Sammle Münzen, weiche Hindernissen aus
und erreiche die Zielflagge!

## 🎮 Spielprinzip

- **Halten & Ziehen** auf dem Touchscreen → Zielrichtung festlegen (gelber Pfeil)
- **Loslassen** → Furz-Stoß propelliert das Männchen in Zugrichtung
- Die **Schwerkraft** zieht das Männchen ständig nach unten
- Das Männchen **rotiert** passend zur Flugrichtung
- **Begrenzte Furz-Ladungen** pro Level (Icons im HUD)
- **Hindernis berührt** = Level-Neustart (mit lustiger Trudel-Animation)
- **Flagge erreicht** = Level geschafft + **Stern-Bewertung (1–3)** je nach
  übrigen Furz-Ladungen

## 📁 Projektstruktur

```
Fart-Rocket/
├── project.godot          # Projektkonfiguration (Landscape, Touch, 1920x1200)
├── export_presets.cfg     # Android-Export (com.yourname.fartrocket, API 21+)
├── icon.svg               # App-Icon
├── scripts/
│   ├── GameManager.gd     # Autoload: Score, Level, Furz-Ladungen, Sterne
│   ├── Player.gd          # Männchen (RigidBody2D), Furz-Antrieb, Rotation
│   ├── FartBurst.gd       # Furz-Wolke (Partikel + Sound)
│   ├── Obstacle.gd        # Hindernisse (Balken, Stacheln, drehende Sägen)
│   ├── Coin.gd            # Einsammelbare Münze
│   ├── LevelEnd.gd        # Ziel-Flagge
│   ├── HUD.gd             # Furz-Icons, Münzzähler, Timer
│   ├── LevelComplete.gd   # Stern-Bewertung + Buttons
│   ├── MainMenu.gd        # Level-Auswahl
│   ├── Main.gd            # Level-Lader & Spielablauf
│   └── Starfield.gd       # Sternenhimmel-Hintergrund
├── scenes/
│   ├── MainMenu.tscn      # Startbildschirm (Hauptszene)
│   ├── Main.tscn          # Spielszene (lädt Level + HUD)
│   ├── Player.tscn
│   ├── FartBurst.tscn
│   ├── Obstacle.tscn
│   ├── Coin.tscn
│   ├── LevelEnd.tscn
│   ├── HUD.tscn
│   └── LevelComplete.tscn
└── levels/
    ├── Level1.tscn        # Weite Lücken, wenig Hindernisse, 5 Ladungen
    ├── Level2.tscn        # Enge Gänge, rotierende Sägen, 4 Ladungen
    └── Level3.tscn        # Kombination aus allem, 3 Ladungen
```

## 🛠️ Technische Eckdaten

| Eigenschaft        | Wert                                  |
|--------------------|---------------------------------------|
| Engine             | Godot 4.x (GL Compatibility Renderer) |
| Basisauflösung     | 1920 × 1200 (16:10)                   |
| Stretch-Modus      | `canvas_items` / `expand`             |
| Orientierung       | Nur Querformat (Landscape)            |
| Eingabe            | Nur Touch                             |
| Min. Android API   | 21                                    |
| Package-Name       | `com.yourname.fartrocket`             |

## ▶️ Starten

1. Projekt in **Godot 4.x** öffnen (`project.godot`).
2. Mit **F5** starten – auf dem Desktop emuliert die Maus die Touch-Eingabe.
3. Für Android: Android-Build-Vorlage installieren und über
   **Projekt → Exportieren → Android** exportieren.

## 🎵 Sounds

Alle `AudioStreamPlayer`-Knoten sind Platzhalter mit `@export`-Variablen
(`fart_sound`, `collect_sound`, `win_sound`). Eigene Sounds können im Editor
einfach an den jeweiligen Knoten/Szenen gesetzt werden.

## 🎨 Grafik

Es werden **keine externen Assets** verwendet – alle Grafiken (Strichmännchen,
Münzen, Hindernisse, Furz-Wolke, Hintergrund) werden per Code aus
`Line2D`, `Polygon2D`, `CPUParticles2D` und Farbverläufen erzeugt.
