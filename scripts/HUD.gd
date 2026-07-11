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

@onready var _root: Control = $Root
@onready var _charges_box: HBoxContainer = $Root/ChargesBox
@onready var _coin_label: Label = $Root/CoinBox/CoinLabel
@onready var _timer_label: Label = $Root/TimerLabel
@onready var _fart_types_box: HBoxContainer = $Root/FartTypesBox
@onready var _pause_btn: Button = $Root/PauseButton       # FR-201
@onready var _combo_label: Label = $Root/ComboLabel       # FR-003
@onready var _speed_label: Label = $Root/SpeedLabel       # FR-204

var _max_charges: int = 0
var _charge_icons: Array[ColorRect] = []
var _charge_fill_overlays: Array[ColorRect] = []  # FR-208
var _last_charges_remaining: int = 0              # FR-208
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
# FR-099: Sammel-Fortschritt (x/y Münzen)
var _coin_progress_label: Label
# FR-100: Power-up-Inventar-Button
var _inventory_btn: Button
# FR-195: Foto-Modus-Button
var _photo_mode_btn: Button
# FR-051: Wisch-Geste zum Pausieren (Zwei-Finger-Swipe nach unten)
var _swipe_start: Dictionary = {}   # {finger_index: {"pos": Vector2, "time": float}}
var _swipe_last: Dictionary = {}    # {finger_index: Vector2}
# FR-207: Geist-Anzeige der Bestzeit
var _ghost_label: Label
# FR-210: Tutorial-Hinweis-Overlay
var _tutorial_hint_label: Label
# FR-211: Fortschrittsbalken zum Münz-Ziel
var _coin_progress_bar: ProgressBar
# FR-213: Sammel-Pop-ups (Screen-Space, nahe der Münzanzeige)
# (keine dauerhafte Referenz nötig, wird fire-and-forget erzeugt)
# FR-215/220: Elemente, die im Minimal-Modus ausgeblendet werden
var _secondary_elements: Array[CanvasItem] = []
# FR-219: Live-Ranglistenposition
var _rank_label: Label
var _last_coin_progress_collected: int = 0  # FR-213


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
	_build_coin_progress_label()
	_build_inventory_button()
	_build_photo_mode_button()
	_build_ghost_label()          # FR-207
	_build_tutorial_hint()        # FR-210
	_build_coin_progress_bar()    # FR-211
	_build_rank_label()           # FR-219
	# FR-215/220: Sekundäre Elemente, die im Minimal-Modus ausgeblendet werden
	_secondary_elements = [
		_height_label, _powerup_box, _stars_label, _total_stars_label,
		_coin_progress_label, _coin_progress_bar, _ghost_label, _rank_label,
	]
	_apply_safe_area()  # FR-054
	_apply_left_handed_layout()  # FR-043
	_apply_hud_settings()  # FR-215/216
	# FR-206: Auf Schild- und Doppelmünzen-Signale lauschen
	GameManager.double_coins_changed.connect(_on_double_coins_changed)
	# FR-099: Sammel-Fortschritt
	GameManager.coin_progress_changed.connect(_on_coin_progress_changed)
	# FR-100: Power-up-Inventar
	GameManager.inventory_changed.connect(_on_inventory_changed)
	# FR-215/216: HUD-Einstellungen (Minimal-Modus/Skalierung)
	GameManager.hud_settings_changed.connect(_apply_hud_settings)


## FR-099: Sammel-Fortschritt (x/y Münzen), unter der Münzanzeige.
func _build_coin_progress_label() -> void:
	_coin_progress_label = Label.new()
	_coin_progress_label.add_theme_font_size_override("font_size", 22)
	_coin_progress_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 0.85))
	_coin_progress_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_coin_progress_label.offset_left = 20.0
	_coin_progress_label.offset_top = 90.0
	_coin_progress_label.offset_right = 200.0
	_coin_progress_label.offset_bottom = 120.0
	add_child(_coin_progress_label)


