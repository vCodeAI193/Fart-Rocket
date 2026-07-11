extends CanvasLayer
class_name SettingsScreen
## SettingsScreen – Einstellungs-Overlay
## =======================================
## FR-222: Zeigt Einstellungen (Haptik, Stummschalten).
## Wird als Overlay über dem Hauptmenü eingeblendet.

signal closed

var _panel: PanelContainer
var _haptics_btn: Button
var _mute_btn: Button
# FR-059: Steuerungs-Kalibrierung
var _scheme_btn: Button
var _handed_btn: Button
var _sensitivity_btn: Button
var _deadzone_btn: Button
# FR-189/200: Kamera-Einstellungen
var _shake_btn: Button
var _smoothing_btn: Button
# FR-215/216: HUD-Einstellungen
var _minimal_hud_btn: Button
var _hud_scale_btn: Button


func _ready() -> void:
	# Unsichtbar starten
	visible = false
	layer = 10
	_build_ui()


func show_settings() -> void:
	visible = true
	_update_buttons()


func _build_ui() -> void:
	# Halbtransparenter dunkler Hintergrund
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(560, 780)
	_panel.offset_left = -280.0
	_panel.offset_top = -390.0
	_panel.offset_right = 280.0
	_panel.offset_bottom = 390.0
	add_child(_panel)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Titel
	var title := Label.new()
	title.text = "Einstellungen"
	title.add_theme_font_size_override("font_size", 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Haptik-Toggle
	_haptics_btn = Button.new()
	_haptics_btn.custom_minimum_size = Vector2(400, 76)
	_haptics_btn.add_theme_font_size_override("font_size", 34)
	_haptics_btn.pressed.connect(_on_haptics_pressed)
	vbox.add_child(_haptics_btn)

	# Ton-Toggle
	_mute_btn = Button.new()
	_mute_btn.custom_minimum_size = Vector2(400, 76)
	_mute_btn.add_theme_font_size_override("font_size", 34)
	_mute_btn.pressed.connect(_on_mute_pressed)
	vbox.add_child(_mute_btn)

	# --- FR-059: Steuerungs-Kalibrierung ---------------------------
	var control_title := Label.new()
	control_title.text = "Steuerung"
	control_title.add_theme_font_size_override("font_size", 30)
	control_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(control_title)

	# FR-042: Steuerschema
	_scheme_btn = Button.new()
	_scheme_btn.custom_minimum_size = Vector2(400, 76)
	_scheme_btn.add_theme_font_size_override("font_size", 30)
	_scheme_btn.pressed.connect(_on_scheme_pressed)
	vbox.add_child(_scheme_btn)

	# FR-043: Linkshänder-Modus
	_handed_btn = Button.new()
	_handed_btn.custom_minimum_size = Vector2(400, 76)
	_handed_btn.add_theme_font_size_override("font_size", 30)
	_handed_btn.pressed.connect(_on_handed_pressed)
	vbox.add_child(_handed_btn)

	# FR-044: Touch-Empfindlichkeit
	_sensitivity_btn = Button.new()
	_sensitivity_btn.custom_minimum_size = Vector2(400, 76)
	_sensitivity_btn.add_theme_font_size_override("font_size", 30)
	_sensitivity_btn.pressed.connect(_on_sensitivity_pressed)
	vbox.add_child(_sensitivity_btn)

	# FR-044: Dead-Zone
	_deadzone_btn = Button.new()
	_deadzone_btn.custom_minimum_size = Vector2(400, 76)
	_deadzone_btn.add_theme_font_size_override("font_size", 30)
	_deadzone_btn.pressed.connect(_on_deadzone_pressed)
	vbox.add_child(_deadzone_btn)

	# --- FR-189/200: Kamera-Einstellungen --------------------------
	var camera_title := Label.new()
	camera_title.text = "Kamera"
	camera_title.add_theme_font_size_override("font_size", 30)
	camera_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(camera_title)

	_shake_btn = Button.new()
	_shake_btn.custom_minimum_size = Vector2(400, 76)
	_shake_btn.add_theme_font_size_override("font_size", 30)
	_shake_btn.pressed.connect(_on_shake_pressed)
	vbox.add_child(_shake_btn)

	_smoothing_btn = Button.new()
	_smoothing_btn.custom_minimum_size = Vector2(400, 76)
	_smoothing_btn.add_theme_font_size_override("font_size", 30)
	_smoothing_btn.pressed.connect(_on_smoothing_pressed)
	vbox.add_child(_smoothing_btn)

	# --- FR-215/216: HUD-Einstellungen -----------------------------
	var hud_title := Label.new()
	hud_title.text = "HUD"
	hud_title.add_theme_font_size_override("font_size", 30)
	hud_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hud_title)

	_minimal_hud_btn = Button.new()
	_minimal_hud_btn.custom_minimum_size = Vector2(400, 76)
	_minimal_hud_btn.add_theme_font_size_override("font_size", 30)
	_minimal_hud_btn.pressed.connect(_on_minimal_hud_pressed)
	vbox.add_child(_minimal_hud_btn)

	_hud_scale_btn = Button.new()
	_hud_scale_btn.custom_minimum_size = Vector2(400, 76)
	_hud_scale_btn.add_theme_font_size_override("font_size", 30)
	_hud_scale_btn.pressed.connect(_on_hud_scale_pressed)
	vbox.add_child(_hud_scale_btn)

	# Schliessen-Button
	var close_btn := Button.new()
	close_btn.text = "Schliessen"
	close_btn.custom_minimum_size = Vector2(400, 80)
	close_btn.add_theme_font_size_override("font_size", 38)
	close_btn.pressed.connect(_on_close_pressed)
	vbox.add_child(close_btn)

	_update_buttons()


