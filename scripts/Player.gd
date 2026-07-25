extends RigidBody2D
class_name Player
## Player – das Furz-Männchen
## ==========================
## Ein RigidBody2D, das durch Furz-Stöße angetrieben wird.
##  - Touch halten & ziehen  -> Zielrichtung festlegen (Pfeil-Anzeige)
##  - Loslassen              -> Furz-Stoß in Zielrichtung (Rakete!)
##  - Schwerkraft zieht das Männchen ständig nach unten
##  - Das Männchen rotiert passend zur Flugrichtung
##  - Begrenzte Anzahl an Furz-Ladungen pro Level

# --- Export-Variablen (im Editor / pro Level einstellbar) --------
@export var fart_power: float = 900.0        # Stärke eines Furz-Stoßes (Impuls)
@export var max_fart_charges: int = 5        # Anzahl Furz-Ladungen im Level
@export var max_drag_distance: float = 300.0 # max. Ziehweite für volle Stärke
@export var fart_burst_scene: PackedScene    # FartBurst.tscn (Partikel + Sound)

# --- FR-021: Schwerkraft-Skalierung pro Level -------------------
@export var level_gravity_scale: float = 1.0 # 0.5 = Mond, 2.0 = Jupiter

# --- FR-032: Maximale Fluggeschwindigkeit -----------------------
@export var max_speed: float = 2400.0

# --- FR-033: Drall-Dämpfung (abklingende Rotation) -------------
@export var rotation_damping: float = 1.5

# --- FR-039: Realistische Luftreibung (optional) ----------------
@export var realistic_drag_enabled: bool = false
@export var drag_coefficient: float = 0.5
@export var air_density: float = 1.2
@export var reference_area: float = 50.0

# --- FR-162: Maennchen-Farbe (Skin) ----------------------------
@export var skin_color: Color = Color(0.95, 0.95, 0.95)

# --- FR-004: Treibstoff-Modus (Alternative zu festen Ladungen) ---
@export var fuel_mode: bool = false
@export var max_fuel: float = 100.0
@export var fuel_regen_rate: float = 20.0       # Kraftstoff pro Sekunde

# --- FR-007: Dauerstrahl-Furz (kontinuierlicher Schub) ---------
@export var continuous_thrust_enabled: bool = false
@export var continuous_thrust_power: float = 300.0
@export var continuous_thrust_cost: float = 15.0  # Treibstoff pro Sekunde

# --- FR-020: Anpassbare Furz-Schubkurven ---------------------
@export var power_curve: Curve = Curve.new()
var _initialized_curve: bool = false

# --- FR-053: Auto-Aim-Modus (Assist) ------------------------
@export var auto_aim_enabled: bool = false
@export var auto_aim_radius: float = 300.0  # Suchradius für Ziele

# --- FR-049: Anpassbare Pfeil-Visualisierung -----------------
@export var arrow_min_length: float = 60.0
@export var arrow_max_length_bonus: float = 140.0

# --- FR-052: Zielen mit Zeitlupe zur Feinjustierung ----------
@export var aim_slowmo_enabled: bool = false
@export var aim_slowmo_scale: float = 0.5

# --- FR-056: Eingabe-Pufferung für reaktionsschnelle Stöße ---
@export var input_buffer_window: float = 0.15

# --- FR-058: Bildschirm-Sperre während kritischer Aktionen ---
var input_locked: bool = false

# --- FR-001: Optionale Furz-Regeneration (pro Level einstellbar) -
@export var charge_regen_enabled: bool = false  # Ladungen mit der Zeit nachfüllen?
@export var charge_regen_time: float = 5.0      # Sekunden bis eine Ladung nachlädt

# --- FR-008: Mindestabstand zwischen zwei Furz-Stößen -----------
@export var fart_cooldown: float = 0.2          # Sekunden Abklingzeit

# --- FR-005: Aufgeladener Furz (länger halten = stärker) --------
@export var charge_hold_time: float = 0.8       # Zeit bis zur vollen Aufladung
@export var charge_hold_bonus: float = 0.6      # max. zusätzlicher Schub-Anteil

# --- Signale ----------------------------------------------------
signal died                                  # Männchen hat ein Hindernis getroffen
signal aim_changed(direction, strength)      # Zielrichtung/-stärke geändert
signal aim_released                          # Zielen beendet (Pfeil ausblenden)
signal fart_type_changed(index)              # aktiver Furz-Typ gewechselt (FR-002)
signal fart_fired(impulse, direction)         # FR-265/192: Furz ausgelöst (für Kamera-Wackeln/-Stoß)
signal shield_changed(active)               # FR-010: Schild aktiviert/deaktiviert

# --- FR-002: Verfügbare Furz-Typen ------------------------------
# power : Multiplikator auf fart_power
# cost  : verbrauchte Furz-Ladungen
# bursts: Anzahl der Stöße (Doppel-Stoß = 2)
# color : Einfärbung der Furz-Wolke
const FART_TYPES := [
	{"id": "mini", "name": "Mini", "power": 0.55, "cost": 1, "bursts": 1,
		"color": Color(0.7, 0.95, 0.5)},
	{"id": "normal", "name": "Normal", "power": 1.0, "cost": 1, "bursts": 1,
		"color": Color(0.55, 0.85, 0.3)},
	{"id": "mega", "name": "Mega", "power": 1.8, "cost": 2, "bursts": 1,
		"color": Color(0.4, 0.7, 1.0)},
	{"id": "double", "name": "Doppel", "power": 0.85, "cost": 2, "bursts": 2,
		"color": Color(1.0, 0.7, 0.3)},
]

# --- interner Zustand -------------------------------------------
var _shield_remaining: float = 0.0          # FR-010: verbleibende Schild-Zeit
var _is_aiming: bool = false
var _aim_start: Vector2 = Vector2.ZERO       # Startpunkt der Berührung (Screen)
var _aim_current: Vector2 = Vector2.ZERO     # aktueller Berührungspunkt (Screen)
var _touch_index: int = -1                   # verfolgter Finger (Multitouch-sicher)
var _is_dead: bool = false                   # Tod/Restart läuft bereits
var _regen_accum: float = 0.0                # aufgelaufene Zeit für die Regeneration
var _fart_type_index: int = 1                # aktiver Furz-Typ (Standard: Normal)
var _aim_hold: float = 0.0                   # wie lange schon gezielt wird (FR-005)
var _cooldown_remaining: float = 0.0         # verbleibende Abklingzeit (FR-008)
var _current_fuel: float = 100.0             # FR-004: Aktueller Treibstoff
var _heat_level: float = 0.0                 # FR-012: Überhitzungs-Level (0..1)
var _overheat_cooldown: float = 0.0          # FR-012: Abklingzeit nach Überhitzung
var _ragdoll_active: bool = false            # FR-040: Ragdoll-Modus aktiv

# Referenzen auf untergeordnete Knoten
var _aim_arrow: Line2D
var _arms: Line2D  # FR-177: für Sieges-Pose-Animation
var _face_node: Node2D  # FR-167: für Gesichtsausdrücke
var _shield_aura: Polygon2D  # FR-297: Schild-Energie-Shader-Aura
var _powerup_aura: Line2D    # FR-277: generische Power-up-Aura
var _powerup_aura_count: int = 0  # zeitgleich aktive Power-up-Auren
var took_hit_this_run: bool = false  # FR-325: für "Perfekt-Lauf"-Erfolg
var ghost_path_recorded: PackedVector2Array = PackedVector2Array()  # FR-353
var _ghost_record_timer: float = 0.0


var _trail: Line2D = null              # FR-168: Flug-Spur
var _speed_lines: Array[Line2D] = []   # FR-264: Geschwindigkeitslinien
var _traj_dots: Array[Node2D] = []     # FR-048: Flugbahn-Vorschau
var _last_tap_time: float = -1.0       # FR-050: Doppel-Tipp-Erkennung
var _last_tap_pos: Vector2 = Vector2.ZERO  # FR-057: räumlicher Doppel-Tipp-Schwellwert
var _buffered_fart: bool = false       # FR-056: Eingabe-Pufferung
var _buffered_dir: Vector2 = Vector2.ZERO
var _buffered_charge_mult: float = 1.0
var _buffer_timer: float = 0.0
var _aim_slowmo_active: bool = false   # FR-052

