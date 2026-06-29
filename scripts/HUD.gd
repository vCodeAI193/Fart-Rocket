extends CanvasLayer
class_name HUD
## HUD – Heads-Up-Display
## =====================
## Zeigt während des Spiels an:
##  - Übrige Furz-Ladungen als Icons (grüne Wölkchen)
##  - Münzzähler
##  - Verstrichene Zeit (Timer)
## Reagiert über Signale auf Änderungen im GameManager.

signal fart_type_selected(index)             # Spieler hat einen Furz-Typ gewählt (FR-002)

@onready var _charges_box: HBoxContainer = $Root/ChargesBox
@onready var _coin_label: Label = $Root/CoinBox/CoinLabel
@onready var _timer_label: Label = $Root/TimerLabel
@onready var _fart_types_box: HBoxContainer = $Root/FartTypesBox
@onready var _pause_btn: Button = $Root/PauseButton       # FR-201
@onready var _combo_label: Label = $Root/ComboLabel       # FR-003
@onready var _speed_label: Label = $Root/SpeedLabel       # FR-204

var _max_charges: int = 0
var _charge_icons: Array[ColorRect] = []
var _fart_type_buttons: Array[Button] = []

var _elapsed: float = 0.0
var _timer_running: bool = false
var _is_paused: bool = false                               # FR-201

# FR-205: Höhenanzeige
var _height_label: Label
# FR-206: Power-up-Status-Icons
var _powerup_box: HBoxContainer
var _shield_icon: ColorRect
var _double_coins_icon: ColorRect
var _slowmo_icon: ColorRect
# FR-214: Stern-Vorschau & FR-302: Sterne-Zähler
var _stars_label: Label
var _total_stars_label: Label
# FR-209: Treffer-Vignette
var _vignette: ColorRect
# FR-212: Checkpoint-Benachrichtigung
var _checkpoint_label: Label


func _ready() -> void:
	# HUD bleibt auch im Pause-Modus aktiv
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Auf globale Zustandsänderungen lauschen
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.charges_changed.connect(_on_charges_changed)
	GameManager.charge_regen_progress.connect(_on_regen_progress)
	GameManager.combo_changed.connect(_on_combo_changed)   # FR-003
	_pause_btn.pressed.connect(_on_pause_pressed)          # FR-201
	_on_coins_changed(GameManager.total_coins)
	_build_height_label()
	_build_powerup_icons()
	_build_star_preview()
	_build_vignette()
	_build_checkpoint_label()
	# FR-206: Auf Schild- und Doppelmünzen-Signale lauschen
	GameManager.double_coins_changed.connect(_on_double_coins_changed)


## FR-205: Höhenanzeige aufbauen (links oben, unterhalb der Ladungen).
func _build_height_label() -> void:
	_height_label = Label.new()
	_height_label.add_theme_font_size_override("font_size", 30)
	_height_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	_height_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_height_label.offset_left = 20.0
	_height_label.offset_bottom = -20.0
	_height_label.offset_top = -60.0
	_height_label.offset_right = 300.0
	add_child(_height_label)


## FR-206: Power-up-Icons (Schild, Doppelmünzen, Zeitlupe) rechts unten.
func _build_powerup_icons() -> void:
	_powerup_box = HBoxContainer.new()
	_powerup_box.add_theme_constant_override("separation", 10)
	_powerup_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_powerup_box.offset_right = -20.0
	_powerup_box.offset_bottom = -20.0
	_powerup_box.offset_left = -300.0
	_powerup_box.offset_top = -72.0
	add_child(_powerup_box)

	_shield_icon = _make_icon(Color(0.3, 0.7, 1.0), "S")
	_double_coins_icon = _make_icon(Color(1.0, 0.85, 0.1), "x2")
	_slowmo_icon = _make_icon(Color(0.7, 0.3, 1.0), "Z")
	_powerup_box.add_child(_shield_icon)
	_powerup_box.add_child(_double_coins_icon)
	_powerup_box.add_child(_slowmo_icon)
	# Alle Icons zunächst ausblenden
	_shield_icon.modulate.a = 0.0
	_double_coins_icon.modulate.a = 0.0
	_slowmo_icon.modulate.a = 0.0


## FR-214/302: Stern-Anzeigen (aktuelle Level + Gesamt-Sterne) aufbauen.
func _build_star_preview() -> void:
	# Aktuelle Level-Sterne (rechts oben)
	_stars_label = Label.new()
	_stars_label.add_theme_font_size_override("font_size", 32)
	_stars_label.add_theme_color_override("font_color", Color(1, 0.82, 0.15))
	_stars_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_stars_label.offset_left = -120.0
	_stars_label.offset_top = 20.0
	_stars_label.offset_right = -20.0
	_stars_label.offset_bottom = 60.0
	add_child(_stars_label)
	# Gesamtsterne (rechts unten)
	_total_stars_label = Label.new()
	_total_stars_label.add_theme_font_size_override("font_size", 28)
	_total_stars_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_total_stars_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_total_stars_label.offset_left = -140.0
	_total_stars_label.offset_bottom = -150.0
	_total_stars_label.offset_right = -20.0
	_total_stars_label.offset_top = -50.0
	add_child(_total_stars_label)


