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

# --- FR-281–300: Shader & Rendering (Post-Processing-Stack) --------
var _postfx_layer: CanvasLayer
var _fps_label: Label  # FR-431
var _fx_chromatic: ColorRect
var _fx_motion_blur: ColorRect
var _fx_bloom: ColorRect
var _fx_color_grading: ColorRect
var _fx_crt: ColorRect
var _fx_vision_cone: ColorRect
var _fx_slowmo: ColorRect  # FR-270: Slow-Mo-Visualfilter
var _fx_colorblind: ColorRect  # FR-421/433: Farbenblind-Assistenz
var _bg_texture_rect: TextureRect  # FR-281/290/292: Weltraum/Tag-Nacht/Grading-Ziel
var _daynight_material: ShaderMaterial  # FR-290: Tag-/Nacht-Verlauf-Overlay
var _daynight_elapsed: float = 0.0

# --- FR-343: Überleben-Modus — Schwerkraft steigt mit der Zeit -------
var _survival_elapsed: float = 0.0
var _survival_base_gravity: float = 1.0

# Fällt das Männchen unter diese Grenze (oder fliegt weit darüber hinaus),
# gilt das Level als verloren und wird neu gestartet.
const FALL_LIMIT_Y := 1700.0
const SKY_LIMIT_Y := -1200.0


## FR-436: Pausiert automatisch, wenn die App den Fokus verliert
## (z.B. Task-Wechsel, eingehender Anruf) — sofern aktiviert.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and GameManager.pause_on_focus_loss:
		if is_instance_valid(_hud) and _hud.has_method("force_pause"):
			_hud.force_pause()


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
	# FR-281/290/292: Shader auf den Weltraum-Hintergrund anwenden
	_apply_background_shader()
	# FR-282/287/288/292/294: Screen-Space-Post-Processing-Stack
	_build_postfx_stack()
	GameManager.render_settings_changed.connect(_update_postfx_visibility)
	set_crt_filter_active(GameManager.crt_filter_enabled)
	# FR-278: Umgebungspartikel (treibender Staub) für Atmosphäre
	_build_ambient_particles()

	_load_current_level()


## FR-278: Treibende Umgebungspartikel (Staub/Funken) für Atmosphäre —
## als Kind der Kamera, damit sie stets im sichtbaren Bereich entstehen.
func _build_ambient_particles() -> void:
	var dust := CPUParticles2D.new()
	dust.amount = 36
	dust.lifetime = 7.0
	dust.preprocess = 7.0
	dust.emitting = true
	dust.local_coords = false
	dust.gravity = Vector2(0, 4)
	dust.initial_velocity_min = 3.0
	dust.initial_velocity_max = 16.0
	dust.spread = 180.0
	dust.scale_amount_min = 1.0
	dust.scale_amount_max = 2.5
	dust.color = Color(1.0, 1.0, 1.0, 0.12)
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(760, 480)
	_camera.add_child(dust)


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


## FR-281/290/292: Wendet Weltraum-Hintergrund-, Tag/Nacht- und Farb-
## Grading-Shader auf den Hintergrund an (kombiniert über eine kleine
## Shader-Kette: space_background zuerst, day_night/grading als Tint
## direkt in dessen Parametern nachgebildet, um Passes zu sparen).
func _apply_background_shader() -> void:
	_bg_texture_rect = get_node_or_null("Background/BG") as TextureRect
	if _bg_texture_rect == null:
		return

	var shader := load("res://shaders/space_background.gdshader")
	var mat := ShaderMaterial.new()
	mat.shader = shader
	# FR-292: Farb-Grading pro Welt — je Level ein anderer Nebel-Farbton
	var palette := [
		[Color(0.15, 0.05, 0.35), Color(0.02, 0.05, 0.15)],
		[Color(0.05, 0.25, 0.2), Color(0.02, 0.1, 0.08)],
		[Color(0.35, 0.1, 0.08), Color(0.12, 0.02, 0.02)],
	]
	var idx := clampi(GameManager.current_level - 1, 0, palette.size() - 1)
	mat.set_shader_parameter("nebula_color_a", palette[idx][0])
	mat.set_shader_parameter("nebula_color_b", palette[idx][1])
	_bg_texture_rect.material = mat

	# FR-295: Funkelnde Parallax-Sterne als zusätzliche Shader-Ebene
	var star_layer := get_node_or_null("Background")
	if star_layer != null:
		var star_rect := ColorRect.new()
		star_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		star_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var star_mat := ShaderMaterial.new()
		star_mat.shader = load("res://shaders/star_parallax.gdshader")
		star_rect.material = star_mat
		star_layer.add_child(star_rect)

		# FR-290: Langsamer Tag-/Nacht-Verlauf als zusätzliches Tint-Overlay
		var daynight_rect := ColorRect.new()
		daynight_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		daynight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var daynight_mat := ShaderMaterial.new()
		daynight_mat.shader = load("res://shaders/day_night_cycle.gdshader")
		daynight_mat.set_shader_parameter("night_tint", Color(0.1, 0.12, 0.35, 0.35))
		daynight_mat.set_shader_parameter("cycle_progress", 0.0)
		daynight_rect.material = daynight_mat
		star_layer.add_child(daynight_rect)
		_daynight_material = daynight_mat