# --- F01/F02: Squash & Stretch ------------------------------------------
# Das Männchen war bislang völlig starr (nur Rotation folgte der Flugrichtung).
# _squash läuft nach jedem Furz-Stoß von 1.0 gegen 0.0 aus und staucht die
# Figur kurz; zusätzlich streckt sie sich dauerhaft leicht in Flugrichtung,
# je schneller sie fliegt.
var _squash: float = 0.0
const SQUASH_DECAY := 6.0          # wie schnell die Stauchung ausläuft
const SQUASH_STRENGTH := 0.28      # maximale Stauchung beim Stoß
const STRETCH_MAX := 0.22          # maximale geschwindigkeitsabhängige Streckung
const STRETCH_FULL_SPEED := 1600.0 # Geschwindigkeit für volle Streckung
var _visual_root: Node2D = null    # Träger aller Körperteile (wird skaliert)

# --- F03/F04/F05: Dynamische Mimik --------------------------------------
# _render_face() existierte, wurde aber nur einmal beim Aufbau mit der im
# Shop gekauften Miene aufgerufen. Jetzt wechselt der Ausdruck situativ.
var _current_expression: String = ""
var _shock_timer: float = 0.0      # F05: Schreck nach Beinahe-Treffer
const SHOCK_DURATION := 0.6
const FEAR_SPEED := 1300.0         # ab dieser Geschwindigkeit: Angst-Gesicht

# --- F09: Blinzeln im Ruhezustand ---------------------------------------
var _blink_timer: float = 0.0
var _blink_active: bool = false

# --- F10: Arm-Rudern beim freien Fall -----------------------------------
var _arm_flail_phase: float = 0.0
# Sperrt das Rudern, solange die Sieges-Pose (FR-177) die Arme animiert
var _victory_pose_active: bool = false

# --- F06/F07: Landungs-/Aufprall-Partikel -------------------------------
var _impact_fx_cooldown: float = 0.0
const IMPACT_FX_COOLDOWN := 0.25
const IMPACT_MIN_SPEED := 260.0    # unterhalb davon kein sichtbarer Aufprall


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	gravity_scale = level_gravity_scale  # FR-021
	angular_damp = rotation_damping      # FR-033
	body_entered.connect(_on_body_entered)
	_apply_shop_skin()  # FR-224: im Shop gekaufte/ausgerüstete Skin-Farbe übernehmen
	# F01/F02: Alle Körperteile hängen an einem eigenen Node2D, damit sie
	# gestaucht/gestreckt werden können, ohne die Kollisionsform des
	# RigidBody2D mitzuskalieren.
	_visual_root = Node2D.new()
	_visual_root.name = "VisualRoot"
	add_child(_visual_root)
	_build_stick_figure()
	_build_aim_arrow()
	# FR-020: Standard-Kurve initialisieren (linear, falls nicht gesetzt)
	if power_curve.point_count == 0:
		power_curve.add_point(Vector2(0, 0))
		power_curve.add_point(Vector2(1, 1))
		_initialized_curve = true
	# Trail und Speed-Lines nach dem nächsten Frame aufbauen
	call_deferred("_build_trail")
	# FR-100: Manuell ausgelöste Inventar-Power-ups anwenden
	GameManager.inventory_use_requested.connect(_on_inventory_powerup_used)
	# FR-277: Goldene Aura während Doppel-Münzen aktiv sind
	GameManager.double_coins_changed.connect(_on_double_coins_changed)


# ----------------------------------------------------------------
# Pro-Frame-Logik: Cooldown (FR-008), Aufladung (FR-005),
# Regeneration (FR-001)
# ----------------------------------------------------------------
func _process(delta: float) -> void:
	if _is_dead:
		return

	# FR-353: Geister-Rennen — Position periodisch für die Wiedergabe aufzeichnen
	if GameModeManager.active_game_mode == GameModeManager.GameMode.GHOST_RACE:
		_ghost_record_timer += delta
		if _ghost_record_timer >= 0.05:
			_ghost_record_timer = 0.0
			ghost_path_recorded.append(global_position)

	# FR-008: Abklingzeit herunterzählen
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)

	# FR-056: Gepufferte Eingabe auslösen, sobald die Abklingzeit vorbei ist
	if _buffered_fart:
		_buffer_timer -= delta
		if _cooldown_remaining <= 0.0:
			_buffered_fart = false
			_execute_fart(_buffered_dir)
		elif _buffer_timer <= 0.0:
			_buffered_fart = false  # Puffer-Fenster abgelaufen, Eingabe verworfen

	# FR-010: Schild-Timer
	if _shield_remaining > 0.0:
		_shield_remaining = maxf(0.0, _shield_remaining - delta)
		if _shield_remaining == 0.0:
			shield_changed.emit(false)
			_update_shield_aura(false)  # FR-297

	# FR-005: Solange gezielt wird, lädt der Furz auf
	if _is_aiming:
		_aim_hold += delta
		_update_aim_visual()
		# FR-007: Dauerstrahl-Furz — kontinuierlicher Schub beim Halten
		if continuous_thrust_enabled and _aim_hold > 0.2:  # Nach 0.2s kontinuierlich
			_apply_continuous_thrust()

	# FR-001/004: Ladungen/Treibstoff über Zeit regenerieren
	if fuel_mode:
		_current_fuel = minf(_current_fuel + fuel_regen_rate * delta, max_fuel)
	else:
		_process_regen(delta)

	# FR-012: Überhitzungs-Level abkühlen
	_heat_level = maxf(0.0, _heat_level - delta * 0.5)
	_overheat_cooldown = maxf(0.0, _overheat_cooldown - delta)

	# FR-168: Flug-Spur aktualisieren
	_update_trail()
	# FR-264: Geschwindigkeitslinien aktualisieren
	_update_speed_lines()
	# F01/F02: Stauchung/Streckung, F03-F05/F09: Mimik, F06/F07: Aufprall-FX
	_update_squash_stretch(delta)
	_update_expression(delta)
	_update_arm_flail(delta)
	_impact_fx_cooldown = maxf(0.0, _impact_fx_cooldown - delta)


## F10: Beim freien Fall (ohne aktiven Schub, deutlich nach unten fallend)
## rudert das Männchen panisch mit den Armen. Nutzt den bereits für die
## Sieges-Pose vorhandenen _arms-Line2D.
func _update_arm_flail(delta: float) -> void:
	if _arms == null or _is_aiming or _victory_pose_active:
		return
	if AccessibilityManager.reduced_motion_enabled:  # FR-423
		return
	var falling_fast: bool = linear_velocity.y > 450.0
	if not falling_fast:
		# Ruhehaltung wiederherstellen (nur wenn nötig, spart Zuweisungen)
		if _arm_flail_phase != 0.0:
			_arm_flail_phase = 0.0
			_set_arm_points(0.0)
		return
	_arm_flail_phase += delta * 18.0
	_set_arm_points(sin(_arm_flail_phase) * 7.0)


## Setzt die Arm-Punkte mit einem vertikalen Versatz (0 = Ruhehaltung).
func _set_arm_points(offset: float) -> void:
	_arms.clear_points()
	_arms.add_point(Vector2(-16, 6 - offset))
	_arms.add_point(Vector2(0, -10))
	_arms.add_point(Vector2(16, 6 + offset))


## F01/F02: Staucht die Figur direkt nach einem Furz-Stoß und streckt sie
## geschwindigkeitsabhängig in Flugrichtung. Da _visual_root mit dem Körper
## rotiert, entspricht die lokale Y-Achse der Flugrichtung.
func _update_squash_stretch(delta: float) -> void:
	if _visual_root == null:
		return
	_squash = maxf(0.0, _squash - delta * SQUASH_DECAY)
	# FR-423: Bei "reduzierte Bewegung" auf die Verformung verzichten
	if AccessibilityManager.reduced_motion_enabled:
		_visual_root.scale = Vector2.ONE
		return
	var speed_ratio := clampf(linear_velocity.length() / STRETCH_FULL_SPEED, 0.0, 1.0)
	var stretch := speed_ratio * STRETCH_MAX
	var squash_now := _squash * SQUASH_STRENGTH
	# Stauchen: breiter + flacher; Strecken: schmaler + länger
	_visual_root.scale = Vector2(
		1.0 + squash_now - stretch,
		1.0 - squash_now + stretch
	)


## F03/F04/F05/F09: Wählt den Gesichtsausdruck situativ statt nur anhand
## der im Shop gekauften Miene. Reihenfolge = Priorität.
func _update_expression(delta: float) -> void:
	_shock_timer = maxf(0.0, _shock_timer - delta)

	# F09: Blinzeln — nur im ruhigen Zustand, damit es nicht mit den
	# situativen Ausdrücken kollidiert.
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_active = not _blink_active
		_blink_timer = 0.12 if _blink_active else randf_range(2.5, 5.0)

	var wanted := CosmeticsManager.equipped_face  # Standard: Shop-Auswahl
	if _shock_timer > 0.0:
		wanted = "scared"                              # F05: Beinahe-Treffer
	elif linear_velocity.length() > FEAR_SPEED:
		wanted = "scared"                              # F03: Angst bei Tempo
	elif _is_aiming:
		wanted = "focused"                             # F04: Konzentration
	elif _blink_active:
		wanted = "blink"                               # F09

	if wanted != _current_expression:
		_current_expression = wanted
		_render_face(wanted)


