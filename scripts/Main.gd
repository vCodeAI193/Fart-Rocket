extends Node2D
## Main – Level-Lader & Spielablauf
## ================================
## Lädt das im GameManager gewählte Level, verbindet die Signale von
## Player und Ziel-Flagge, steuert Kamera, HUD und den
## Abschlussbildschirm (LevelComplete).

@onready var _level_container: Node2D = $LevelContainer
@onready var _camera: CameraZoom = $Camera2D
@onready var _hud: HUD = $HUD
@onready var _level_complete: LevelComplete = $LevelComplete

var _vignette: CanvasLayer  # FR-286: Vignette-Effekt

var _player: Player
var _level_end: LevelEnd
var _max_charges: int = 0
var _level_finished: bool = false
var _checkpoint_pos: Vector2 = Vector2(INF, INF)  # FR-135
var _starfield: ParallaxStarfield  # FR-188
var _camera_min := Vector2(-100, -100)   # FR-185: Kamera-Grenzen pro Level
var _camera_max := Vector2(3800, 1400)

# --- FR-181/191: Dynamischer Zoom -------------------------------
var _dynamic_zoom: float = 1.0
const MAX_SPEED_FOR_ZOOM := 1800.0
const ZOOM_OUT_AT_MAX_SPEED := 0.72

# --- FR-186: Zielfokus-Kamera beim Zielen -----------------------
var _is_player_aiming: bool = false
var _aim_focus_dir: Vector2 = Vector2.ZERO

# --- FR-190: Mini-Karte ------------------------------------------
var _minimap: Control
var _minimap_player_dot: ColorRect
var _minimap_goal_dot: ColorRect

# --- FR-193: Rand-Indikatoren für Off-Screen-Ziele ---------------
var _edge_indicator: Control

# --- FR-194: Verfolgungs-Kamera für Boss-Kämpfe ------------------
var _active_boss: Node2D = null

# --- FR-197: Letterbox --------------------------------------------
var _letterbox: CanvasLayer
var _letterbox_top: ColorRect
var _letterbox_bottom: ColorRect

# --- FR-187: Kino-Modus beim Levelende -----------------------------
var _cinematic_active: bool = false

# --- FR-196: Kamera-Übergänge zwischen Sektionen -------------------
var _transition_active: bool = false

# --- FR-198: Erschütterung bei Beinahe-Treffern ------------------
var _near_miss_cooldown: float = 0.0
const NEAR_MISS_RADIUS := 55.0

# Fällt das Männchen unter diese Grenze (oder fliegt weit darüber hinaus),
# gilt das Level als verloren und wird neu gestartet.
const FALL_LIMIT_Y := 1700.0
const SKY_LIMIT_Y := -1200.0


func _ready() -> void:
	# FR-196: Ermöglicht CameraTransitionZone, Main unabhängig vom Szenenpfad zu finden
	add_to_group("main_controller")
	# Abschluss-Buttons verbinden
	_level_complete.next_level_pressed.connect(_on_next_level)
	_level_complete.retry_pressed.connect(_on_retry)
	_level_complete.menu_pressed.connect(_on_menu)

	# FR-188: Parallax-Sternenhintergrund erzeugen
	_starfield = ParallaxStarfield.new()
	add_child(_starfield)

	# FR-286: Vignette-Post-Processing
	_build_vignette()
	# FR-190: Mini-Karte
	_build_minimap()
	# FR-193: Rand-Indikatoren für Off-Screen-Ziele
	_build_edge_indicator()
	# FR-197: Letterbox für Zwischensequenzen/Kino-Modus
	_build_letterbox()

	_load_current_level()


## FR-286: Dunkle Vignette an Bildschirmrändern.
func _build_vignette() -> void:
	_vignette = CanvasLayer.new()
	_vignette.layer = 100
	add_child(_vignette)
	var vig := ColorRect.new()
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.color = Color(0.0, 0.0, 0.0, 0.35)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.add_child(vig)