func _update_buttons() -> void:
	if _haptics_btn == null:
		return
	_haptics_btn.text = "Haptik: EIN" if GameManager.haptics_enabled else "Haptik: AUS"
	_mute_btn.text = "Ton: AN" if not GameManager.sound_muted else "Ton: AUS"
	# FR-059
	var scheme_label := "Direkt" if GameManager.control_scheme == "direct" else "Steinschleuder"
	_scheme_btn.text = "Steuerschema: %s" % scheme_label
	_handed_btn.text = "Linkshänder: EIN" if GameManager.left_handed_mode else "Linkshänder: AUS"
	_sensitivity_btn.text = "Empfindlichkeit: %.1fx" % GameManager.touch_sensitivity
	_deadzone_btn.text = "Dead-Zone: %d px" % int(GameManager.touch_dead_zone)
	_shake_btn.text = "Kamera-Ruckeln: %d%%" % int(GameManager.camera_shake_intensity * 100)
	_smoothing_btn.text = "Kamera-Glättung: %.0f" % GameManager.camera_smoothing
	_minimal_hud_btn.text = "Minimal-HUD: EIN" if GameManager.hud_minimal_mode else "Minimal-HUD: AUS"
	_hud_scale_btn.text = "HUD-Größe: %.2fx" % GameManager.hud_scale


func _on_haptics_pressed() -> void:
	GameManager.set_haptics(not GameManager.haptics_enabled)
	_update_buttons()


func _on_mute_pressed() -> void:
	GameManager.toggle_muted()
	_update_buttons()


## FR-042: Steuerschema zwischen "direct" und "slingshot" umschalten.
func _on_scheme_pressed() -> void:
	var next := "slingshot" if GameManager.control_scheme == "direct" else "direct"
	GameManager.set_control_scheme(next)
	GameManager.vibrate(15)
	_update_buttons()


## FR-043: Linkshänder-Modus umschalten (erfordert HUD-Neuaufbau im Level).
func _on_handed_pressed() -> void:
	GameManager.set_left_handed(not GameManager.left_handed_mode)
	GameManager.vibrate(15)
	_update_buttons()


## FR-044: Touch-Empfindlichkeit in Schritten von 0.25 durchschalten (0.5..2.0).
func _on_sensitivity_pressed() -> void:
	var next := GameManager.touch_sensitivity + 0.25
	if next > 2.0:
		next = 0.5
	GameManager.set_touch_sensitivity(next)
	GameManager.vibrate(15)
	_update_buttons()


## FR-044: Dead-Zone in Schritten von 10px durchschalten (0..60).
func _on_deadzone_pressed() -> void:
	var next := GameManager.touch_dead_zone + 10.0
	if next > 60.0:
		next = 0.0
	GameManager.set_touch_dead_zone(next)
	GameManager.vibrate(15)
	_update_buttons()


## FR-189: Kamera-Rüttel-Intensität in Schritten von 50% durchschalten (0..200%).
func _on_shake_pressed() -> void:
	var next := GameManager.camera_shake_intensity + 0.5
	if next > 2.0:
		next = 0.0
	GameManager.set_camera_shake_intensity(next)
	GameManager.vibrate(15)
	_update_buttons()


## FR-200: Kamera-Glättung in Schritten von 2 durchschalten (2..16).
func _on_smoothing_pressed() -> void:
	var next := GameManager.camera_smoothing + 2.0
	if next > 16.0:
		next = 2.0
	GameManager.set_camera_smoothing(next)
	GameManager.vibrate(15)
	_update_buttons()


## FR-215: Minimalistischen HUD-Modus umschalten.
func _on_minimal_hud_pressed() -> void:
	GameManager.set_hud_minimal_mode(not GameManager.hud_minimal_mode)
	GameManager.vibrate(15)
	_update_buttons()


## FR-216: HUD-Skalierung in Schritten von 0.25 durchschalten (0.75..1.5).
func _on_hud_scale_pressed() -> void:
	var next := GameManager.hud_scale + 0.25
	if next > 1.5:
		next = 0.75
	GameManager.set_hud_scale(next)
	GameManager.vibrate(15)
	_update_buttons()


func _on_close_pressed() -> void:
	visible = false
	closed.emit()
