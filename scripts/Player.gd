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
signal fart_fired(impulse)                   # FR-265: Furz ausgelöst (für Kamera-Wackeln)
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


var _trail: Line2D = null              # FR-168: Flug-Spur
var _speed_lines: Array[Line2D] = []   # FR-264: Geschwindigkeitslinien
var _traj_dots: Array[Node2D] = []     # FR-048: Flugbahn-Vorschau
var _last_tap_time: float = -1.0       # FR-050: Doppel-Tipp-Erkennung


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	gravity_scale = level_gravity_scale  # FR-021
	angular_damp = rotation_damping      # FR-033
	body_entered.connect(_on_body_entered)
	_build_stick_figure()
	_build_aim_arrow()
	# FR-020: Standard-Kurve initialisieren (linear, falls nicht gesetzt)
	if power_curve.point_count == 0:
		power_curve.add_point(Vector2(0, 0))
		power_curve.add_point(Vector2(1, 1))
		_initialized_curve = true
	# Trail und Speed-Lines nach dem nächsten Frame aufbauen
	call_deferred("_build_trail")


# ----------------------------------------------------------------
# Pro-Frame-Logik: Cooldown (FR-008), Aufladung (FR-005),
# Regeneration (FR-001)
# ----------------------------------------------------------------
func _process(delta: float) -> void:
	if _is_dead:
		return

	# FR-008: Abklingzeit herunterzählen
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)

	# FR-010: Schild-Timer
	if _shield_remaining > 0.0:
		_shield_remaining = maxf(0.0, _shield_remaining - delta)
		if _shield_remaining == 0.0:
			shield_changed.emit(false)

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


## FR-001: Regenerations-Logik (aus _process ausgelagert).
func _process_regen(delta: float) -> void:
	if not charge_regen_enabled or charge_regen_time <= 0.0:
		return
	# Nur nachladen, wenn noch Platz ist
	if GameManager.charges_remaining >= GameManager.max_charges:
		_regen_accum = 0.0
		return

	_regen_accum += delta
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
	if _is_dead:
		return

	# Finger berührt den Bildschirm -> Zielen beginnen
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			# FR-050: Doppel-Tipp erkennen (innerhalb 0.3 Sekunden)
			var now := Time.get_ticks_msec() / 1000.0
			if now - _last_tap_time < 0.3:
				died.emit()  # Schnell-Neustart: Tod-Signal senden, Main lädt Level neu
				return
			_last_tap_time = now
			_touch_index = event.index
			_is_aiming = true
			_aim_start = event.position
			_aim_current = event.position
			_aim_hold = 0.0  # FR-005: Aufladung neu beginnen
			_update_aim_visual()
		elif not event.pressed and event.index == _touch_index:
			# Finger losgelassen -> Furz-Stoß auslösen
			_release_fart()
			_touch_index = -1
			_clear_traj_dots()

	# Finger zieht über den Bildschirm -> Zielrichtung aktualisieren
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_aim_current = event.position
		_update_aim_visual()


## Aktualisiert den Zielpfeil und sendet das aim_changed-Signal.
func _update_aim_visual() -> void:
	var drag := _aim_current - _aim_start
	var strength := clampf(drag.length() / max_drag_distance, 0.0, 1.0)
	var dir := drag.normalized()
	# FR-053: Auto-Aim-Modus — suche nächstes Ziel bei kurzen Zügen
	if auto_aim_enabled and drag.length() < max_drag_distance * 0.3:
		var target_dir := _find_nearest_target()
		if target_dir != Vector2.ZERO:
			dir = target_dir
	_draw_aim_arrow(dir, strength)
	# FR-005: Pfeil färbt sich mit zunehmender Aufladung von Gelb nach Rot
	var charge := _hold_factor()
	_aim_arrow.default_color = Color(1.0, 0.85, 0.2, 0.9).lerp(Color(1.0, 0.3, 0.2, 1.0), charge)
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
	# Zu kurzes Ziehen ignorieren (versehentliche Tipper)
	if drag.length() < 20.0:
		return

	# FR-008: Noch in der Abklingzeit? Dann kein Stoß.
	if _cooldown_remaining > 0.0:
		return

	# FR-012: Überhitzt? Dann kein Stoß möglich bis abgekühlt
	if _heat_level >= 1.0 and _overheat_cooldown > 0.0:
		return

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
	var strength := clampf(drag.length() / max_drag_distance, 0.0, 1.0)
	var dir := drag.normalized()
	# FR-009: Winkel-Präzisions-Bonus — perfekte Winkel bekommen Schub-Bonus
	var precision_mult := _calculate_precision_bonus(dir)
	# FR-020: Anpassbare Furz-Schubkurve anwenden (Kurven-Mapping)
	var curve_factor := power_curve.sample(strength)
	var impulse: float = fart_power * curve_factor * fart["power"] * charge_mult * precision_mult
	var bursts: int = fart["bursts"]
	var tint: Color = fart["color"]

	# FR-008: Abklingzeit starten, FR-045: kurze Vibration
	_cooldown_remaining = fart_cooldown
	GameManager.vibrate(40)

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
	var tolerance := PI * 0.15
	var bonus := (1.0 - clampf(min_angle_diff / tolerance, 0.0, 1.0)) * 0.5
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
	if drag.length() < 20.0:
		return
	var dir := drag.normalized()
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
	fart_fired.emit(impulse)  # FR-265: Kamera-Wackeln signalisieren
	_spawn_fart_burst(-dir, tint)