## FR-214: Aktuelle Sterne für dieses Level anzeigen.
func set_level_stars(current: int, max_stars: int = 3) -> void:
	if _stars_label == null:
		return
	_stars_label.text = "★".repeat(current) + "☆".repeat(max_stars - current)


## FR-302: Gesamtzahl aller gesammelten Sterne anzeigen.
func update_total_stars() -> void:
	if _total_stars_label == null:
		return
	var total := 0
	for lvl in GameManager.level_stars.values():
		total += lvl
	_total_stars_label.text = "Sterne: %d / %d" % [total, GameManager.TOTAL_LEVELS * 3]


func _make_icon(col: Color, text: String) -> ColorRect:
	var cr := ColorRect.new()
	cr.custom_minimum_size = Vector2(56, 56)
	cr.color = col
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.offset_left = -22.0
	lbl.offset_right = 22.0
	lbl.offset_top = -16.0
	lbl.offset_bottom = 16.0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cr.add_child(lbl)
	return cr


## FR-209: Rote Vignette beim Treffer.
func _build_vignette() -> void:
	_vignette = ColorRect.new()
	_vignette.color = Color(1.0, 0.1, 0.1, 0.0)
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)


## FR-212: Checkpoint-Meldung (kurz sichtbar, dann ausblenden).
func _build_checkpoint_label() -> void:
	_checkpoint_label = Label.new()
	_checkpoint_label.text = "CHECKPOINT!"
	_checkpoint_label.add_theme_font_size_override("font_size", 54)
	_checkpoint_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	_checkpoint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_checkpoint_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_checkpoint_label.offset_top = 120.0
	_checkpoint_label.offset_bottom = 190.0
	_checkpoint_label.offset_left = -300.0
	_checkpoint_label.offset_right = 300.0
	_checkpoint_label.modulate.a = 0.0
	add_child(_checkpoint_label)


func _process(delta: float) -> void:
	if _timer_running:
		_elapsed += delta
		_timer_label.text = _format_time(_elapsed)


## Vom Level/Main aufgerufen: Anzahl der Furz-Icons festlegen.
func set_max_charges(value: int) -> void:
	_max_charges = value
	# Vorhandene Icons entfernen
	for icon in _charge_icons:
		icon.queue_free()
	_charge_icons.clear()
	# Neue Icons erzeugen (grüne Wölkchen)
	for i in range(_max_charges):
		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(44, 44)
		icon.color = Color(0.45, 0.85, 0.35)
		_charges_box.add_child(icon)
		_charge_icons.append(icon)


## Startet den Level-Timer.
func start_timer() -> void:
	_elapsed = 0.0
	_timer_running = true


## Stoppt den Timer und gibt die verstrichene Zeit zurück.
func stop_timer() -> float:
	_timer_running = false
	return _elapsed


## FR-002: Baut die Auswahl-Buttons für die Furz-Typen auf.
func setup_fart_types(types: Array, current_index: int) -> void:
	for btn in _fart_type_buttons:
		btn.queue_free()
	_fart_type_buttons.clear()

	for i in range(types.size()):
		var data: Dictionary = types[i]
		var btn := Button.new()
		btn.text = str(data["name"])
		btn.custom_minimum_size = Vector2(200, 76)
		btn.add_theme_font_size_override("font_size", 34)
		# Einfärbung passend zum Furz-Typ
		btn.add_theme_color_override("font_color", data["color"])
		btn.pressed.connect(_on_fart_type_button.bind(i))
		_fart_types_box.add_child(btn)
		_fart_type_buttons.append(btn)

	highlight_fart_type(current_index)


## FR-002: Hebt den aktiven Furz-Typ-Button hervor.
func highlight_fart_type(index: int) -> void:
	for i in range(_fart_type_buttons.size()):
		# Aktiver Button voll sichtbar, inaktive abgedunkelt
		_fart_type_buttons[i].modulate = Color.WHITE if i == index else Color(0.6, 0.6, 0.6)


func _on_fart_type_button(index: int) -> void:
	fart_type_selected.emit(index)


## FR-204: Aktualisiert die Geschwindigkeitsanzeige.
func set_speed(speed_px: float) -> void:
	# Pixel/s in lesbare "m/s" umrechnen (100 px = 1 m)
	_speed_label.text = "%d m/s" % int(speed_px / 100.0)


## FR-205: Aktualisiert die Höhenanzeige (Y-Position des Spielers in Weltkoordinaten).
func set_player_height(world_y: float) -> void:
	# Höhe wächst nach oben (negatives Y in Godot)
	var meters := int(-world_y / 100.0)
	_height_label.text = "%d m" % meters