## F05: Wird von Main.gd bei einem Beinahe-Treffer aufgerufen — das
## Männchen erschrickt kurz sichtbar.
func react_to_near_miss() -> void:
	_shock_timer = SHOCK_DURATION


## FR-001: Regenerations-Logik (aus _process ausgelagert).
func _process_regen(delta: float) -> void:
	if not charge_regen_enabled or charge_regen_time <= 0.0:
		return
	# Nur nachladen, wenn noch Platz ist
	if GameManager.charges_remaining >= GameManager.max_charges:
		_regen_accum = 0.0
		return

	# FR-305: "Schnellere Regeneration"-Upgrades beschleunigen das Nachladen
	var regen_skill_mult := 1.0 + GameManager.get_skill_effect_level("regen_speed") * 0.15
	_regen_accum += delta * regen_skill_mult
	# Fortschritt der gerade nachladenden Ladung an das HUD melden
	GameManager.set_regen_progress(_regen_accum / charge_regen_time)

	if _regen_accum >= charge_regen_time:
		_regen_accum = 0.0
		GameManager.add_charge()
		GameManager.set_regen_progress(0.0)


## FR-005: Aktueller Aufladegrad (0..1) anhand der Haltedauer.
func _hold_factor() -> float:
	if charge_hold_time <= 0.0:
		return 0.0
	return clampf(_aim_hold / charge_hold_time, 0.0, 1.0)


# ----------------------------------------------------------------
# Touch-Eingabe: Zielen & Furzen
# ----------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	# FR-058: Bildschirm-Sperre während kritischer Aktionen (z.B. Respawn-Übergang)
	if _is_dead or input_locked:
		return

	# FR-055: Multitouch-robust — nur der über _touch_index verfolgte Finger
	# steuert das Zielen; weitere Finger (z.B. für Kamera-Zoom) werden hier
	# ignoriert, da sie weder die _touch_index==-1-Bedingung noch den
	# event.index==_touch_index-Vergleich unten erfüllen.
	# Finger berührt den Bildschirm -> Zielen beginnen
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			# FR-050/057: Doppel-Tipp erkennen (Zeit- UND Ortsschwellwert,
			# damit ein schnelles erneutes Zielen nicht als Neustart zählt)
			var now := Time.get_ticks_msec() / 1000.0
			var close_enough := _last_tap_pos.distance_to(event.position) < 40.0
			if now - _last_tap_time < 0.3 and close_enough:
				died.emit()  # Schnell-Neustart: Tod-Signal senden, Main lädt Level neu
				return
			_last_tap_time = now
			_last_tap_pos = event.position
			_touch_index = event.index
			_is_aiming = true
			_aim_start = event.position
			_aim_current = event.position
			_aim_hold = 0.0  # FR-005: Aufladung neu beginnen
			_update_aim_visual()
			# FR-435: Visuelle Tipp-Bestätigung am Berührungspunkt
			if AccessibilityManager.tap_confirmations_enabled:
				_show_tap_confirmation(event.position)
			# FR-052: Beim Zielen leichte Zeitlupe für Feinjustierung
			if aim_slowmo_enabled and not _aim_slowmo_active:
				_aim_slowmo_active = true
				Engine.time_scale = aim_slowmo_scale
		elif not event.pressed and event.index == _touch_index:
			# Finger losgelassen -> Furz-Stoß auslösen
			_release_fart()
			_touch_index = -1
			_clear_traj_dots()
			# FR-052: Zeitlupe beim Loslassen wieder aufheben
			if _aim_slowmo_active:
				_aim_slowmo_active = false
				Engine.time_scale = 1.0

	# Finger zieht über den Bildschirm -> Zielrichtung aktualisieren
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_aim_current = event.position
		_update_aim_visual()


## FR-044: Effektive maximale Ziehweite unter Berücksichtigung der Sensitivität.
func _effective_max_drag() -> float:
	return max_drag_distance / maxf(0.1, GameManager.touch_sensitivity)


## FR-042: Liefert die Zielrichtung passend zum gewählten Steuerschema.
## "direct" (Standard) = Stoß in Zugrichtung, "slingshot" = entgegengesetzt.
func _scheme_direction(drag: Vector2) -> Vector2:
	var dir := drag.normalized()
	if GameManager.control_scheme == "slingshot":
		return -dir
	return dir


## Aktualisiert den Zielpfeil und sendet das aim_changed-Signal.
func _update_aim_visual() -> void:
	var drag := _aim_current - _aim_start
	var strength := clampf(drag.length() / _effective_max_drag(), 0.0, 1.0)
	var dir := _scheme_direction(drag)
	# FR-053/427: Auto-Aim bzw. globaler Assist-Modus — suche nächstes Ziel
	# bei kurzen Zügen (Assist-Modus nutzt einen großzügigeren Schwellwert)
	var auto_aim_active := auto_aim_enabled or AccessibilityManager.assist_aim_enabled
	var auto_aim_threshold := 0.45 if AccessibilityManager.assist_aim_enabled else 0.3
	if auto_aim_active and drag.length() < _effective_max_drag() * auto_aim_threshold:
		var target_dir := _find_nearest_target()
		if target_dir != Vector2.ZERO:
			dir = target_dir
	_draw_aim_arrow(dir, strength)
	# FR-005/175: Pfeil-Farbe je nach Aufladung und gewähltem Pfeil-Design
	var charge := _hold_factor()
	_aim_arrow.default_color = _aim_arrow_color(charge)
	_aim_arrow.width = 8.0 + charge * 8.0
	aim_changed.emit(dir, strength)
	# FR-048: Flugbahn-Vorschau zeichnen
	_update_traj_preview(dir, strength, charge)


## Löst den Furz-Stoß aus: je nach Furz-Typ Impuls(e) + Partikel + Sound.
func _release_fart() -> void:
	_is_aiming = false
	_aim_arrow.visible = false
	_clear_traj_dots()
	aim_released.emit()

	var drag := _aim_current - _aim_start
	# Zu kurzes Ziehen ignorieren (versehentliche Tipper) — FR-044 Dead-Zone
	if drag.length() < GameManager.touch_dead_zone:
		return

	# FR-012: Überhitzt? Dann kein Stoß möglich bis abgekühlt (kein Puffern)
	if _heat_level >= 1.0 and _overheat_cooldown > 0.0:
		return

	# FR-008/056: Noch in der Abklingzeit? Eingabe kurz puffern statt verwerfen,
	# damit ein knapp zu früher Stoß trotzdem reaktionsschnell ausgelöst wird.
	if _cooldown_remaining > 0.0:
		_buffered_fart = true
		_buffered_dir = drag
		_buffer_timer = input_buffer_window
		return

	_execute_fart(drag)


## FR-056: Führt den eigentlichen Furz-Stoß aus (aus _release_fart ausgelagert,
## damit gepufferte Eingaben in _process denselben Code nutzen können).
func _execute_fart(drag: Vector2) -> void:
	var fart: Dictionary = FART_TYPES[_fart_type_index]

	# FR-004: Im Treibstoff-Modus Energie verbrauchen statt Ladungen
	if fuel_mode:
		var fuel_cost := fart["cost"] * 20.0  # Ein "Punkt" = 20 Treibstoff
		if _current_fuel < fuel_cost:
			return
		_current_fuel -= fuel_cost
	else:
		# Genug Ladungen für diesen Furz-Typ vorhanden?
		if not GameManager.use_charges(fart["cost"]):
			return

	# FR-005: Haltedauer erhöht den Schub zusätzlich
	var charge_mult := 1.0 + _hold_factor() * charge_hold_bonus
	var strength := clampf(drag.length() / _effective_max_drag(), 0.0, 1.0)
	var dir := _scheme_direction(drag)
	# FR-009: Winkel-Präzisions-Bonus — perfekte Winkel bekommen Schub-Bonus
	var precision_mult := _calculate_precision_bonus(dir)
	# FR-020: Anpassbare Furz-Schubkurve anwenden (Kurven-Mapping)
	var curve_factor := power_curve.sample(strength)
	# FR-305: Permanente "Stärkerer Furz"-Upgrades erhöhen den Basis-Impuls
	var skill_mult := 1.0 + GameManager.get_skill_effect_level("fart_power") * 0.08
	var impulse: float = fart_power * curve_factor * fart["power"] * charge_mult * precision_mult * skill_mult
	var bursts: int = fart["bursts"]
	var tint: Color = fart["color"]

	# FR-008: Abklingzeit starten, FR-045: kurze Vibration
	_cooldown_remaining = fart_cooldown
	GameManager.vibrate(40)
	GameManager.record_fart()  # FR-226: Statistik
	SoundManager.play_fart_sound(strength)  # FR-165
	AccessibilityManager.show_sound_caption(tr("caption_fart"))  # FR-425

	# FR-012: Überhitzungs-Level erhöhen (Mega-Furz = mehr Hitze)
	_heat_level += (fart["power"] * 0.25)
	if _heat_level >= 1.0:
		_heat_level = 1.0
		_overheat_cooldown = 2.0  # 2 Sekunden nicht furzen können
		GameManager.vibrate(100)  # Intensive Vibration bei Überhitzung

	# Ersten Stoß sofort auslösen
	_do_thrust(dir, impulse, tint)

	# Doppel-Stoß: weitere Stöße kurz versetzt nachfeuern
	for i in range(bursts - 1):
		if _is_dead:
			return
		await get_tree().create_timer(0.12).timeout
		# Nach der Wartezeit erneut prüfen (Szene könnte neu geladen sein)
		if not is_instance_valid(self) or _is_dead:
			return
		_do_thrust(dir, impulse * 0.85, tint)