func _on_coin_progress_changed(collected: int, total: int) -> void:
	_coin_progress_label.text = "%d / %d Münzen" % [collected, total]
	# FR-211: Fortschrittsbalken synchron mit dem Text aktualisieren
	if _coin_progress_bar != null:
		_coin_progress_bar.max_value = maxf(1.0, float(total))
		_coin_progress_bar.value = float(collected)
	# FR-213: Screen-Space-Pop-up nahe der Münzanzeige, wenn Münzen dazukamen
	if collected > _last_coin_progress_collected:
		_spawn_coin_popup(collected - _last_coin_progress_collected)
	_last_coin_progress_collected = collected


## FR-213: Kleines "+N"-Pop-up nahe dem Münz-Icon (Screen-Space, zusätzlich
## zur weltraum-gebundenen FloatingText direkt an der Münze).
func _spawn_coin_popup(amount: int) -> void:
	var popup := Label.new()
	popup.text = "+%d" % amount
	popup.add_theme_font_size_override("font_size", 30)
	popup.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	popup.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	popup.offset_left = -280.0
	popup.offset_top = 100.0
	popup.offset_right = -40.0
	popup.offset_bottom = 150.0
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(popup)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 40.0, 0.6)
	tween.tween_property(popup, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(popup.queue_free)


## FR-207: Geist-Anzeige — zeigt die Differenz zur persönlichen Bestzeit live an.
func _build_ghost_label() -> void:
	_ghost_label = Label.new()
	_ghost_label.add_theme_font_size_override("font_size", 24)
	_ghost_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_ghost_label.offset_left = 20.0
	_ghost_label.offset_top = 120.0
	_ghost_label.offset_right = 260.0
	_ghost_label.offset_bottom = 150.0
	add_child(_ghost_label)


## FR-207: Aktualisiert die Geist-Anzeige (aufgerufen aus _process via set_elapsed_time).
func update_ghost_display(elapsed: float) -> void:
	if _ghost_label == null:
		return
	var best := GameManager.get_best_time(GameManager.current_level)
	if best == INF:
		_ghost_label.visible = false
		return
	_ghost_label.visible = true
	var delta_t := elapsed - best
	if delta_t <= 0.0:
		_ghost_label.text = "Geist: -%.1fs 👻" % absf(delta_t)
		_ghost_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	else:
		_ghost_label.text = "Geist: +%.1fs" % delta_t
		_ghost_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))


## FR-210: Kurzer Tutorial-Hinweis, der beim ersten Zielen ausgeblendet wird.
func _build_tutorial_hint() -> void:
	_tutorial_hint_label = Label.new()
	_tutorial_hint_label.text = "Ziehen zum Zielen, loslassen zum Furzen!"
	_tutorial_hint_label.add_theme_font_size_override("font_size", 32)
	_tutorial_hint_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	_tutorial_hint_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_tutorial_hint_label.offset_left = -300.0
	_tutorial_hint_label.offset_right = 300.0
	_tutorial_hint_label.offset_top = 220.0
	_tutorial_hint_label.offset_bottom = 270.0
	_tutorial_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_hint_label.visible = not GameManager.tutorial_hint_seen
	add_child(_tutorial_hint_label)


## FR-210: Blendet den Tutorial-Hinweis dauerhaft aus (z.B. bei erstem Zielen).
func dismiss_tutorial_hint() -> void:
	if _tutorial_hint_label == null or not _tutorial_hint_label.visible:
		return
	var tween := create_tween()
	tween.tween_property(_tutorial_hint_label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): _tutorial_hint_label.visible = false)
	GameManager.mark_tutorial_hint_seen()


## FR-211: Fortschrittsbalken zum Münz-Sammelziel, unter dem x/y-Text.
func _build_coin_progress_bar() -> void:
	_coin_progress_bar = ProgressBar.new()
	_coin_progress_bar.show_percentage = false
	_coin_progress_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_coin_progress_bar.offset_left = 20.0
	_coin_progress_bar.offset_top = 122.0
	_coin_progress_bar.offset_right = 200.0
	_coin_progress_bar.offset_bottom = 132.0
	add_child(_coin_progress_bar)