## FR-282/287/288/292/294: Baut den Screen-Space-Post-Processing-Stack auf.
## Jeder Effekt ist ein eigenes ColorRect mit hint_screen_texture-Shader,
## übereinander gestapelt in einem CanvasLayer über dem Spielgeschehen.
func _build_postfx_stack() -> void:
	_postfx_layer = CanvasLayer.new()
	_postfx_layer.layer = 80  # unter HUD (90+), über dem Spielfeld
	add_child(_postfx_layer)

	_fx_color_grading = _make_fx_rect("res://shaders/color_grading.gdshader")
	_fx_bloom = _make_fx_rect("res://shaders/bloom.gdshader")
	_fx_chromatic = _make_fx_rect("res://shaders/chromatic_aberration.gdshader")
	_fx_motion_blur = _make_fx_rect("res://shaders/motion_blur.gdshader")
	_fx_crt = _make_fx_rect("res://shaders/crt_filter.gdshader")
	_fx_vision_cone = _make_fx_rect("res://shaders/vision_cone.gdshader")
	_fx_slowmo = _make_fx_rect("res://shaders/slowmo_filter.gdshader")
	_fx_colorblind = _make_fx_rect("res://shaders/colorblind_assist.gdshader")  # FR-421/433
	_fx_crt.visible = false      # FR-282: standardmäßig aus, per Einstellung aktivierbar
	_fx_vision_cone.visible = false  # FR-289: nur in Dunkelheits-Leveln aktiv

	# FR-431: Umschaltbare FPS-Anzeige
	_fps_label = Label.new()
	_fps_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_fps_label.offset_left = 10
	_fps_label.offset_top = 10
	_fps_label.add_theme_font_size_override("font_size", 22)
	_fps_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	_fps_label.visible = GameManager.fps_counter_enabled
	_postfx_layer.add_child(_fps_label)

	_apply_accessibility_settings()  # FR-421/422/429
	GameManager.accessibility_changed.connect(_apply_accessibility_settings)
	_update_postfx_visibility()


func _make_fx_rect(shader_path: String) -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(1, 1, 1, 1)
	var mat := ShaderMaterial.new()
	mat.shader = load(shader_path)
	rect.material = mat
	_postfx_layer.add_child(rect)
	return rect


## FR-421/422/429/433: Wendet Farbenblind-Filter, Hoher-Kontrast-Modus und
## Bildschirm-Helligkeit auf den Post-Processing-Stack an.
func _apply_accessibility_settings() -> void:
	if _fx_colorblind != null:
		var cb_mat: ShaderMaterial = _fx_colorblind.material
		cb_mat.set_shader_parameter("mode", int(GameManager.colorblind_mode))
		_fx_colorblind.visible = GameManager.colorblind_mode != GameManager.ColorblindMode.NONE
	if _fx_color_grading != null:
		var cg_mat: ShaderMaterial = _fx_color_grading.material
		# FR-422: Hoher Kontrast erhöht Kontrast/Sättigung deutlich
		cg_mat.set_shader_parameter("contrast", 1.5 if GameManager.high_contrast_enabled else 1.0)
		cg_mat.set_shader_parameter("saturation", 1.3 if GameManager.high_contrast_enabled else 1.0)
		# FR-429: Bildschirm-Helligkeit als RGB-Multiplikator
		var b := GameManager.screen_brightness
		cg_mat.set_shader_parameter("color_balance", Vector3(b, b, b))