## FR-009: Berechnet den Präzisions-Bonus für einen gegebenen Zielwinkel.
## Perfekte Winkel (Kardinalrichtungen) erhalten bis zu 1.5x Bonus.
func _calculate_precision_bonus(dir: Vector2) -> float:
	var angle := dir.angle()
	angle = fmod(angle + TAU, TAU)
	var perfect_angles := [0.0, PI * 0.5, PI, PI * 1.5]
	var min_angle_diff := PI
	for perfect in perfect_angles:
		var diff := abs(angle - perfect)
		if diff > PI:
			diff = TAU - diff
		min_angle_diff = minf(min_angle_diff, diff)
	# FR-355: Präzisions-Modus verschärft die Toleranz und bestraft
	# ungenaue Stöße zusätzlich mit einem Malus statt nur den Bonus zu entziehen
	var precision_mode := GameModeManager.active_game_mode == GameModeManager.GameMode.PRECISION
	var tolerance := PI * 0.05 if precision_mode else PI * 0.15
	var off_angle := clampf(min_angle_diff / tolerance, 0.0, 1.0)
	var bonus := (1.0 - off_angle) * 0.5
	if precision_mode:
		return 1.0 + bonus - off_angle * 0.3
	return 1.0 + bonus


## FR-053: Findet das nächste Ziel im Auto-Aim-Modus.
func _find_nearest_target() -> Vector2:
	var nearest_dist := auto_aim_radius
	var nearest_dir := Vector2.ZERO
	# Suche nach Münzen, Sternen und anderen Sammelobjekten
	for coin in get_tree().get_nodes_in_group("coins"):
		if coin.has_method("_collected") and coin._collected:
			continue
		var dist := global_position.distance_to(coin.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_dir = (coin.global_position - global_position).normalized()
	return nearest_dir


## FR-007: Kontinuierlicher Schub beim Zielen (Dauerstrahl-Furz).
func _apply_continuous_thrust() -> void:
	var drag := _aim_current - _aim_start
	if drag.length() < GameManager.touch_dead_zone:
		return
	var dir := _scheme_direction(drag)
	if fuel_mode:
		var fuel_cost := continuous_thrust_cost * get_physics_process_delta_time()
		if _current_fuel < fuel_cost:
			return
		_current_fuel -= fuel_cost
	apply_central_impulse(dir * continuous_thrust_power * get_physics_process_delta_time())


## Wendet einen einzelnen Schub an und erzeugt die passende Furz-Wolke.
func _do_thrust(dir: Vector2, impulse: float, tint: Color) -> void:
	apply_central_impulse(dir * impulse)
	# FR-006: Seitlicher Drall — Schub senkrecht zur Bewegungsrichtung dreht das Männchen
	var current_vel := linear_velocity
	if current_vel.length() > 80.0:
		var side_component := dir - dir.project(current_vel.normalized())
		if side_component.length() > 0.1:
			apply_torque_impulse(side_component.x * impulse * 0.008)
	fart_fired.emit(impulse, dir)  # FR-265/192: Kamera-Wackeln/-Stoß signalisieren
	_squash = 1.0  # F01: Stauchung im Moment des Stoßes auslösen
	_spawn_fart_burst(-dir, _apply_fart_color_style(tint))
	# FR-115: Nahe Gegner in der Gruppe "blowable" werden vom Furz weggeblasen
	_blow_away_nearby_enemies(-dir, impulse)


## FR-164: Überschreibt die Furz-Wolken-Farbe je nach ausgerüstetem Stil.
func _apply_fart_color_style(base_tint: Color) -> Color:
	match CosmeticsManager.equipped_fart_color_style:
		"fart_toxic":
			return Color(0.4, 1.0, 0.2)
		"fart_rainbow":
			var hue := fmod(Time.get_ticks_msec() * 0.0008, 1.0)
			return Color.from_hsv(hue, 0.8, 1.0)
		_:
			return base_tint


# FR-461: Pool wiederverwendbarer FartBurst-Instanzen — vermeidet
# instantiate()/queue_free()-Churn bei schnellem Furz-Feuer (Combo-System
# erlaubt Stöße im Sekundenbruchteil-Abstand), analog zum bestehenden
# AudioStreamPlayer-Pool-Muster (z.B. SoundManager._get_free_stinger_player()).
var _fart_burst_pool: Array[FartBurst] = []
const FART_BURST_POOL_SIZE := 6


## Erzeugt die FartBurst-Szene (eingefärbte Partikelwolke) hinter dem Männchen.
func _spawn_fart_burst(back_dir: Vector2, tint: Color = Color.WHITE) -> void:
	if fart_burst_scene == null:
		return
	var burst := _get_free_fart_burst()
	if burst == null:
		return
	burst.global_position = global_position + back_dir * 30.0
	# Partikel in die Furz-Richtung ausrichten
	burst.rotation = back_dir.angle()
	burst.erupt(tint)


func _get_free_fart_burst() -> FartBurst:
	for b in _fart_burst_pool:
		if is_instance_valid(b) and not b.is_active:
			return b
	if _fart_burst_pool.size() < FART_BURST_POOL_SIZE:
		var new_burst := fart_burst_scene.instantiate() as FartBurst
		get_parent().add_child(new_burst)
		_fart_burst_pool.append(new_burst)
		return new_burst
	return _fart_burst_pool[0]  # Pool voll: älteste Instanz wiederverwenden


## FR-115: Schiebt nahe Gegner der Gruppe "blowable" vom Furz-Ausstoß weg.
func _blow_away_nearby_enemies(blast_dir: Vector2, impulse: float) -> void:
	const BLAST_RADIUS := 220.0
	for enemy in get_tree().get_nodes_in_group("blowable"):
		if not is_instance_valid(enemy) or not (enemy is Node2D):
			continue
		var to_enemy: Vector2 = enemy.global_position - global_position
		var dist := to_enemy.length()
		if dist > BLAST_RADIUS or dist < 1.0:
			continue
		var falloff := 1.0 - (dist / BLAST_RADIUS)
		var push_dir := to_enemy.normalized()
		var push_force := push_dir * impulse * falloff * 0.6
		if enemy.has_method("apply_fart_push"):
			enemy.apply_fart_push(push_force)


# --- FR-002: Öffentliche Schnittstelle für die Furz-Typ-Auswahl -
## Liefert die Liste der verfügbaren Furz-Typen (für das HUD).
func get_fart_types() -> Array:
	return FART_TYPES


## Liefert den Index des aktuell aktiven Furz-Typs.
func get_fart_type_index() -> int:
	return _fart_type_index


## Setzt den aktiven Furz-Typ (vom HUD aufgerufen).
func set_fart_type(index: int) -> void:
	if index < 0 or index >= FART_TYPES.size():
		return
	_fart_type_index = index
	fart_type_changed.emit(_fart_type_index)


# ----------------------------------------------------------------
# Physik: Rotation passend zur Flugrichtung
# ----------------------------------------------------------------
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _is_dead:
		return
	var vel := state.linear_velocity

	# FR-039: Realistische Luftreibung (optional, statt standard linear_damp)
	if realistic_drag_enabled:
		var speed := vel.length()
		if speed > 0.1:
			# Aerodynamischer Widerstand: F = 0.5 * ρ * v² * Cd * A
			var drag_force := 0.5 * air_density * (speed * speed) * drag_coefficient * reference_area
			var drag_accel := -drag_force / mass * vel.normalized()
			state.linear_velocity += drag_accel * state.step

	# FR-032: Maximale Fluggeschwindigkeit begrenzen
	if vel.length() > max_speed:
		state.linear_velocity = vel.normalized() * max_speed
		vel = state.linear_velocity
	if vel.length() > 60.0:
		# Kopf zeigt in Flugrichtung (Figur ist standardmäßig "Kopf oben")
		var target_rot := vel.angle() + PI * 0.5
		var current_rot := state.transform.get_rotation()
		var new_rot := lerp_angle(current_rot, target_rot, 0.12)
		state.transform = Transform2D(new_rot, state.transform.origin)


# ----------------------------------------------------------------
# Kollision mit Hindernissen -> Tod / Level-Neustart
# ----------------------------------------------------------------
func _on_body_entered(body: Node) -> void:
	if _is_dead:
		return
	# F06/F07: Aufprall-Partikel bei jeder harten Berührung (Boden, Wände,
	# Plattformen) — bislang gab es Partikel nur beim Tod.
	_spawn_impact_fx()
	if body.is_in_group("obstacles"):
		# FR-345: Im Zen-Modus ist der Spieler unverwundbar — abprallen statt sterben
		if GameModeManager.active_game_mode == GameModeManager.GameMode.ZEN:
			apply_central_impulse(-linear_velocity.normalized() * 200.0)
			GameManager.vibrate(20)
			return
		# FR-010: Schild absorbiert den ersten Treffer
		if _shield_remaining > 0.0:
			_shield_remaining = 0.0
			shield_changed.emit(false)
			_update_shield_aura(false)  # FR-297
			GameManager.vibrate(60)
			took_hit_this_run = true  # FR-325: kein "Perfekt-Lauf" mehr möglich
			return
		_die()


## FR-010: Aktiviert den Furz-Schild für `duration` Sekunden.
func activate_shield(duration: float) -> void:
	# FR-305/437: "Längerer Schild"-Upgrades und Schwierigkeits-Assist
	# verlängern die Schild-Dauer
	var skill_bonus := 1.0 + GameManager.get_skill_effect_level("shield_duration") * 0.2
	if AccessibilityManager.difficulty_assist_enabled:
		skill_bonus += 0.3
	_shield_remaining = duration * skill_bonus
	shield_changed.emit(true)
	GameManager.vibrate(30)
	_update_shield_aura(true)  # FR-297: Schild-Energie-Shader-Aura einblenden


## FR-297: Baut/zeigt die Schild-Aura mit dem Energie-Shader um den Spieler.
func _update_shield_aura(active: bool) -> void:
	if not is_instance_valid(_shield_aura):
		_shield_aura = Polygon2D.new()
		_shield_aura.name = "ShieldAura"
		var pts := PackedVector2Array()
		var uv_pts := PackedVector2Array()
		for i in range(20):
			var a := TAU * float(i) / 20.0
			pts.append(Vector2(cos(a), sin(a)) * 42.0)
			# FR-297: 0..1-UV-Mapping für den Shield-Shader (erwartet UV im
			# 0..1-Raum, nicht die rohen Vertex-Koordinaten).
			uv_pts.append(Vector2(cos(a), sin(a)) * 0.5 + Vector2(0.5, 0.5))
		_shield_aura.polygon = pts
		_shield_aura.uv = uv_pts
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/shield_energy.gdshader")
		mat.set_shader_parameter("shield_color", Color(0.3, 0.7, 1.0, 0.4))
		_shield_aura.material = mat
		add_child(_shield_aura)
	_shield_aura.visible = active


## FR-277: Reagiert auf GameManager.double_coins_changed — goldene Aura
## während der Doppel-Münzen-Phase.
func _on_double_coins_changed(active: bool) -> void:
	_toggle_powerup_aura(active, Color(1.0, 0.85, 0.2, 0.6))


## FR-277: Öffentliche Schnittstelle für zeitlich befristete Power-up-Auren
## (z.B. Münz-Magnet). Mehrere Auren können sich überlappen; die Aura
## bleibt sichtbar, solange mindestens eine noch aktiv ist (vereinfachtes
## Referenzzählungs-Modell statt einer pro Power-up-Typ eigenen Aura).
func show_powerup_aura(color: Color, duration: float) -> void:
	_toggle_powerup_aura(true, color)
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(self):
		_toggle_powerup_aura(false, color)


func _toggle_powerup_aura(active: bool, color: Color) -> void:
	if not is_instance_valid(_powerup_aura):
		_build_powerup_aura()
	_powerup_aura_count = maxi(0, _powerup_aura_count + (1 if active else -1))
	_powerup_aura.default_color = color
	_powerup_aura.visible = _powerup_aura_count > 0


func _build_powerup_aura() -> void:
	_powerup_aura = Line2D.new()
	_powerup_aura.name = "PowerupAura"
	var pts := PackedVector2Array()
	for i in range(25):
		var a := TAU * float(i) / 24.0
		pts.append(Vector2(cos(a), sin(a)) * 38.0)
	_powerup_aura.points = pts
	_powerup_aura.width = 4.0
	_powerup_aura.visible = false
	add_child(_powerup_aura)
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_powerup_aura, "scale", Vector2(1.15, 1.15), 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_powerup_aura, "scale", Vector2(0.92, 0.92), 0.6).set_trans(Tween.TRANS_SINE)