## FR-219: Live-Ranglistenposition (lokale Versuchs-Historie) oben mittig.
func _build_rank_label() -> void:
	_rank_label = Label.new()
	_rank_label.add_theme_font_size_override("font_size", 22)
	_rank_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 0.85))
	_rank_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_rank_label.offset_left = -100.0
	_rank_label.offset_right = 100.0
	_rank_label.offset_top = 118.0
	_rank_label.offset_bottom = 148.0
	_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_rank_label)


## FR-219: Aktualisiert den Live-Rang anhand der bisherigen Versuchs-Historie.
func update_rank_display(elapsed: float) -> void:
	if _rank_label == null:
		return
	var attempts: Array = GameManager.level_attempt_times.get(GameManager.current_level, [])
	if attempts.is_empty():
		_rank_label.visible = false
		return
	_rank_label.visible = true
	var rank := GameManager.get_live_rank(GameManager.current_level, elapsed)
	_rank_label.text = "Rang #%d von %d" % [rank, attempts.size() + 1]


## FR-215/216: Wendet Minimal-Modus (Sichtbarkeit) und HUD-Skalierung an.
func _apply_hud_settings() -> void:
	for el in _secondary_elements:
		if is_instance_valid(el):
			el.visible = not GameManager.hud_minimal_mode
	var vp_size := get_viewport().get_visible_rect().size
	var pivot := vp_size * 0.5
	var s := GameManager.hud_scale
	# FR-216: Skaliert die gesamte HUD-Ebene um die Bildschirmmitte, damit
	# rand-verankerte Elemente bei größerer Skalierung nicht zu weit
	# aus dem sichtbaren Bereich wandern.
	transform = Transform2D(0.0, Vector2.ONE * s, 0.0, pivot * (1.0 - s))


## FR-100: Inventar-Button (Mitte unten), zeigt gespeichertes Power-up.
func _build_inventory_button() -> void:
	_inventory_btn = Button.new()
	_inventory_btn.text = ""
	_inventory_btn.custom_minimum_size = Vector2(100, 100)
	_inventory_btn.add_theme_font_size_override("font_size", 26)
	_inventory_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_inventory_btn.offset_left = -50.0
	_inventory_btn.offset_right = 50.0
	_inventory_btn.offset_top = -130.0
	_inventory_btn.offset_bottom = -30.0
	_inventory_btn.disabled = true
	_inventory_btn.modulate.a = 0.35
	_inventory_btn.pressed.connect(_on_inventory_button_pressed)
	add_child(_inventory_btn)


func _on_inventory_changed(stored_type: String) -> void:
	if stored_type == "":
		_inventory_btn.text = ""
		_inventory_btn.disabled = true
		_inventory_btn.modulate.a = 0.35
	else:
		var label := {"shield": "Schild", "slowmo": "Zeitlupe", "double_coins": "x2"}.get(stored_type, stored_type)
		_inventory_btn.text = label
		_inventory_btn.disabled = false
		_inventory_btn.modulate.a = 1.0


func _on_inventory_button_pressed() -> void:
	GameManager.use_stored_powerup()


## FR-054: Schiebt den HUD-Root um die Geräte-Safe-Area ein (Notch/Ecken).
func _apply_safe_area() -> void:
	var screen_size := DisplayServer.screen_get_size()
	var safe_rect := DisplayServer.get_display_safe_area()
	if screen_size.x <= 0 or screen_size.y <= 0:
		return
	var left_inset := safe_rect.position.x
	var top_inset := safe_rect.position.y
	var right_inset := screen_size.x - (safe_rect.position.x + safe_rect.size.x)
	var bottom_inset := screen_size.y - (safe_rect.position.y + safe_rect.size.y)
	if left_inset <= 0 and top_inset <= 0 and right_inset <= 0 and bottom_inset <= 0:
		return  # kein Notch/Rand vorhanden
	_root.offset_left += left_inset
	_root.offset_top += top_inset
	_root.offset_right -= right_inset
	_root.offset_bottom -= bottom_inset