## FR-300: Schaltet teure Shader-Passes je nach Qualitätsstufe ab, damit
## schwächere Geräte flüssig bleiben.
func _update_postfx_visibility() -> void:
	var quality := GameManager.shader_quality
	_fx_bloom.visible = quality == "high"
	_fx_motion_blur.visible = quality != "low"
	_fx_chromatic.visible = quality != "low"
	_fx_color_grading.visible = true  # günstig, bleibt immer an


## FR-288/294: Aktualisiert Aberrations-/Blur-Stärke anhand der Spielergeschwindigkeit.
func _update_speed_postfx(vel: Vector2) -> void:
	var speed_factor := clampf(vel.length() / MAX_SPEED_FOR_ZOOM, 0.0, 1.0)

	if _fx_chromatic.visible:
		var mat: ShaderMaterial = _fx_chromatic.material
		mat.set_shader_parameter("aberration_strength", speed_factor * speed_factor * 0.012)

	if _fx_motion_blur.visible:
		var mat: ShaderMaterial = _fx_motion_blur.material
		var dir := vel.normalized() * speed_factor * 0.02
		mat.set_shader_parameter("blur_direction", dir)

	# FR-289: Sichtkegel folgt dem Spieler (Bildschirmmitte, da Kamera zentriert)
	if _fx_vision_cone != null and _fx_vision_cone.visible:
		var mat: ShaderMaterial = _fx_vision_cone.material
		mat.set_shader_parameter("light_center", Vector2(0.5, 0.5))


## FR-282: CRT-Filter umschalten (z.B. per Einstellung/Retro-Modus).
func set_crt_filter_active(active: bool) -> void:
	if _fx_crt != null:
		_fx_crt.visible = active and GameManager.shader_quality != "low"


## FR-289: Sichtkegel-Shader für Dunkelheits-Level aktivieren; folgt der
## Spielerposition auf dem Bildschirm.
func set_vision_cone_active(active: bool) -> void:
	if _fx_vision_cone != null:
		_fx_vision_cone.visible = active and GameManager.shader_quality != "low"


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
	_player.play_victory_pose()  # FR-177: Sieges-Pose während der Kino-Sequenz
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
	# FR-431: Umschaltbare FPS-Anzeige
	if _fps_label != null:
		_fps_label.visible = GameManager.fps_counter_enabled
		if _fps_label.visible:
			_fps_label.text = "%d FPS" % Engine.get_frames_per_second()

	# FR-290: Tag-/Nacht-Verlauf — langsame Oszillation zwischen Tag (0.0)
	# und Nacht (1.0), unabhängig vom Spielerzustand.
	if _daynight_material != null:
		_daynight_elapsed += delta
		var cycle_progress := (sin(_daynight_elapsed * 0.05) + 1.0) * 0.5
		_daynight_material.set_shader_parameter("cycle_progress", cycle_progress)

	# FR-270: Slow-Mo-Visualfilter — Stärke folgt der aktuellen Zeitskala
	if _fx_slowmo != null:
		var slowmo_strength := clampf(1.0 - Engine.time_scale, 0.0, 1.0)
		_fx_slowmo.visible = slowmo_strength > 0.01
		if _fx_slowmo.visible:
			var slowmo_mat: ShaderMaterial = _fx_slowmo.material
			slowmo_mat.set_shader_parameter("strength", slowmo_strength)

	if not is_instance_valid(_player):
		return

	# FR-343: Überleben-Modus — Schwerkraft steigt allmählich mit der Zeit
	if GameManager.active_game_mode == GameManager.GameMode.SURVIVAL:
		_survival_elapsed += delta
		_player.gravity_scale = _survival_base_gravity * (1.0 + _survival_elapsed * 0.01)

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
	# FR-288/294: Chromatische Aberration + Motion Blur je nach Tempo
	_update_speed_postfx(vel)

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
	GameManager.last_played_level = GameManager.current_level  # FR-238
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
	# FR-316: Hard-Mode gewährt weniger Furz-Ladungen (härtere Bedingung),
	# die Sternebewertung bleibt am ursprünglichen Level-Design gemessen
	var start_charges := _max_charges
	if GameManager.hard_mode_enabled:
		start_charges = maxi(1, _max_charges - 2)
	# FR-344: Hardcore-Modus überschreibt alles auf genau eine Ladung
	if GameManager.active_game_mode == GameManager.GameMode.HARDCORE:
		start_charges = 1
	GameManager.start_level(GameManager.current_level, start_charges)
	# FR-099: Gesamtzahl der Münzen im Level für die Fortschrittsanzeige zählen
	GameManager.set_level_coin_total(get_tree().get_nodes_in_group("coins").size())

	# HUD einrichten — zeigt die tatsächlich verfügbaren Ladungen (inkl.
	# Hard-Mode-Abzug/Extra-Ladung-Skill), nicht den rohen Level-Designwert
	_hud.set_max_charges(GameManager.max_charges)
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

	# FR-342-360: Spielmodus-spezifische Regeln anwenden
	_apply_game_mode_setup(level)

	# Kamera sofort auf den Player setzen
	_camera.global_position = _player.global_position
	_camera.make_current()