## FR-100: Wendet ein aus dem Inventar manuell ausgelöstes Power-up an.
func _on_inventory_powerup_used(powerup_type: String) -> void:
	if _is_dead:
		return
	match powerup_type:
		"shield":
			activate_shield(6.0)
		"slowmo":
			Engine.time_scale = 0.4
			get_tree().create_timer(3.0, false, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
		"double_coins":
			GameManager.activate_double_coins(8.0)


## Lustige Tod-Animation: das Männchen wirbelt herum, dann Signal "died".
func _die() -> void:
	_is_dead = true
	_aim_arrow.visible = false
	GameManager.vibrate(120)  # FR-045: kräftige Vibration beim Tod
	# FR-266: Hit-Stop – kurzes Einfrieren beim Aufprall
	Engine.time_scale = 0.0
	await get_tree().create_timer(0.08, false, false, true).timeout
	Engine.time_scale = 1.0
	# FR-262: Crash-Partikel-Explosion
	_spawn_crash_particles()
	# FR-040: Ragdoll-Modus aktivieren (Figur wird zur Puppe)
	_activate_ragdoll()
	# Letzten Furz als "Ohnmacht" ausstoßen
	_spawn_fart_burst(Vector2.DOWN)
	# Kurze Verzögerung, damit man die Animation sieht
	await get_tree().create_timer(0.9).timeout
	died.emit()


## FR-040/176: Ragdoll-Modus aktivieren — Verhalten je nach gewählter
## Tod-Animation (CosmeticsManager.equipped_death_anim).
func _activate_ragdoll() -> void:
	_ragdoll_active = true
	match CosmeticsManager.equipped_death_anim:
		"death_confetti":
			gravity_scale = 1.0
			angular_velocity = randf_range(-15.0, 15.0)
			linear_damp = 0.5
			apply_central_impulse(Vector2(randf_range(-200, 200), -300))
			_spawn_confetti_burst()
		"death_ghost":
			gravity_scale = 0.05
			linear_damp = 3.0
			angular_velocity = randf_range(-3.0, 3.0)
			apply_central_impulse(Vector2(randf_range(-60, 60), -180))
			_dissolve_visual()  # FR-298: Dissolve-Shader statt einfacher Alpha-Blende
		_:  # "death_spin" (Standard)
			gravity_scale = 1.0
			angular_velocity = randf_range(-15.0, 15.0)
			linear_damp = 0.5
			apply_central_impulse(Vector2(randf_range(-200, 200), -300))


## FR-176: Bunter Partikel-Burst für die "Konfetti-Explosion"-Tod-Animation.
func _spawn_confetti_burst() -> void:
	var p := CPUParticles2D.new()
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.amount = 30
	p.lifetime = 0.8
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 150.0
	p.initial_velocity_max = 400.0
	p.color = Color(randf(), randf(), randf())
	get_tree().create_timer(0.9).timeout.connect(func(): if is_instance_valid(p): p.queue_free())


## FR-298: Wendet den Dissolve-Shader auf alle sichtbaren Körperteile an
## und blendet das Männchen darüber auf (statt einer einfachen Alpha-Blende).
func _dissolve_visual() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/dissolve.gdshader")
	mat.set_shader_parameter("dissolve_amount", 0.0)
	for child in get_children():
		if child is CanvasItem:
			child.material = mat
	var tween := create_tween()
	tween.tween_method(func(v): mat.set_shader_parameter("dissolve_amount", v), 0.0, 1.0, 0.9)


## FR-435: Kurzer, sich ausdehnender Ring am Berührungspunkt (Bildschirm-
## Koordinaten) als visuelle Bestätigung, dass die Eingabe registriert wurde.
func _show_tap_confirmation(screen_pos: Vector2) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 95
	tree.root.add_child(layer)
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = Color(1.0, 1.0, 1.0, 0.8)
	ring.position = screen_pos
	var pts := PackedVector2Array()
	for i in range(17):
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a), sin(a)) * 10.0)
	ring.points = pts
	layer.add_child(ring)
	var tween := tree.create_tween()
	tween.tween_property(ring, "scale", Vector2(2.5, 2.5), 0.3)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.3)
	tween.tween_callback(layer.queue_free)