## FR-043/217: Spiegelt die seitlich angedockten HUD-Elemente für Linkshänder.
func _apply_left_handed_layout() -> void:
	if not GameManager.left_handed_mode:
		return
	for path in ["ChargesBox", "ChargesLabel", "CoinBox", "PauseButton"]:
		var node := _root.get_node_or_null(path)
		if node is Control:
			_mirror_control_horizontally(node)
	# FR-217: Auch die dynamisch erzeugten, seitlich angedockten Elemente spiegeln
	for ctrl in [_coin_progress_label, _coin_progress_bar, _photo_mode_btn, _inventory_btn]:
		if ctrl != null:
			_mirror_control_horizontally(ctrl)


## FR-043: Spiegelt Anker/Offsets eines Controls horizontal innerhalb des Root.
func _mirror_control_horizontally(ctrl: Control) -> void:
	var new_anchor_left := 1.0 - ctrl.anchor_right
	var new_anchor_right := 1.0 - ctrl.anchor_left
	var new_offset_left := -ctrl.offset_right
	var new_offset_right := -ctrl.offset_left
	ctrl.anchor_left = new_anchor_left
	ctrl.anchor_right = new_anchor_right
	ctrl.offset_left = new_offset_left
	ctrl.offset_right = new_offset_right


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
		update_ghost_display(_elapsed)  # FR-207
		update_rank_display(_elapsed)   # FR-219


## Vom Level/Main aufgerufen: Anzahl der Furz-Icons festlegen.
func set_max_charges(value: int) -> void:
	_max_charges = value
	# Vorhandene Icons entfernen
	for icon in _charge_icons:
		icon.queue_free()
	_charge_icons.clear()
	_charge_fill_overlays.clear()
	_last_charges_remaining = value
	# Neue Icons erzeugen (grüne Wölkchen)
	for i in range(_max_charges):
		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(44, 44)
		icon.color = Color(0.45, 0.85, 0.35)
		_charges_box.add_child(icon)
		_charge_icons.append(icon)
		# FR-208: Fortschritts-Overlay für die Nachfüll-Animation (wächst von unten)
		var fill := ColorRect.new()
		fill.color = Color(1.0, 1.0, 0.6, 0.55)
		fill.size = Vector2(44, 0)
		fill.position = Vector2(0, 44)
		icon.add_child(fill)
		_charge_fill_overlays.append(fill)


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
## FR-051: Zwei-Finger-Swipe nach unten pausiert ebenfalls (stört das
## Zielen nicht, da der Spieler nur auf den ERSTEN Finger reagiert).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_pause_pressed()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_swipe_start[event.index] = {"pos": event.position, "time": Time.get_ticks_msec() / 1000.0}
			_swipe_last[event.index] = event.position
		else:
			if _swipe_start.size() == 2 and _swipe_start.has(event.index):
				if _check_swipe_pause_gesture():
					# Verhindert, dass dieselbe Loslass-Bewegung beim Spieler
					# noch einen ungewollten Furz-Stoß auslöst.
					get_viewport().set_input_as_handled()
			_swipe_start.erase(event.index)
			_swipe_last.erase(event.index)
	elif event is InputEventScreenDrag and _swipe_last.has(event.index):
		_swipe_last[event.index] = event.position


## FR-051: Prüft, ob beide Finger schnell und deutlich nach unten gewischt
## wurden. Gibt true zurück, wenn die Geste erkannt wurde (und pausiert dabei).
func _check_swipe_pause_gesture() -> bool:
	var total_down_movement := 0.0
	var max_elapsed := 0.0
	for idx in _swipe_start.keys():
		var start_data: Dictionary = _swipe_start[idx]
		var last_pos: Vector2 = _swipe_last.get(idx, start_data["pos"])
		var delta_y := last_pos.y - start_data["pos"].y
		var delta_x := absf(last_pos.x - start_data["pos"].x)
		# Nur werten, wenn die Bewegung überwiegend vertikal nach unten ging
		if delta_y > 0 and delta_y > delta_x:
			total_down_movement += delta_y
		var elapsed := Time.get_ticks_msec() / 1000.0 - start_data["time"]
		max_elapsed = maxf(max_elapsed, elapsed)

	if total_down_movement / 2.0 > 120.0 and max_elapsed < 0.5:
		_on_pause_pressed()
		return true
	return false