## Erzeugt die FartBurst-Szene (eingefärbte Partikelwolke) hinter dem Männchen.
func _spawn_fart_burst(back_dir: Vector2, tint: Color = Color.WHITE) -> void:
	if fart_burst_scene == null:
		return
	var burst := fart_burst_scene.instantiate() as FartBurst
	get_parent().add_child(burst)
	burst.global_position = global_position + back_dir * 30.0
	# Partikel in die Furz-Richtung ausrichten
	burst.rotation = back_dir.angle()
	burst.erupt(tint)


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
	if body.is_in_group("obstacles"):
		# FR-010: Schild absorbiert den ersten Treffer
		if _shield_remaining > 0.0:
			_shield_remaining = 0.0
			shield_changed.emit(false)
			GameManager.vibrate(60)
			return
		_die()


## FR-010: Aktiviert den Furz-Schild für `duration` Sekunden.
func activate_shield(duration: float) -> void:
	_shield_remaining = duration
	shield_changed.emit(true)
	GameManager.vibrate(30)


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


## FR-040: Ragdoll-Modus aktivieren — Figur wird zur Puppe.
func _activate_ragdoll() -> void:
	_ragdoll_active = true
	gravity_scale = 1.0
	angular_velocity = randf_range(-15.0, 15.0)
	linear_damp = 0.5
	apply_central_impulse(Vector2(randf_range(-200, 200), -300))


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


# ----------------------------------------------------------------
# Aufbau der Grafik: Strichmännchen mit Helm (per Line2D)
# ----------------------------------------------------------------
func _build_stick_figure() -> void:
	var col := skin_color  # FR-162: konfigurierbare Maennchen-Farbe

	# Helm (Kreis aus Line2D-Punkten)
	var helmet := Line2D.new()
	helmet.name = "Helmet"
	helmet.width = 4.0
	helmet.default_color = Color(0.55, 0.85, 1.0)  # hellblauer Helm
	helmet.closed = true
	var segments := 16
	var radius := 16.0
	var center := Vector2(0, -34)
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		helmet.add_point(center + Vector2(cos(a), sin(a)) * radius)
	add_child(helmet)

	# Körper (Torso)
	var torso := Line2D.new()
	torso.name = "Torso"
	torso.width = 5.0
	torso.default_color = col
	torso.add_point(Vector2(0, -18))
	torso.add_point(Vector2(0, 18))
	add_child(torso)

	# Arme
	var arms := Line2D.new()
	arms.name = "Arms"
	arms.width = 5.0
	arms.default_color = col
	arms.add_point(Vector2(-16, 6))
	arms.add_point(Vector2(0, -10))
	arms.add_point(Vector2(16, 6))
	add_child(arms)

	# Beine
	var legs := Line2D.new()
	legs.name = "Legs"
	legs.width = 5.0
	legs.default_color = col
	legs.add_point(Vector2(-14, 40))
	legs.add_point(Vector2(0, 18))
	legs.add_point(Vector2(14, 40))
	add_child(legs)


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
	if _trail != null:
		_trail.clear_points()


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


## Zeichnet den Zielpfeil in lokaler Ausrichtung (entgegen der Rotation,
## damit er immer in Bildschirmrichtung zeigt).
func _draw_aim_arrow(dir: Vector2, strength: float) -> void:
	if dir == Vector2.ZERO:
		_aim_arrow.visible = false
		return
	_aim_arrow.visible = true
	# In den lokalen Raum umrechnen (Rotation des Körpers ausgleichen)
	var local_dir := dir.rotated(-rotation)
	var length := 60.0 + strength * 140.0
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