## FR-262: Partikel-Explosion beim Aufprall.
func _spawn_crash_particles() -> void:
	var p := CPUParticles2D.new()
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 30
	p.lifetime = 0.9
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 340.0
	p.gravity = Vector2(0, 500)
	p.scale_amount_min = 4.0
	p.scale_amount_max = 9.0
	p.color = Color(1.0, 0.5, 0.15)
	get_tree().create_timer(1.1).timeout.connect(
		func() -> void:
			if is_instance_valid(p):
				p.queue_free()
	)


## F06/F07: Kurze Staub-/Funken-Wolke am Aufprallpunkt. Nur bei spürbarem
## Tempo und mit Abklingzeit, damit rollende Dauerkontakte keine
## Partikel-Flut auslösen.
func _spawn_impact_fx() -> void:
	if _impact_fx_cooldown > 0.0:
		return
	var speed := linear_velocity.length()
	if speed < IMPACT_MIN_SPEED:
		return
	if AccessibilityManager.reduced_motion_enabled:  # FR-423
		return
	_impact_fx_cooldown = IMPACT_FX_COOLDOWN
	var p := CPUParticles2D.new()
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.9
	# FR-466: Partikelmenge folgt der eingestellten Grafikqualität
	p.amount = GameManager.scaled_particle_amount(12)
	p.lifetime = 0.45
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 60.0 + minf(speed * 0.15, 160.0)
	p.spread = 70.0
	# Partikel weg von der Aufprallrichtung streuen
	p.direction = -linear_velocity.normalized() if speed > 0.0 else Vector2.UP
	p.gravity = Vector2(0, 220)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	p.color = Color(0.75, 0.72, 0.65, 0.7)  # staubiges Grau-Beige
	get_tree().create_timer(0.7).timeout.connect(
		func() -> void:
			if is_instance_valid(p):
				p.queue_free()
	)


## FR-224/180: Übernimmt die im Shop ausgerüstete Skin-Farbe (falls nicht
## Standard) oder die frei gewählte Farbe aus dem Farb-Editor.
func _apply_shop_skin() -> void:
	if CosmeticsManager.active_skin_color == "default":
		return
	if CosmeticsManager.active_skin_color == "custom":
		skin_color = CosmeticsManager.custom_skin_color
		return
	for offer in ShopScreen.SKIN_OFFERS:
		if offer["id"] == CosmeticsManager.active_skin_color:
			skin_color = offer["color"]
			return


# ----------------------------------------------------------------
# Aufbau der Grafik: Strichmännchen mit Helm (per Line2D)
# ----------------------------------------------------------------
func _build_stick_figure() -> void:
	var col := skin_color  # FR-162: konfigurierbare Maennchen-Farbe
	var head_center := Vector2(0, -34)
	var head_radius := 16.0

	# FR-161: Helm-Design (abhängig von CosmeticsManager.equipped_helmet)
	_build_helmet(head_center, head_radius)

	# Körper (Torso)
	var torso := Line2D.new()
	torso.name = "Torso"
	torso.width = 5.0
	torso.default_color = col
	torso.add_point(Vector2(0, -18))
	torso.add_point(Vector2(0, 18))
	_add_visual(torso)

	# Arme
	_arms = Line2D.new()
	_arms.name = "Arms"
	_arms.width = 5.0
	_arms.default_color = col
	_arms.add_point(Vector2(-16, 6))
	_arms.add_point(Vector2(0, -10))
	_arms.add_point(Vector2(16, 6))
	_add_visual(_arms)

	# Beine
	var legs := Line2D.new()
	legs.name = "Legs"
	legs.width = 5.0
	legs.default_color = col
	legs.add_point(Vector2(-14, 40))
	legs.add_point(Vector2(0, 18))
	legs.add_point(Vector2(14, 40))
	_add_visual(legs)

	# FR-163: Kostüm-Overlay (Astronaut/Superheld/Tier)
	_build_outfit(head_center, head_radius)
	# FR-166: Hut/Accessoire (über dem Helm)
	_build_hat(head_center, head_radius)
	# FR-167: Gesichtsausdruck
	_build_face(head_center)
	# FR-296: 2D-Beleuchtung — sanftes Glühen um den Spieler
	_build_player_light()


## FR-296: Fügt ein PointLight2D hinzu, das das Männchen sanft beleuchtet
## (nutzt Godots eingebautes 2D-Beleuchtungssystem).
func _build_player_light() -> void:
	var light := PointLight2D.new()
	light.name = "PlayerGlow"
	light.energy = 0.6
	light.texture_scale = 4.0
	light.color = Color(1.0, 0.95, 0.8)
	light.range_item_cull_mask = 1
	# Prozedurale weiche Kreis-Textur als Licht-Textur (Radial-Gradient)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = gradient
	grad_tex.width = 128
	grad_tex.height = 128
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(1.0, 0.5)
	light.texture = grad_tex
	add_child(light)


## FR-161: Zeichnet das gewählte Helm-Design.
func _build_helmet(head_center: Vector2, radius: float) -> void:
	var style := CosmeticsManager.equipped_helmet
	if style == "helmet_none":
		return

	var helmet := Line2D.new()
	helmet.name = "Helmet"
	helmet.width = 4.0
	helmet.closed = true
	var segments := 16

	match style:
		"helmet_viking":
			helmet.default_color = Color(0.6, 0.6, 0.65)
			for i in range(segments):
				var a := TAU * float(i) / float(segments)
				helmet.add_point(head_center + Vector2(cos(a), sin(a)) * radius)
			_add_visual(helmet)
			for side in [-1, 1]:
				var horn := Line2D.new()
				horn.width = 3.0
				horn.default_color = Color(0.9, 0.85, 0.7)
				horn.add_point(head_center + Vector2(side * radius * 0.6, -radius * 0.3))
				horn.add_point(head_center + Vector2(side * radius * 1.6, -radius * 1.4))
				_add_visual(horn)
		"helmet_mohawk":
			helmet.default_color = Color(0.5, 0.5, 0.55)
			for i in range(segments):
				var a := TAU * float(i) / float(segments)
				helmet.add_point(head_center + Vector2(cos(a), sin(a)) * radius)
			_add_visual(helmet)
			var mohawk := Polygon2D.new()
			mohawk.color = Color(0.9, 0.2, 0.5)
			mohawk.polygon = PackedVector2Array([
				head_center + Vector2(-4, -radius), head_center + Vector2(4, -radius),
				head_center + Vector2(0, -radius * 2.2),
			])
			_add_visual(mohawk)
		"helmet_crown":
			helmet.default_color = Color(1.0, 0.85, 0.2)
			for i in range(segments):
				var a := TAU * float(i) / float(segments)
				helmet.add_point(head_center + Vector2(cos(a), sin(a)) * radius)
			_add_visual(helmet)
			var crown := Polygon2D.new()
			crown.color = Color(1.0, 0.85, 0.2)
			var pts := PackedVector2Array()
			for i in range(5):
				var x := -radius + i * (radius * 2.0 / 4.0)
				pts.append(head_center + Vector2(x, -radius * (1.6 if i % 2 == 0 else 1.1)))
			pts.append(head_center + Vector2(radius, -radius))
			pts.append(head_center + Vector2(-radius, -radius))
			crown.polygon = pts
			_add_visual(crown)
		_:  # "helmet_visor" und Fallback
			helmet.default_color = Color(0.55, 0.85, 1.0)
			for i in range(segments):
				var a := TAU * float(i) / float(segments)
				helmet.add_point(head_center + Vector2(cos(a), sin(a)) * radius)
			_add_visual(helmet)
			var visor := Line2D.new()
			visor.width = 3.0
			visor.default_color = Color(0.2, 0.5, 0.8, 0.8)
			visor.add_point(head_center + Vector2(-radius * 0.7, 0))
			visor.add_point(head_center + Vector2(radius * 0.7, 0))
			_add_visual(visor)