## FR-190: Kleine Übersichtskarte oben links, zeigt Spieler- und Zielposition
## relativ zu den Kamera-Grenzen des Levels.
func _build_minimap() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 95
	add_child(layer)

	_minimap = Control.new()
	_minimap.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_minimap.offset_left = 20.0
	_minimap.offset_top = 150.0
	_minimap.offset_right = 180.0
	_minimap.offset_bottom = 260.0
	layer.add_child(_minimap)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.4)
	_minimap.add_child(bg)

	_minimap_goal_dot = ColorRect.new()
	_minimap_goal_dot.size = Vector2(10, 10)
	_minimap_goal_dot.color = Color(0.3, 1.0, 0.4)
	_minimap.add_child(_minimap_goal_dot)

	_minimap_player_dot = ColorRect.new()
	_minimap_player_dot.size = Vector2(8, 8)
	_minimap_player_dot.color = Color(1.0, 0.85, 0.2)
	_minimap.add_child(_minimap_player_dot)


## FR-193: Container für Rand-Indikator-Pfeile (Ziel, aktiver Boss).
func _build_edge_indicator() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 94
	add_child(layer)
	_edge_indicator = Control.new()
	_edge_indicator.set_anchors_preset(Control.PRESET_FULL_RECT)
	_edge_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_edge_indicator)


## FR-197: Schwarze Balken oben/unten für Zwischensequenzen/Kino-Modus (FR-187).
func _build_letterbox() -> void:
	_letterbox = CanvasLayer.new()
	_letterbox.layer = 99
	add_child(_letterbox)

	_letterbox_top = ColorRect.new()
	_letterbox_top.color = Color.BLACK
	_letterbox_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_letterbox_top.offset_bottom = 0.0
	_letterbox_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_letterbox.add_child(_letterbox_top)

	_letterbox_bottom = ColorRect.new()
	_letterbox_bottom.color = Color.BLACK
	_letterbox_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_letterbox_bottom.offset_top = 0.0
	_letterbox_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_letterbox.add_child(_letterbox_bottom)


## FR-197: Blendet die Letterbox-Balken ein/aus.
func set_letterbox_active(active: bool) -> void:
	var target_height := 90.0 if active else 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_letterbox_top, "offset_bottom", target_height, 0.4)
	tween.tween_property(_letterbox_bottom, "offset_top", -target_height, 0.4)


## FR-187: Kurze Kino-Sequenz beim Levelende — Letterbox einblenden und
## sanft auf den Spieler heranzoomen, bevor der Abschlussbildschirm erscheint.
func _play_cinematic_ending() -> void:
	if not is_instance_valid(_player):
		return
	_cinematic_active = true
	set_letterbox_active(true)
	var tween := create_tween()
	tween.tween_property(_camera, "zoom", Vector2.ONE * 1.35, 0.6).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(_camera, "global_position", _player.global_position, 0.6).set_trans(Tween.TRANS_SINE)
	await tween.finished
	await get_tree().create_timer(0.6).timeout
	set_letterbox_active(false)
	_cinematic_active = false