## FR-342-360: Wendet die Regeln des aktuell gewählten Spielmodus auf das
## frisch geladene Level an (Schwerkraft, Sichtbarkeit, Modifikatoren, ...).
## FR-344 (Hardcore) ist bereits über start_charges oben abgedeckt.
func _apply_game_mode_setup(level: Node2D) -> void:
	match GameManager.active_game_mode:
		GameManager.GameMode.MIRROR:
			level.scale.x = -1.0  # FR-348
		GameManager.GameMode.SURVIVAL:
			_survival_elapsed = 0.0
			_survival_base_gravity = _player.gravity_scale
		GameManager.GameMode.ENDLESS:
			# FR-342: Jede Wiederholung wird etwas schneller/schwerer
			var loop: int = GameManager.endless_loop_count
			_player.gravity_scale *= (1.0 + loop * 0.06)
			_player.fart_cooldown = maxf(0.2, _player.fart_cooldown * (1.0 - loop * 0.03))
		GameManager.GameMode.DARK:
			set_vision_cone_active(true)  # FR-357 (nutzt den FR-289-Shader)
		GameManager.GameMode.REVERSE_GRAVITY:
			_player.gravity_scale *= -1.0  # FR-358
		GameManager.GameMode.CHAOS:
			_player.gravity_scale *= 1.4       # FR-359
			_player.fart_cooldown *= 0.6
		GameManager.GameMode.NO_FUEL:
			_player.charge_regen_enabled = false  # FR-354
		GameManager.GameMode.PRACTICE:
			_checkpoint_pos = _player.global_position  # FR-360: sofortiger Neustart am Levelanfang
		GameManager.GameMode.MUTATOR:
			var modifier_id: String = AchievementManager.MODIFIERS[randi() % AchievementManager.MODIFIERS.size()]["id"]
			_apply_modifier(modifier_id)  # FR-349
		GameManager.GameMode.DAILY_SEED:
			var params := GameManager.get_daily_seed_params()
			_apply_modifier(String(params["modifier_id"]))  # FR-350
		GameManager.GameMode.GHOST_RACE:
			_spawn_ghost_runner()  # FR-353
		GameManager.GameMode.BOSS_RUSH:
			for boss in get_tree().get_nodes_in_group("bosses"):
				if boss.has_method("double_difficulty"):
					boss.double_difficulty()  # FR-347


## FR-331/349/350: Wendet einen der Herausforderungs-Modifikatoren
## (siehe AchievementManager.MODIFIERS) auf das laufende Level an.
func _apply_modifier(modifier_id: String) -> void:
	match modifier_id:
		"low_gravity":
			_player.gravity_scale *= 0.4
		"double_speed":
			_player.fart_power *= 1.6
		"no_regen":
			_player.charge_regen_enabled = false
		"single_fart":
			GameManager.max_charges = 1
			GameManager.charges_remaining = 1
			_hud.set_max_charges(1)
		_:
			pass  # "none" -> kein Effekt


## FR-353: Setzt einen halbtransparenten Geister-Läufer, der die
## aufgezeichnete Spur der Bestzeit dieses Levels abspielt (falls vorhanden).
func _spawn_ghost_runner() -> void:
	var path := GameManager.get_ghost_path(GameManager.current_level)
	if path.is_empty():
		return
	var ghost := GhostRunner.new()
	_level_container.add_child(ghost)
	ghost.set_path(path)