## FR-163: Zeichnet das gewählte Kostüm-Overlay.
func _build_outfit(head_center: Vector2, head_radius: float) -> void:
	match CosmeticsManager.equipped_outfit:
		"outfit_astronaut":
			var suit := Polygon2D.new()
			suit.color = Color(0.9, 0.9, 0.95, 0.85)
			suit.polygon = PackedVector2Array([
				Vector2(-10, -18), Vector2(10, -18), Vector2(12, 18), Vector2(-12, 18),
			])
			_add_visual(suit)
			var backpack := ColorRect.new()
			backpack.size = Vector2(10, 20)
			backpack.position = Vector2(-5, -8)
			backpack.color = Color(0.7, 0.7, 0.75)
			_add_visual(backpack)
		"outfit_hero":
			var cape := Polygon2D.new()
			cape.color = Color(0.8, 0.1, 0.1, 0.85)
			cape.z_index = -1
			cape.polygon = PackedVector2Array([
				Vector2(-8, -14), Vector2(8, -14), Vector2(14, 30), Vector2(-14, 30),
			])
			_add_visual(cape)
			var emblem := Polygon2D.new()
			emblem.color = Color(1.0, 0.85, 0.2)
			emblem.polygon = PackedVector2Array([
				Vector2(0, -6), Vector2(5, 0), Vector2(0, 6), Vector2(-5, 0),
			])
			_add_visual(emblem)
		"outfit_animal":
			for side in [-1, 1]:
				var ear := Polygon2D.new()
				ear.color = skin_color.darkened(0.2)
				ear.polygon = PackedVector2Array([
					head_center + Vector2(side * head_radius * 0.5, -head_radius),
					head_center + Vector2(side * head_radius * 1.1, -head_radius * 1.8),
					head_center + Vector2(side * head_radius * 0.1, -head_radius * 1.3),
				])
				_add_visual(ear)
			var tail := Line2D.new()
			tail.width = 4.0
			tail.default_color = skin_color.darkened(0.2)
			tail.add_point(Vector2(-4, 30))
			tail.add_point(Vector2(-16, 20))
			tail.add_point(Vector2(-14, 34))
			_add_visual(tail)


## FR-166: Zeichnet ein Hut-Accessoire über dem Helm.
func _build_hat(head_center: Vector2, head_radius: float) -> void:
	match CosmeticsManager.equipped_hat:
		"hat_top":
			var brim := ColorRect.new()
			brim.size = Vector2(head_radius * 2.2, 4)
			brim.position = head_center + Vector2(-head_radius * 1.1, -head_radius * 1.3)
			brim.color = Color(0.1, 0.1, 0.12)
			_add_visual(brim)
			var top := ColorRect.new()
			top.size = Vector2(head_radius * 1.1, head_radius * 1.2)
			top.position = head_center + Vector2(-head_radius * 0.55, -head_radius * 2.5)
			top.color = Color(0.1, 0.1, 0.12)
			_add_visual(top)
		"hat_cap":
			var cap := Polygon2D.new()
			cap.color = Color(0.2, 0.5, 0.8)
			var pts := PackedVector2Array()
			for i in range(10):
				var a := PI + TAU * 0.5 * float(i) / 9.0
				pts.append(head_center + Vector2(cos(a), sin(a)) * head_radius * 1.05)
			cap.polygon = pts
			_add_visual(cap)
			var brim := Polygon2D.new()
			brim.color = Color(0.15, 0.4, 0.65)
			brim.polygon = PackedVector2Array([
				head_center + Vector2(0, -head_radius * 0.2),
				head_center + Vector2(head_radius * 1.4, -head_radius * 0.1),
				head_center + Vector2(head_radius * 1.2, head_radius * 0.15),
			])
			_add_visual(brim)
		"hat_shades":
			var shades := ColorRect.new()
			shades.size = Vector2(head_radius * 1.6, 6)
			shades.position = head_center + Vector2(-head_radius * 0.8, -3)
			shades.color = Color(0.05, 0.05, 0.05, 0.9)
			_add_visual(shades)
		"hat_crown":
			# FR-334: Erfolgs-Belohnung für "Sternensammler" (alle Level 3 Sterne)
			var crown := Polygon2D.new()
			crown.color = Color(1.0, 0.85, 0.15)
			var base_offset := -head_radius * 1.15
			var cw := head_radius * 1.1
			crown.polygon = PackedVector2Array([
				head_center + Vector2(-cw, base_offset),
				head_center + Vector2(-cw, base_offset - head_radius * 0.5),
				head_center + Vector2(-cw * 0.5, base_offset - head_radius * 0.15),
				head_center + Vector2(0, base_offset - head_radius * 0.65),
				head_center + Vector2(cw * 0.5, base_offset - head_radius * 0.15),
				head_center + Vector2(cw, base_offset - head_radius * 0.5),
				head_center + Vector2(cw, base_offset),
			])
			_add_visual(crown)
			var jewel := Polygon2D.new()
			jewel.color = Color(0.9, 0.15, 0.2)
			var jewel_center := head_center + Vector2(0, base_offset - head_radius * 0.35)
			var jpts := PackedVector2Array()
			for i in range(8):
				var a := TAU * float(i) / 8.0
				jpts.append(jewel_center + Vector2(cos(a), sin(a)) * head_radius * 0.12)
			jewel.polygon = jpts
			_add_visual(jewel)


## FR-167: Zeichnet einen Gesichtsausdruck (aktualisierbar via set_face_expression).
func _build_face(head_center: Vector2) -> void:
	_face_node = Node2D.new()
	_face_node.position = head_center
	_add_visual(_face_node)
	_render_face(CosmeticsManager.equipped_face)


## FR-167 + F03/F04/F05/F09: Zeichnet Augen und Mund für einen Ausdruck.
## "focused"/"blink" ergänzen die bisherigen Shop-Mienen und werden
## situativ von _update_expression() gesetzt.
func _render_face(expression: String) -> void:
	if _face_node == null:
		return
	for child in _face_node.get_children():
		child.queue_free()

	var ink := Color(0.2, 0.1, 0.1)

	# --- Augen ---
	match expression:
		"blink":
			# Geschlossene Augen: zwei kurze waagerechte Striche
			for side in [-1.0, 1.0]:
				var lid := Line2D.new()
				lid.width = 2.0
				lid.default_color = ink
				lid.add_point(Vector2(side * 6.0 - 3.0, -4))
				lid.add_point(Vector2(side * 6.0 + 3.0, -4))
				_face_node.add_child(lid)
		"scared":
			# Weit aufgerissene Augen
			for side in [-1.0, 1.0]:
				var eye := _make_eye(Vector2(side * 6.0, -4), 3.5, ink)
				_face_node.add_child(eye)
		"focused":
			# Zusammengekniffene Augen + Konzentrations-Brauen
			for side in [-1.0, 1.0]:
				var eye := _make_eye(Vector2(side * 6.0, -4), 1.8, ink)
				_face_node.add_child(eye)
				var brow := Line2D.new()
				brow.width = 2.0
				brow.default_color = ink
				brow.add_point(Vector2(side * 6.0 - 3.5, -9))
				brow.add_point(Vector2(side * 6.0 + 3.5, -7))
				_face_node.add_child(brow)
		_:
			for side in [-1.0, 1.0]:
				var eye := _make_eye(Vector2(side * 6.0, -4), 2.4, ink)
				_face_node.add_child(eye)

	# --- Mund ---
	var mouth := Line2D.new()
	mouth.width = 2.0
	mouth.default_color = ink
	match expression:
		"happy":
			mouth.add_point(Vector2(-5, 6))
			mouth.add_point(Vector2(0, 9))
			mouth.add_point(Vector2(5, 6))
		"scared":
			# Offener Schreck-Mund (kleines O)
			mouth.add_point(Vector2(-3, 6))
			mouth.add_point(Vector2(0, 10))
			mouth.add_point(Vector2(3, 6))
			mouth.add_point(Vector2(0, 4))
			mouth.add_point(Vector2(-3, 6))
		"focused":
			# Entschlossene, leicht schiefe Linie
			mouth.add_point(Vector2(-4, 8))
			mouth.add_point(Vector2(4, 6))
		_:
			mouth.add_point(Vector2(-4, 7))
			mouth.add_point(Vector2(4, 7))
	_face_node.add_child(mouth)


## Kleiner runder Augapfel als Polygon2D (kein externes Asset).
func _make_eye(center: Vector2, radius: float, color: Color) -> Polygon2D:
	var eye := Polygon2D.new()
	eye.color = color
	var pts := PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	eye.polygon = pts
	return eye


## F01/F02: Hängt einen Sichtbarkeits-Knoten an den skalierbaren
## Visual-Root statt direkt an den RigidBody2D — so verformt Squash &
## Stretch nur die Optik, nie die Kollisionsform.
func _add_visual(node: Node) -> void:
	if _visual_root != null:
		_visual_root.add_child(node)
	else:
		add_child(node)  # Sicherheitsnetz, falls vor _ready() aufgerufen