## FR-196: Zieht die Kamera kurz auf einen festen Punkt (z.B. Sektions-
## Übersicht), bevor sie wieder normal dem Spieler folgt. Wird von
## CameraTransitionZone aufgerufen.
func play_camera_transition(focus_pos: Vector2, focus_zoom: float, duration: float, hold: float) -> void:
	if _transition_active:
		return
	_transition_active = true
	var start_zoom := _camera.zoom
	var tween := create_tween()
	tween.tween_property(_camera, "global_position", focus_pos, duration).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(_camera, "zoom", Vector2.ONE * focus_zoom, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished
	await get_tree().create_timer(hold).timeout
	var back_tween := create_tween()
	if is_instance_valid(_player):
		back_tween.tween_property(_camera, "global_position", _player.global_position, duration * 0.7).set_trans(Tween.TRANS_SINE)
	back_tween.parallel().tween_property(_camera, "zoom", start_zoom, duration * 0.7).set_trans(Tween.TRANS_SINE)
	await back_tween.finished
	_transition_active = false


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return

	# FR-195: Im Foto-Modus wird die normale Kamera-Verfolgung pausiert
	if _camera.photo_mode:
		_update_minimap()
		return

	# FR-187: Während der Kino-Sequenz am Levelende führt eine eigene
	# Tween-Animation die Kamera — die normale Verfolgung pausiert dafür.
	if _level_finished and _cinematic_active:
		return
	# FR-196: Während eines Sektions-Übergangs übernimmt play_camera_transition()
	if _transition_active:
		return

	# FR-182/184: Kamera folgt sanft mit leichter Vorausschau
	var vel := _player.linear_velocity
	var look_ahead := vel.normalized() * minf(vel.length() * 0.10, 80.0)
	var target := _player.global_position + look_ahead

	# FR-186: Zielfokus-Kamera — beim Zielen leicht in Zugrichtung verschieben
	if _is_player_aiming:
		target += _aim_focus_dir * 120.0

	# FR-194: Verfolgungs-Kamera für Boss-Kämpfe — Mittelpunkt zwischen
	# Spieler und Boss anvisieren, wenn ein Boss aktiv ist
	if is_instance_valid(_active_boss):
		target = target.lerp(_active_boss.global_position, 0.35)

	# FR-200: Kamera-Glättung ist über die Einstellungen konfigurierbar
	_camera.global_position = _camera.global_position.lerp(target, minf(delta * GameManager.camera_smoothing, 1.0))
	# FR-185: Kamera in Grenzen halten
	_camera.global_position = _camera.global_position.clamp(_camera_min, _camera_max)

	# FR-181/191: Dynamischer Zoom je nach Geschwindigkeit + Zeitlupen-Zoom
	var speed_factor := clampf(vel.length() / MAX_SPEED_FOR_ZOOM, 0.0, 1.0)
	var target_zoom := lerpf(1.0, ZOOM_OUT_AT_MAX_SPEED, speed_factor)
	if Engine.time_scale < 0.9:  # FR-191: Zeitlupe aktiv -> näher heranzoomen
		target_zoom *= 1.15
	if is_instance_valid(_active_boss):  # FR-194: etwas weiter rauszoomen im Boss-Kampf
		target_zoom *= 0.85
	_dynamic_zoom = lerpf(_dynamic_zoom, target_zoom, minf(delta * 3.0, 1.0))
	_camera.zoom = Vector2.ONE * _dynamic_zoom * _camera.user_zoom_scale

	# FR-188: Sternenhintergrund mit Parallax-Versatz aktualisieren
	if _starfield != null:
		_starfield.global_position = _camera.global_position * (1.0 - _starfield.parallax_ratio)
	# FR-204/205: Geschwindigkeit und Höhe ans HUD melden
	_hud.set_speed(vel.length())
	_hud.set_player_height(_player.global_position.y)

	# FR-198: Beinahe-Treffer erkennen und leicht rütteln
	_check_near_miss(delta)
	# FR-190: Mini-Karte aktualisieren
	_update_minimap()
	# FR-193: Rand-Indikatoren aktualisieren
	_update_edge_indicators()

	# Aus dem Spielfeld gefallen? -> Level neu starten
	if not _level_finished:
		var y := _player.global_position.y
		if y > FALL_LIMIT_Y or y < SKY_LIMIT_Y:
			_level_finished = true
			get_tree().reload_current_scene()


## FR-198: Prüft die Distanz zu nahen Hindernissen; ist der Spieler knapp
## vorbeigeflogen (ohne Treffer), gibt es ein kleines Warn-Rütteln.
func _check_near_miss(delta: float) -> void:
	_near_miss_cooldown = maxf(0.0, _near_miss_cooldown - delta)
	if _near_miss_cooldown > 0.0:
		return
	for obstacle in get_tree().get_nodes_in_group("obstacles"):
		if not (obstacle is Node2D):
			continue
		var dist := _player.global_position.distance_to(obstacle.global_position)
		if dist < NEAR_MISS_RADIUS:
			_camera_shake(0.06, 0.1)
			_near_miss_cooldown = 0.4
			return


## FR-190: Aktualisiert die Positions-Punkte auf der Mini-Karte.
func _update_minimap() -> void:
	if _minimap == null or not is_instance_valid(_player):
		return
	var map_size := _minimap.size
	var bounds_size := _camera_max - _camera_min
	if bounds_size.x <= 0.0 or bounds_size.y <= 0.0:
		return
	var player_frac := (_player.global_position - _camera_min) / bounds_size
	_minimap_player_dot.position = player_frac * map_size - _minimap_player_dot.size * 0.5
	if _level_end != null:
		var goal_frac := (_level_end.global_position - _camera_min) / bounds_size
		_minimap_goal_dot.position = goal_frac * map_size - _minimap_goal_dot.size * 0.5


## FR-193: Zeigt Pfeile am Bildschirmrand für off-screen Ziel/Boss.
func _update_edge_indicators() -> void:
	if _edge_indicator == null:
		return
	for child in _edge_indicator.get_children():
		child.queue_free()

	var viewport_rect := get_viewport().get_visible_rect()
	var targets: Array[Node2D] = []
	if _level_end != null:
		targets.append(_level_end)
	if is_instance_valid(_active_boss):
		targets.append(_active_boss)

	for target_node in targets:
		var screen_pos := target_node.global_position - _camera.global_position + viewport_rect.size * 0.5
		if viewport_rect.has_point(screen_pos):
			continue  # sichtbar, kein Indikator nötig
		var center := viewport_rect.size * 0.5
		var dir := (screen_pos - center).normalized()
		var margin := 60.0
		var clamped := center + dir * (min(viewport_rect.size.x, viewport_rect.size.y) * 0.5 - margin)
		var indicator := _make_edge_arrow(dir)
		indicator.position = clamped
		_edge_indicator.add_child(indicator)


## FR-193: Erzeugt einen kleinen Pfeil, der in Richtung `dir` zeigt.
func _make_edge_arrow(dir: Vector2) -> Control:
	var container := Control.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := Line2D.new()
	var angle := dir.angle()
	var tip := Vector2(cos(angle), sin(angle)) * 18.0
	var left := tip - Vector2(cos(angle - 2.6), sin(angle - 2.6)) * 14.0
	var right := tip - Vector2(cos(angle + 2.6), sin(angle + 2.6)) * 14.0
	line.points = [left, tip, right]
	line.width = 4.0
	line.default_color = Color(1.0, 0.85, 0.2, 0.85)
	container.add_child(line)
	return container


## Lädt die aktuelle Level-Szene und richtet das Spiel ein.
func _load_current_level() -> void:
	_level_finished = false
	_checkpoint_pos = Vector2(INF, INF)  # FR-135: Checkpoint zurücksetzen
	var path := GameManager.get_level_scene_path(GameManager.current_level)
	var level_scene: PackedScene = load(path)
	var level := level_scene.instantiate()
	_level_container.add_child(level)

	# Player und Ziel im Level finden (mit Cast auf die konkreten Typen)
	_player = _find_in_group(level, "player") as Player
	_level_end = _find_in_group(level, "level_end") as LevelEnd

	if _player == null:
		push_error("Kein Player (Gruppe 'player') im Level gefunden!")
		return

	# Furz-Ladungen aus dem Player übernehmen
	_max_charges = _player.max_fart_charges
	GameManager.start_level(GameManager.current_level, _max_charges)
	# FR-099: Gesamtzahl der Münzen im Level für die Fortschrittsanzeige zählen
	GameManager.set_level_coin_total(get_tree().get_nodes_in_group("coins").size())

	# HUD einrichten
	_hud.set_max_charges(_max_charges)
	_hud.start_timer()

	# FR-002: Furz-Typ-Auswahl aufbauen und mit dem Player verbinden
	_hud.setup_fart_types(_player.get_fart_types(), _player.get_fart_type_index())
	_hud.fart_type_selected.connect(_player.set_fart_type)
	_player.fart_type_changed.connect(_hud.highlight_fart_type)

	# Signale verbinden
	_player.died.connect(_on_player_died)
	_player.fart_fired.connect(_on_fart_fired)    # FR-265/192
	_player.shield_changed.connect(_hud.set_shield_active)  # FR-206/010
	# FR-186: Zielfokus-Kamera
	_player.aim_changed.connect(_on_player_aim_changed)
	_player.aim_released.connect(_on_player_aim_released)
	if _level_end != null:
		_level_end.reached.connect(_on_level_reached)
		_apply_focus_highlight(_level_end)  # FR-199
	# FR-135: Checkpoints verbinden (nach add_child haben alle _ready() durchlaufen)
	for cp in get_tree().get_nodes_in_group("checkpoints"):
		(cp as Checkpoint).triggered.connect(_on_checkpoint_triggered)

	# FR-194: Aktiven Boss im Level erkennen (falls vorhanden)
	var bosses := get_tree().get_nodes_in_group("bosses")
	if bosses.size() > 0:
		_active_boss = bosses[0]
		_apply_focus_highlight(_active_boss)  # FR-199
		if _active_boss.has_signal("boss_defeated"):
			# String-basiertes connect(), da Node2D das Signal "boss_defeated"
			# statisch nicht kennt (nur MiniBoss/EndBoss deklarieren es).
			_active_boss.connect("boss_defeated", _on_active_boss_defeated)

	# Kamera sofort auf den Player setzen
	_camera.global_position = _player.global_position
	_camera.make_current()


# --- FR-265: Kamera-Wackeln ------------------------------------
func _camera_shake(strength: float, duration: float) -> void:
	# FR-189: Globale Rüttel-Intensität aus den Einstellungen anwenden
	var effective_strength := strength * GameManager.camera_shake_intensity
	if effective_strength <= 0.0:
		return
	var tween := create_tween()
	var steps := maxi(2, int(duration / 0.04))
	for i in range(steps):
		var offset := Vector2(
			randf_range(-1.0, 1.0) * effective_strength * 80.0,
			randf_range(-1.0, 1.0) * effective_strength * 80.0
		)
		tween.tween_property(_camera, "offset", offset, 0.04)
	tween.tween_property(_camera, "offset", Vector2.ZERO, 0.06)


## FR-192: Kurzer gerichteter Kamera-Stoß in Furz-Richtung (Impuls-Feedback).
func _camera_punch(direction: Vector2, strength: float) -> void:
	if GameManager.camera_shake_intensity <= 0.0:
		return
	var punch_offset := -direction * strength * 18.0 * GameManager.camera_shake_intensity
	var tween := create_tween()
	tween.tween_property(_camera, "offset", punch_offset, 0.05)
	tween.tween_property(_camera, "offset", Vector2.ZERO, 0.12)


func _on_fart_fired(impulse: float, direction: Vector2) -> void:
	_camera_shake(clampf(impulse / 2000.0, 0.04, 0.18), 0.14)
	_camera_punch(direction, clampf(impulse / 1500.0, 0.2, 1.0))  # FR-192


## FR-186: Zielrichtung für die Zielfokus-Kamera übernehmen.
func _on_player_aim_changed(direction: Vector2, _strength: float) -> void:
	_is_player_aiming = true
	_aim_focus_dir = direction


## FR-186: Zielfokus wieder aufheben, sobald der Spieler loslässt.
func _on_player_aim_released() -> void:
	_is_player_aiming = false
	_aim_focus_dir = Vector2.ZERO


## FR-194: Boss besiegt — Verfolgungs-Kamera wieder auf den Spieler zentrieren.
func _on_active_boss_defeated() -> void:
	_active_boss = null


## FR-199: Fokus-Highlight — pulsierender Umriss um ein wichtiges Objekt.
func _apply_focus_highlight(target: Node2D) -> void:
	var highlight := Line2D.new()
	highlight.width = 3.0
	highlight.default_color = Color(1.0, 0.9, 0.3, 0.7)
	var points := PackedVector2Array()
	var radius := 40.0
	for i in range(17):
		var a := TAU * float(i) / 16.0
		points.append(Vector2(cos(a), sin(a)) * radius)
	highlight.points = points
	target.add_child(highlight)

	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(highlight, "scale", Vector2(1.25, 1.25), 0.8).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(highlight, "modulate:a", 0.2, 0.8)
	tween.tween_property(highlight, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(highlight, "modulate:a", 0.7, 0.8)


## FR-195: Foto-/Replay-Kameramodus umschalten (nur nutzbar während Pause).
## Die Ein-Finger-Verschiebung wird direkt von CameraZoom (FR-041) behandelt,
## da diese als einziger Knoten PROCESS_MODE_ALWAYS nutzt, ohne den Player
## via Vererbung versehentlich mit-aufzuwecken.
func toggle_photo_mode() -> void:
	_camera.photo_mode = not _camera.photo_mode
	if not _camera.photo_mode:
		_camera.offset = Vector2.ZERO


## FR-195: Öffentlicher Zugriff für das HUD, ob der Foto-Modus aktiv ist.
func is_photo_mode() -> bool:
	return _camera.photo_mode


# --- Spielereignisse --------------------------------------------
func _on_player_died() -> void:
	_camera_shake(0.3, 0.35)
	_hud.flash_damage()  # FR-209: rote Vignette
	# FR-135: Am Checkpoint wiederbeleben, falls einer aktiviert wurde
	if _checkpoint_pos.x < INF:
		_player.revive(_checkpoint_pos)
		_level_finished = false
	else:
		get_tree().reload_current_scene()


func _on_checkpoint_triggered(pos: Vector2) -> void:
	_checkpoint_pos = pos
	_hud.show_checkpoint_msg()  # FR-212: Checkpoint-Benachrichtigung


func _on_level_reached() -> void:
	if _level_finished:
		return
	_level_finished = true

	# Zeit stoppen und Sterne berechnen
	var time_sec: float = _hud.stop_timer()
	var stars := GameManager.calculate_stars(_max_charges)
	GameManager.record_stars(GameManager.current_level, stars)

	# FR-341: Im Zeitrennen-Modus Bestzeit aktualisieren
	if GameManager.time_attack_mode:
		var is_new_best := GameManager.record_time_attack(GameManager.current_level, time_sec)
		if is_new_best:
			GameManager.vibrate(80)

	# FR-187: Kurzer Kino-Modus (Zoom + Letterbox) vor dem Abschlussbildschirm
	await _play_cinematic_ending()

	# Abschlussbildschirm anzeigen
	_level_complete.show_result(
		stars,
		GameManager.total_coins,
		time_sec,
		GameManager.has_next_level()
	)


# --- Buttons im Abschlussbildschirm -----------------------------
func _on_next_level() -> void:
	if GameManager.has_next_level():
		GameManager.current_level += 1
	get_tree().reload_current_scene()


func _on_retry() -> void:
	get_tree().reload_current_scene()


func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


# --- Hilfsfunktion: ersten Knoten einer Gruppe im Baum finden ---
func _find_in_group(root: Node, group_name: String) -> Node:
	if root.is_in_group(group_name):
		return root
	for child in root.get_children():
		var found := _find_in_group(child, group_name)
		if found != null:
			return found
	return null
