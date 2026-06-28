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

# --- FR-001: Optionale Furz-Regeneration (pro Level einstellbar) -
@export var charge_regen_enabled: bool = false  # Ladungen mit der Zeit nachfüllen?
@export var charge_regen_time: float = 5.0      # Sekunden bis eine Ladung nachlädt

# --- Signale ----------------------------------------------------
signal died                                  # Männchen hat ein Hindernis getroffen
signal aim_changed(direction, strength)      # Zielrichtung/-stärke geändert
signal aim_released                          # Zielen beendet (Pfeil ausblenden)
signal fart_type_changed(index)              # aktiver Furz-Typ gewechselt (FR-002)

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
var _is_aiming: bool = false
var _aim_start: Vector2 = Vector2.ZERO       # Startpunkt der Berührung (Screen)
var _aim_current: Vector2 = Vector2.ZERO     # aktueller Berührungspunkt (Screen)
var _touch_index: int = -1                   # verfolgter Finger (Multitouch-sicher)
var _is_dead: bool = false                   # Tod/Restart läuft bereits
var _regen_accum: float = 0.0                # aufgelaufene Zeit für die Regeneration
var _fart_type_index: int = 1                # aktiver Furz-Typ (Standard: Normal)

# Referenzen auf untergeordnete Knoten
var _aim_arrow: Line2D


func _ready() -> void:
	# Schwerkraft skalieren (Standard kommt aus den Projekteinstellungen)
	contact_monitor = true
	max_contacts_reported = 4
	# Kollision mit Hindernissen erkennen
	body_entered.connect(_on_body_entered)
	# Strichmännchen + Helm zeichnen und Zielpfeil vorbereiten
	_build_stick_figure()
	_build_aim_arrow()


# ----------------------------------------------------------------
# FR-001: Furz-Ladungen über Zeit regenerieren (optional)
# ----------------------------------------------------------------
func _process(delta: float) -> void:
	if _is_dead or not charge_regen_enabled or charge_regen_time <= 0.0:
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


# ----------------------------------------------------------------
# Touch-Eingabe: Zielen & Furzen
# ----------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if _is_dead:
		return

	# Finger berührt den Bildschirm -> Zielen beginnen
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_is_aiming = true
			_aim_start = event.position
			_aim_current = event.position
			_update_aim_visual()
		elif not event.pressed and event.index == _touch_index:
			# Finger losgelassen -> Furz-Stoß auslösen
			_release_fart()
			_touch_index = -1

	# Finger zieht über den Bildschirm -> Zielrichtung aktualisieren
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_aim_current = event.position
		_update_aim_visual()


## Aktualisiert den Zielpfeil und sendet das aim_changed-Signal.
func _update_aim_visual() -> void:
	var drag := _aim_current - _aim_start
	var strength := clampf(drag.length() / max_drag_distance, 0.0, 1.0)
	var dir := drag.normalized()
	_draw_aim_arrow(dir, strength)
	aim_changed.emit(dir, strength)


## Löst den Furz-Stoß aus: je nach Furz-Typ Impuls(e) + Partikel + Sound.
func _release_fart() -> void:
	_is_aiming = false
	_aim_arrow.visible = false
	aim_released.emit()

	var drag := _aim_current - _aim_start
	# Zu kurzes Ziehen ignorieren (versehentliche Tipper)
	if drag.length() < 20.0:
		return

	var fart: Dictionary = FART_TYPES[_fart_type_index]

	# Genug Ladungen für diesen Furz-Typ vorhanden?
	if not GameManager.use_charges(fart["cost"]):
		return

	var strength := clampf(drag.length() / max_drag_distance, 0.0, 1.0)
	var dir := drag.normalized()
	var impulse: float = fart_power * strength * fart["power"]
	var bursts: int = fart["bursts"]
	var tint: Color = fart["color"]

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


## Wendet einen einzelnen Schub an und erzeugt die passende Furz-Wolke.
func _do_thrust(dir: Vector2, impulse: float, tint: Color) -> void:
	# Das Männchen fliegt in Zugrichtung (wie eine Rakete)
	apply_central_impulse(dir * impulse)
	# Furz-Wolke hinter dem Männchen erzeugen (entgegengesetzte Richtung).
	# Die FartBurst-Szene spielt dabei selbst den Furz-Sound ab.
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
		_die()


## Lustige Tod-Animation: das Männchen wirbelt herum, dann Signal "died".
func _die() -> void:
	_is_dead = true
	_aim_arrow.visible = false
	# Wild durch die Luft wirbeln (lustiger Effekt)
	gravity_scale = 0.3
	angular_velocity = 12.0
	apply_central_impulse(Vector2(0, -350))
	# Letzten Furz als "Ohnmacht" ausstoßen
	_spawn_fart_burst(Vector2.DOWN)
	# Kurze Verzögerung, damit man die Animation sieht
	await get_tree().create_timer(0.9).timeout
	died.emit()


# ----------------------------------------------------------------
# Aufbau der Grafik: Strichmännchen mit Helm (per Line2D)
# ----------------------------------------------------------------
func _build_stick_figure() -> void:
	var col := Color(0.95, 0.95, 0.95)  # weiße Linien

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