## Bereitet den Zielpfeil (Line2D) vor – wird beim Zielen sichtbar.
func _build_aim_arrow() -> void:
	_aim_arrow = Line2D.new()
	_aim_arrow.name = "AimArrow"
	_aim_arrow.width = 8.0
	_aim_arrow.default_color = Color(1.0, 0.85, 0.2, 0.9)  # gelber Pfeil
	_aim_arrow.visible = false
	add_child(_aim_arrow)


## FR-048: Simuliert die Flugbahn und zeichnet Vorschau-Punkte.
func _update_traj_preview(dir: Vector2, strength: float, charge: float) -> void:
	var fart: Dictionary = FART_TYPES[_fart_type_index]
	var impulse := fart_power * strength * fart["power"] * (1.0 + charge * charge_hold_bonus)
	var grav := Vector2(0, ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
	grav *= gravity_scale
	var sim_vel := linear_velocity + dir * impulse / mass
	var sim_pos := global_position
	var dt := 0.06
	const DOTS := 10
	# Genug Dots vorbereiten
	while _traj_dots.size() < DOTS:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(10, 10)
		dot.color = Color(1.0, 0.9, 0.3, 0.6)
		dot.position = Vector2(-5, -5)
		get_parent().add_child(dot)
		_traj_dots.append(dot)
	for i in range(DOTS):
		sim_vel += grav * dt
		sim_pos += sim_vel * dt
		_traj_dots[i].global_position = sim_pos - Vector2(5, 5)
		var alpha := lerpf(0.6, 0.1, float(i) / float(DOTS))
		_traj_dots[i].modulate.a = alpha
		_traj_dots[i].visible = true


func _clear_traj_dots() -> void:
	for dot in _traj_dots:
		if is_instance_valid(dot):
			dot.visible = false


## FR-264: Aufbau der radialen Geschwindigkeitslinien (8 Linien um den Spieler).
func _build_speed_lines() -> void:
	for i in range(8):
		var line := Line2D.new()
		line.width = 2.5
		line.default_color = Color(0.8, 1.0, 0.6, 0.0)
		line.z_index = -2
		add_child(line)
		_speed_lines.append(line)


## FR-264: Geschwindigkeitslinien in Flugrichtung zeichnen.
func _update_speed_lines() -> void:
	if _speed_lines.is_empty():
		_build_speed_lines()
	var speed := linear_velocity.length()
	var show := speed > 600.0 and not _is_dead
	var dir := linear_velocity.normalized() if speed > 0.0 else Vector2.RIGHT
	for i in range(_speed_lines.size()):
		var line := _speed_lines[i]
		if not show:
			line.default_color.a = 0.0
			continue
		var angle := TAU * float(i) / float(_speed_lines.size())
		var spread := dir.rotated(angle) * 30.0
		var tail := -dir.rotated(angle * 0.1) * lerpf(20.0, 60.0, (speed - 600.0) / 800.0)
		line.clear_points()
		line.add_point(spread)
		line.add_point(spread + tail)
		var alpha := clampf((speed - 600.0) / 600.0, 0.0, 0.55)
		line.default_color = Color(0.75, 1.0, 0.55, alpha)


## FR-135: Wiederbelebt den Spieler an einer Checkpoint-Position.
func revive(at_pos: Vector2) -> void:
	_is_dead = false
	_is_aiming = false
	_touch_index = -1
	_aim_hold = 0.0
	_cooldown_remaining = 0.0
	_shield_remaining = 0.0
	global_position = at_pos
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	rotation = 0.0
	gravity_scale = level_gravity_scale
	_aim_arrow.visible = false
	shield_changed.emit(false)
	_update_shield_aura(false)  # FR-297
	if _trail != null:
		_trail.clear_points()
	# FR-058: Kurze Eingabesperre nach dem Respawn, damit kein versehentlicher
	# Furz-Stoß aus der Berührung ausgelöst wird, die den Neustart antippte.
	input_locked = true
	get_tree().create_timer(0.3).timeout.connect(func(): input_locked = false)


## FR-177: Setzt den Mittelpunkt (Hand-Spitze) der Arme-Line2D neu.
## (PackedVector2Array-Einträge lassen sich nicht per "points:N"-Tween-
## Subpfad animieren, daher über tween_method mit Neuzuweisung.)
func _set_arm_point(index: int, value: Vector2) -> void:
	if _arms == null:
		return
	var pts := _arms.points
	pts[index] = value
	_arms.points = pts


## FR-177: Spielt die ausgerüstete Sieges-Pose beim Levelabschluss ab.
func play_victory_pose() -> void:
	if _arms == null:
		return
	_victory_pose_active = true  # F10: Arm-Rudern währenddessen aussetzen
	var tween := create_tween()
	match CosmeticsManager.equipped_victory_pose:
		"pose_flex":
			tween.set_loops(2)
			tween.tween_method(_set_arm_point.bind(1), Vector2(0, -10), Vector2(0, -26), 0.25)
			tween.tween_method(_set_arm_point.bind(1), Vector2(0, -26), Vector2(0, -10), 0.25)
		"pose_dance":
			tween.set_loops(4)
			tween.tween_property(self, "rotation", 0.25, 0.15)
			tween.tween_property(self, "rotation", -0.25, 0.15)
			tween.tween_property(self, "rotation", 0.0, 0.1)
		_:  # "pose_wave" (Standard)
			tween.set_loops(3)
			tween.tween_method(_set_arm_point.bind(2), Vector2(16, 6), Vector2(20, -14), 0.2)
			tween.tween_method(_set_arm_point.bind(2), Vector2(20, -14), Vector2(16, 6), 0.2)


# ----------------------------------------------------------------
# FR-168: Flug-Spur (Trail)
# ----------------------------------------------------------------
func _build_trail() -> void:
	_trail = Line2D.new()
	_trail.name = "PlayerTrail"
	_trail.z_index = -1
	_trail.width = 5.0
	_trail.default_color = Color(0.6, 1.0, 0.5, 0.35)
	get_parent().add_child(_trail)


const _TRAIL_MAX := 22
const _TRAIL_MIN_DIST := 6.0

func _update_trail() -> void:
	if _trail == null or not is_instance_valid(_trail):
		return
	var speed := linear_velocity.length()
	_trail.visible = speed > 120.0 and not _is_dead
	if not _trail.visible:
		_trail.clear_points()
		return
	var local_pos := _trail.to_local(global_position)
	if _trail.get_point_count() == 0 or local_pos.distance_to(
			_trail.get_point_position(_trail.get_point_count() - 1)) > _TRAIL_MIN_DIST:
		_trail.add_point(local_pos)
		if _trail.get_point_count() > _TRAIL_MAX:
			_trail.remove_point(0)
	var alpha := clampf(speed / 1000.0, 0.0, 0.55)
	_trail.default_color = Color(0.55, 1.0, 0.45, alpha)


## FR-175: Liefert die Pfeil-Farbe passend zum ausgerüsteten Pfeil-Design.
func _aim_arrow_color(charge: float) -> Color:
	match CosmeticsManager.equipped_arrow_style:
		"arrow_neon":
			return Color(0.2, 1.0, 0.9, 0.9).lerp(Color(1.0, 0.1, 0.9, 1.0), charge)
		"arrow_rainbow":
			var hue := fmod(Time.get_ticks_msec() * 0.0005, 1.0)
			return Color.from_hsv(hue, 0.85, 1.0, 0.9)
		_:
			return Color(1.0, 0.85, 0.2, 0.9).lerp(Color(1.0, 0.3, 0.2, 1.0), charge)


## Zeichnet den Zielpfeil in lokaler Ausrichtung (entgegen der Rotation,
## damit er immer in Bildschirmrichtung zeigt).
func _draw_aim_arrow(dir: Vector2, strength: float) -> void:
	if dir == Vector2.ZERO:
		_aim_arrow.visible = false
		return
	_aim_arrow.visible = true
	# In den lokalen Raum umrechnen (Rotation des Körpers ausgleichen)
	var local_dir := dir.rotated(-rotation)
	# FR-049: Pfeil-Länge über arrow_min_length/arrow_max_length_bonus anpassbar
	var length := arrow_min_length + strength * arrow_max_length_bonus
	var tip := local_dir * length
	_aim_arrow.clear_points()
	_aim_arrow.add_point(Vector2.ZERO)
	_aim_arrow.add_point(tip)
	# Pfeilspitze
	var left := tip - local_dir.rotated(0.5) * 24.0
	var right := tip - local_dir.rotated(-0.5) * 24.0
	_aim_arrow.add_point(left)
	_aim_arrow.add_point(tip)
	_aim_arrow.add_point(right)