# --- FR-265: Kamera-Wackeln ------------------------------------
func _camera_shake(strength: float, duration: float) -> void:
	# FR-189/423: Globale Rüttel-Intensität, komplett unterdrückt im
	# Reduzierte-Bewegung-Modus
	if GameManager.reduced_motion_enabled:
		return
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
	if GameManager.reduced_motion_enabled or GameManager.camera_shake_intensity <= 0.0:
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
	_hud.dismiss_tutorial_hint()  # FR-210: Hinweis beim ersten Zielen ausblenden


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
	# FR-333: Verstecktes Erfolgs-Achievement für den allerersten Tod
	if GameManager.stat_total_deaths == 0:
		AchievementManager.report_first_death()
	GameManager.record_death()  # FR-226: Statistik

	# FR-343: Überleben-Modus endet mit dem Tod — Bestzeit sichern
	if GameManager.active_game_mode == GameManager.GameMode.SURVIVAL:
		GameManager.survival_best_time = maxf(GameManager.survival_best_time, _survival_elapsed)
	# FR-342/356: Ein Tod beendet den Endlos-/Marathon-Lauf — von vorn beginnen
	if GameManager.active_game_mode == GameManager.GameMode.ENDLESS:
		GameManager.endless_loop_count = 0
	if GameManager.active_game_mode == GameManager.GameMode.MARATHON:
		GameManager.marathon_level_index = 1
		GameManager.current_level = 1

	# FR-135: Am Checkpoint wiederbeleben, falls einer aktiviert wurde
	if _checkpoint_pos.x < INF:
		_player.revive(_checkpoint_pos)
		_level_finished = false
	else:
		GameManager.reload_scene_with_wipe()  # FR-276


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

	# FR-219: Versuch in die lokale Rang-Historie eintragen
	GameManager.record_attempt_time(GameManager.current_level, time_sec)

	# FR-224: Erspielten Punktestand als dauerhaftes Guthaben einzahlen
	GameManager.bank_level_coins(GameManager.total_score)

	# FR-321/324-330: Erfolge/Herausforderungen anhand des Versuchs prüfen
	AchievementManager.report_level_complete(
		stars, GameManager.total_coins, GameManager.level_farts_used,
		time_sec, _player.took_hit_this_run
	)

	# FR-353: Geister-Pfad speichern, falls dies eine neue Bestzeit ist
	if GameManager.active_game_mode == GameManager.GameMode.GHOST_RACE:
		var prev_best := GameManager.get_best_attempt_time(GameManager.current_level)
		if prev_best < 0.0 or time_sec < prev_best:
			GameManager.store_ghost_path(GameManager.current_level, _player.ghost_path_recorded)

	# FR-346: Münzjagd-Bestwert aktualisieren
	if GameManager.active_game_mode == GameManager.GameMode.COIN_HUNT:
		GameManager.coin_hunt_best_score = maxi(GameManager.coin_hunt_best_score, GameManager.total_coins)

	# FR-404: Auto-Speichern nach jedem abgeschlossenen Level
	SaveManager.save_now()

	# FR-342: Endlos-Modus — Level statt eines Abschlussbildschirms sofort
	# mit steigendem Tempo wiederholen
	if GameManager.active_game_mode == GameManager.GameMode.ENDLESS:
		GameManager.endless_loop_count += 1
		GameManager.endless_best_loops = maxi(GameManager.endless_best_loops, GameManager.endless_loop_count)
		GameManager.reload_scene_with_wipe()
		return

	# FR-356: Marathon-Modus — direkt zum nächsten Level ohne Zwischenstopp
	if GameManager.active_game_mode == GameManager.GameMode.MARATHON \
			and GameManager.marathon_level_index < GameManager.TOTAL_LEVELS:
		GameManager.marathon_level_index += 1
		GameManager.current_level = GameManager.marathon_level_index
		GameManager.reload_scene_with_wipe()
		return

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
	GameManager.reload_scene_with_wipe()  # FR-276


func _on_retry() -> void:
	GameManager.reload_scene_with_wipe()  # FR-276


func _on_menu() -> void:
	GameManager.change_scene_with_wipe("res://scenes/MainMenu.tscn")  # FR-276


# --- Hilfsfunktion: ersten Knoten einer Gruppe im Baum finden ---
func _find_in_group(root: Node, group_name: String) -> Node:
	if root.is_in_group(group_name):
		return root
	for child in root.get_children():
		var found := _find_in_group(child, group_name)
		if found != null:
			return found
	return null