## FR-209: Kurze rote Vignette beim Treffer anzeigen.
func flash_damage() -> void:
	var tween := create_tween()
	tween.tween_property(_vignette, "color:a", 0.55, 0.05)
	tween.tween_property(_vignette, "color:a", 0.0, 0.35)


## FR-206: Schild-Icon ein-/ausblenden.
func set_shield_active(active: bool) -> void:
	if _shield_icon == null:
		return
	_shield_icon.modulate.a = 1.0 if active else 0.0


## FR-206: Doppelmünzen-Signal-Handler.
func _on_double_coins_changed(active: bool) -> void:
	if _double_coins_icon == null:
		return
	_double_coins_icon.modulate.a = 1.0 if active else 0.0


## FR-212: Checkpoint-Meldung kurz einblenden.
func show_checkpoint_msg() -> void:
	var tween := create_tween()
	tween.tween_property(_checkpoint_label, "modulate:a", 1.0, 0.15)
	tween.tween_interval(0.9)
	tween.tween_property(_checkpoint_label, "modulate:a", 0.0, 0.4)


## FR-233: Android Zurück-Taste pausiert das Spiel im Level.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_pause_pressed()
		get_viewport().set_input_as_handled()


## FR-201: Pausiert oder setzt das Spiel fort.
func _on_pause_pressed() -> void:
	_is_paused = not _is_paused
	get_tree().paused = _is_paused
	_pause_btn.text = "▶" if _is_paused else "⏸"


## FR-003/280: Zeigt Combo-Multiplikator kurz in der Bildschirmmitte an + Feuerwerk bei hohen Combos.
func _on_combo_changed(count: int, multiplier: int) -> void:
	if count < 2:
		_combo_label.modulate.a = 0.0
		return
	_combo_label.text = "COMBO x%d!\n%dx PUNKTE" % [count, multiplier]
	var tween := create_tween()
	tween.tween_property(_combo_label, "modulate:a", 1.0, 0.1)
	tween.tween_interval(0.55)
	tween.tween_property(_combo_label, "modulate:a", 0.0, 0.35)
	# FR-280: Feuerwerk bei hohen Combos (ab x10)
	if count >= 10:
		_spawn_combo_fireworks()


## FR-280: Feuerwerk-Effekt für hohe Combos.
func _spawn_combo_fireworks() -> void:
	for i in range(4):
		var p := CPUParticles2D.new()
		p.global_position = get_viewport_rect().get_center()
		p.emitting = true
		p.one_shot = true
		p.explosiveness = 0.95
		p.amount = 40
		p.lifetime = 1.2
		p.initial_velocity_min = 150.0
		p.initial_velocity_max = 400.0
		p.gravity = Vector2(0, 200)
		p.scale_amount_min = 3.0
		p.scale_amount_max = 8.0
		var cols := [Color(1.0, 0.85, 0.2), Color(1.0, 0.5, 0.1), Color(1.0, 0.3, 0.2)]
		p.color = cols[i % cols.size()]
		add_child(p)
		get_tree().create_timer(1.5).timeout.connect(
			func() -> void:
				if is_instance_valid(p):
					p.queue_free()
		)


# --- Hilfsfunktionen ---
func _format_time(t: float) -> String:
	var minutes := int(t) / 60
	var seconds := int(t) % 60
	return "%02d:%02d" % [minutes, seconds]


# --- Signal-Handler ---------------------------------------------
func _on_coins_changed(total: int) -> void:
	# FR-202: Animierte Münzzähler-Aktualisierung (kurzes Aufleuchten)
	_coin_label.text = "x %d" % total
	var tween := create_tween()
	tween.tween_property(_coin_label, "scale", Vector2(1.25, 1.25), 0.08)
	tween.tween_property(_coin_label, "scale", Vector2(1.0, 1.0), 0.12)


func _on_charges_changed(remaining: int) -> void:
	# Verbrauchte Ladungen ausgrauen
	for i in range(_charge_icons.size()):
		if i < remaining:
			_charge_icons[i].color = Color(0.45, 0.85, 0.35)      # aktiv (grün)
		else:
			_charge_icons[i].color = Color(0.3, 0.3, 0.3, 0.5)    # verbraucht


## FR-001: Füllt das nächste (nachladende) Icon entsprechend dem Fortschritt.
func _on_regen_progress(fraction: float) -> void:
	var idx := GameManager.charges_remaining
	if idx < 0 or idx >= _charge_icons.size():
		return
	# Von "verbraucht" (blass) zu "aktiv" (grün) überblenden
	_charge_icons[idx].color = Color(0.45, 0.85, 0.35, lerpf(0.25, 1.0, fraction))


# --- Hilfsfunktionen --------------------------------------------
func _format_time(t: float) -> String:
	var minutes := int(t) / 60
	var seconds := int(t) % 60
	return "%02d:%02d" % [minutes, seconds]