## FR-201: Pausiert oder setzt das Spiel fort.
func _on_pause_pressed() -> void:
	_is_paused = not _is_paused
	get_tree().paused = _is_paused
	_pause_btn.text = "▶" if _is_paused else "⏸"
	# FR-195: Foto-Modus-Button nur im Pause-Zustand anzeigen
	if _photo_mode_btn != null:
		_photo_mode_btn.visible = _is_paused
		if not _is_paused:
			# Variant statt statischem Typ, da Node/Main hier nur per Duck-Typing
			# (has_method) angesprochen wird und nicht jede Szene ein Main ist.
			var main = get_parent()
			if main != null and main.has_method("is_photo_mode") and main.is_photo_mode():
				main.toggle_photo_mode()  # Foto-Modus beim Fortsetzen automatisch beenden


## FR-195: Button zum Umschalten des Foto-/Replay-Kameramodus (nur bei Pause sichtbar).
func _build_photo_mode_button() -> void:
	_photo_mode_btn = Button.new()
	_photo_mode_btn.text = "📷 Foto-Modus"
	_photo_mode_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_photo_mode_btn.custom_minimum_size = Vector2(240, 70)
	_photo_mode_btn.add_theme_font_size_override("font_size", 26)
	_photo_mode_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_photo_mode_btn.offset_left = -300.0
	_photo_mode_btn.offset_top = 210.0
	_photo_mode_btn.offset_right = -40.0
	_photo_mode_btn.offset_bottom = 280.0
	_photo_mode_btn.visible = false
	_photo_mode_btn.pressed.connect(_on_photo_mode_pressed)
	add_child(_photo_mode_btn)


func _on_photo_mode_pressed() -> void:
	var main = get_parent()
	if main != null and main.has_method("toggle_photo_mode"):
		main.toggle_photo_mode()
		GameManager.vibrate(15)


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
		if i < _charge_fill_overlays.size():
			_charge_fill_overlays[i].size.y = 0.0

	# FR-208: Kleiner "Pop", wenn eine Ladung frisch aufgefüllt wurde
	if remaining > _last_charges_remaining and remaining - 1 < _charge_icons.size():
		var refreshed := _charge_icons[remaining - 1]
		var tween := create_tween()
		tween.tween_property(refreshed, "scale", Vector2(1.35, 1.35), 0.1)
		tween.tween_property(refreshed, "scale", Vector2.ONE, 0.15)
	_last_charges_remaining = remaining


## FR-001/208: Füllt das nächste (nachladende) Icon entsprechend dem
## Fortschritt — sowohl per Farb-Überblendung als auch per wachsendem
## Balken-Overlay von unten nach oben (Nachfüll-Animation).
func _on_regen_progress(fraction: float) -> void:
	var idx := GameManager.charges_remaining
	if idx < 0 or idx >= _charge_icons.size():
		return
	# Von "verbraucht" (blass) zu "aktiv" (grün) überblenden
	_charge_icons[idx].color = Color(0.45, 0.85, 0.35, lerpf(0.25, 1.0, fraction))
	if idx < _charge_fill_overlays.size():
		var fill := _charge_fill_overlays[idx]
		fill.size.y = 44.0 * fraction
		fill.position.y = 44.0 - fill.size.y


# --- Hilfsfunktionen --------------------------------------------
func _format_time(t: float) -> String:
	var minutes := int(t) / 60
	var seconds := int(t) % 60
	return "%02d:%02d" % [minutes, seconds]
