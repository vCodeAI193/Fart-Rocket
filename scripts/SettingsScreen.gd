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
# FR-228: Bestätigungsdialog für den Fortschritts-Reset
var _confirm_dialog: ConfirmDialog
# FR-282/291/299/300: Grafik-Einstellungen
var _quality_btn: Button
var _render_scale_btn: Button
var _pixel_perfect_btn: Button
var _crt_btn: Button
var _hard_mode_btn: Button  # FR-316
var _slot_buttons: Array[Button] = []  # FR-403/418
# FR-421-440: Barrierefreiheit-Buttons
var _colorblind_btn: Button
var _contrast_btn: Button
var _motion_btn: Button
var _ui_scale_btn: Button
var _captions_btn: Button
var _one_handed_btn: Button
var _assist_aim_btn: Button
var _brightness_btn: Button
var _fps_counter_btn: Button
var _fps_limit_btn: Button
var _tap_confirm_btn: Button
var _focus_pause_btn: Button
var _difficulty_assist_btn: Button
var _volume_btn: Button
var _language_btn: Button


func _ready() -> void:
	# Unsichtbar starten
	visible = false
	layer = 10
	_build_ui()
	_confirm_dialog = preload("res://scenes/ConfirmDialog.tscn").instantiate()
	add_child(_confirm_dialog)
	# FR-424: Live-Aktualisierung, falls die UI-Skalierung während der
	# Anzeige geändert wird (z.B. über den Skalierungs-Button selbst)
	GameManager.accessibility_changed.connect(func():
		if visible:
			GameManager.apply_menu_ui_scale(self, get_viewport().get_visible_rect().size)
	)


func show_settings() -> void:
	visible = true
	GameManager.apply_menu_ui_scale(self, get_viewport().get_visible_rect().size)  # FR-424
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

	# --- FR-282/291/299/300: Grafik-Einstellungen -------------------
	var graphics_title := Label.new()
	graphics_title.text = "Grafik"
	graphics_title.add_theme_font_size_override("font_size", 30)
	graphics_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(graphics_title)

	_quality_btn = Button.new()
	_quality_btn.custom_minimum_size = Vector2(400, 76)
	_quality_btn.add_theme_font_size_override("font_size", 28)
	_quality_btn.pressed.connect(_on_quality_pressed)
	vbox.add_child(_quality_btn)

	_render_scale_btn = Button.new()
	_render_scale_btn.custom_minimum_size = Vector2(400, 76)
	_render_scale_btn.add_theme_font_size_override("font_size", 28)
	_render_scale_btn.pressed.connect(_on_render_scale_pressed)
	vbox.add_child(_render_scale_btn)

	_pixel_perfect_btn = Button.new()
	_pixel_perfect_btn.custom_minimum_size = Vector2(400, 76)
	_pixel_perfect_btn.add_theme_font_size_override("font_size", 28)
	_pixel_perfect_btn.pressed.connect(_on_pixel_perfect_pressed)
	vbox.add_child(_pixel_perfect_btn)

	_crt_btn = Button.new()
	_crt_btn.custom_minimum_size = Vector2(400, 76)
	_crt_btn.add_theme_font_size_override("font_size", 28)
	_crt_btn.pressed.connect(_on_crt_pressed)
	vbox.add_child(_crt_btn)

	# --- FR-316: Hard-Mode-Umschalter -------------------------------
	_hard_mode_btn = Button.new()
	_hard_mode_btn.custom_minimum_size = Vector2(400, 76)
	_hard_mode_btn.add_theme_font_size_override("font_size", 28)
	_hard_mode_btn.pressed.connect(_on_hard_mode_pressed)
	vbox.add_child(_hard_mode_btn)

	# --- FR-421-440: Barrierefreiheit -------------------------------
	var a11y_title := Label.new()
	a11y_title.text = "Barrierefreiheit"
	a11y_title.add_theme_font_size_override("font_size", 30)
	a11y_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(a11y_title)

	_colorblind_btn = _make_settings_button(vbox, _on_colorblind_pressed)
	_contrast_btn = _make_settings_button(vbox, _on_contrast_pressed)
	_motion_btn = _make_settings_button(vbox, _on_motion_pressed)
	_ui_scale_btn = _make_settings_button(vbox, _on_ui_scale_pressed)
	_captions_btn = _make_settings_button(vbox, _on_captions_pressed)
	_one_handed_btn = _make_settings_button(vbox, _on_one_handed_pressed)
	_assist_aim_btn = _make_settings_button(vbox, _on_assist_aim_pressed)
	_brightness_btn = _make_settings_button(vbox, _on_brightness_pressed)
	_fps_counter_btn = _make_settings_button(vbox, _on_fps_counter_pressed)
	_fps_limit_btn = _make_settings_button(vbox, _on_fps_limit_pressed)
	_tap_confirm_btn = _make_settings_button(vbox, _on_tap_confirm_pressed)
	_focus_pause_btn = _make_settings_button(vbox, _on_focus_pause_pressed)
	_difficulty_assist_btn = _make_settings_button(vbox, _on_difficulty_assist_pressed)
	_volume_btn = _make_settings_button(vbox, _on_volume_pressed)
	_language_btn = _make_settings_button(vbox, _on_language_pressed)

	var reset_settings_btn := Button.new()
	reset_settings_btn.text = "Einstellungen zurücksetzen"
	reset_settings_btn.custom_minimum_size = Vector2(400, 76)
	reset_settings_btn.add_theme_font_size_override("font_size", 26)
	reset_settings_btn.pressed.connect(_on_reset_settings_pressed)
	vbox.add_child(reset_settings_btn)

	# --- FR-403/418: Speicherplatz-Verwaltung -----------------------
	var slots_title := Label.new()
	slots_title.text = "Speicherplätze"
	slots_title.add_theme_font_size_override("font_size", 30)
	slots_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(slots_title)

	var slots_row := HBoxContainer.new()
	slots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	slots_row.add_theme_constant_override("separation", 10)
	vbox.add_child(slots_row)
	_slot_buttons.clear()
	for slot in range(1, GameManager.SAVE_SLOT_COUNT + 1):
		var slot_btn := Button.new()
		slot_btn.custom_minimum_size = Vector2(120, 70)
		slot_btn.add_theme_font_size_override("font_size", 24)
		slot_btn.pressed.connect(_on_slot_pressed.bind(slot))
		slots_row.add_child(slot_btn)
		_slot_buttons.append(slot_btn)

	# --- FR-406/407/411: Backup anlegen/wiederherstellen ------------
	var backup_row := HBoxContainer.new()
	backup_row.alignment = BoxContainer.ALIGNMENT_CENTER
	backup_row.add_theme_constant_override("separation", 10)
	vbox.add_child(backup_row)
	var backup_btn := Button.new()
	backup_btn.text = "Backup anlegen"
	backup_btn.custom_minimum_size = Vector2(190, 64)
	backup_btn.add_theme_font_size_override("font_size", 22)
	backup_btn.pressed.connect(_on_backup_pressed)
	backup_row.add_child(backup_btn)
	var restore_btn := Button.new()
	restore_btn.text = "Letztes Backup laden"
	restore_btn.custom_minimum_size = Vector2(190, 64)
	restore_btn.add_theme_font_size_override("font_size", 22)
	restore_btn.pressed.connect(_on_restore_pressed)
	backup_row.add_child(restore_btn)

	# --- FR-228: Fortschritt zurücksetzen ---------------------------
	var reset_btn := Button.new()
	reset_btn.text = "Fortschritt zurücksetzen"
	reset_btn.custom_minimum_size = Vector2(400, 76)
	reset_btn.add_theme_font_size_override("font_size", 28)
	reset_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	reset_btn.pressed.connect(_on_reset_pressed)
	vbox.add_child(reset_btn)

	# --- FR-420: DSGVO-konformes vollständiges Löschen ---------------
	var delete_all_btn := Button.new()
	delete_all_btn.text = "Alle Daten löschen (DSGVO)"
	delete_all_btn.custom_minimum_size = Vector2(400, 76)
	delete_all_btn.add_theme_font_size_override("font_size", 26)
	delete_all_btn.add_theme_color_override("font_color", Color(1.0, 0.2, 0.15))
	delete_all_btn.pressed.connect(_on_delete_all_pressed)
	vbox.add_child(delete_all_btn)

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
	_quality_btn.text = "Shader-Qualität: %s" % GameManager.shader_quality.capitalize()
	_render_scale_btn.text = "Auflösung: %d%%" % int(GameManager.render_scale * 100)
	_pixel_perfect_btn.text = "Pixel-Perfect: EIN" if GameManager.pixel_perfect_mode else "Pixel-Perfect: AUS"
	_crt_btn.text = "CRT-Filter: EIN" if GameManager.crt_filter_enabled else "CRT-Filter: AUS"
	_hard_mode_btn.text = "Hard-Mode: EIN" if GameManager.hard_mode_enabled else "Hard-Mode: AUS"
	# FR-421-440: Barrierefreiheit-Buttons
	var cb_names := {
		GameManager.ColorblindMode.NONE: "Aus", GameManager.ColorblindMode.PROTANOPIA: "Protanopie",
		GameManager.ColorblindMode.DEUTERANOPIA: "Deuteranopie", GameManager.ColorblindMode.TRITANOPIA: "Tritanopie",
	}
	_colorblind_btn.text = "Farbenblind-Modus: %s" % cb_names.get(GameManager.colorblind_mode, "Aus")
	# FR-433: Kurzbeschreibung als Tooltip-Vorschau, welche Farbpaare der
	# jeweilige Modus stärker unterscheidbar macht.
	_colorblind_btn.tooltip_text = {
		GameManager.ColorblindMode.NONE: "Kein Filter aktiv.",
		GameManager.ColorblindMode.PROTANOPIA: "Verstärkt Rot-Grün-Unterschiede im Blaukanal.",
		GameManager.ColorblindMode.DEUTERANOPIA: "Verstärkt Grün-Rot-Unterschiede im Blaukanal.",
		GameManager.ColorblindMode.TRITANOPIA: "Verstärkt Blau-Gelb-Unterschiede im Rotkanal.",
	}.get(GameManager.colorblind_mode, "")
	_contrast_btn.text = "Hoher Kontrast: EIN" if GameManager.high_contrast_enabled else "Hoher Kontrast: AUS"
	_motion_btn.text = "Reduzierte Bewegung: EIN" if GameManager.reduced_motion_enabled else "Reduzierte Bewegung: AUS"
	_ui_scale_btn.text = "Menü-/Textgröße: %.0f%%" % (GameManager.menu_ui_scale * 100)
	_captions_btn.text = "Sound-Untertitel: EIN" if GameManager.sound_captions_enabled else "Sound-Untertitel: AUS"
	_one_handed_btn.text = "Einhand-Modus: EIN" if GameManager.one_handed_mode else "Einhand-Modus: AUS"
	_assist_aim_btn.text = "Ziel-Assistenz: EIN" if GameManager.assist_aim_enabled else "Ziel-Assistenz: AUS"
	_brightness_btn.text = "Helligkeit: %d%%" % int(GameManager.screen_brightness * 100)
	_fps_counter_btn.text = "FPS-Anzeige: EIN" if GameManager.fps_counter_enabled else "FPS-Anzeige: AUS"
	_fps_limit_btn.text = "Bildrate: %s" % ("Unbegrenzt" if GameManager.fps_limit == 0 else "%d FPS" % GameManager.fps_limit)
	_tap_confirm_btn.text = "Tipp-Bestätigung: EIN" if GameManager.tap_confirmations_enabled else "Tipp-Bestätigung: AUS"
	_focus_pause_btn.text = "Pause bei Fokusverlust: EIN" if GameManager.pause_on_focus_loss else "Pause bei Fokusverlust: AUS"
	_difficulty_assist_btn.text = "Schwierigkeits-Assist: EIN" if GameManager.difficulty_assist_enabled else "Schwierigkeits-Assist: AUS"
	_volume_btn.text = "Lautstärke: %d%%" % int(GameManager.master_volume * 100)
	_language_btn.text = "Sprache: %s" % GameManager.language.to_upper()
	# FR-403/418: Speicherplatz-Buttons
	for i in range(_slot_buttons.size()):
		var slot := i + 1
		var btn := _slot_buttons[i]
		if slot == GameManager.current_save_slot:
			btn.text = "● %d" % slot
			btn.disabled = true
		else:
			btn.text = "%d" % slot if GameManager.save_slot_exists(slot) else "%d (leer)" % slot
			btn.disabled = false


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


## FR-300: Shader-Qualität durchschalten (low -> medium -> high).
func _on_quality_pressed() -> void:
	var order := ["low", "medium", "high"]
	var next_idx := (order.find(GameManager.shader_quality) + 1) % order.size()
	GameManager.set_shader_quality(order[next_idx])
	GameManager.vibrate(15)
	_update_buttons()


## FR-291: Render-Auflösung in 10%-Schritten durchschalten (50..100%).
func _on_render_scale_pressed() -> void:
	var next := GameManager.render_scale - 0.1
	if next < 0.5:
		next = 1.0
	GameManager.set_render_scale(next)
	GameManager.vibrate(15)
	_update_buttons()


## FR-299: Pixel-Perfect-Modus umschalten.
func _on_pixel_perfect_pressed() -> void:
	GameManager.set_pixel_perfect_mode(not GameManager.pixel_perfect_mode)
	GameManager.vibrate(15)
	_update_buttons()


## FR-282: CRT-Filter umschalten (wirkt im laufenden Level sofort).
func _on_crt_pressed() -> void:
	GameManager.set_crt_filter_enabled(not GameManager.crt_filter_enabled)
	# Variant statt statischem Typ, da nur per Duck-Typing angesprochen
	var main = get_tree().get_first_node_in_group("main_controller")
	if main != null and main.has_method("set_crt_filter_active"):
		main.set_crt_filter_active(GameManager.crt_filter_enabled)
	GameManager.vibrate(15)
	_update_buttons()


## FR-316: Hard-Mode umschalten (härtere Bedingungen, separate Stern-Wertung).
func _on_hard_mode_pressed() -> void:
	GameManager.set_hard_mode_enabled(not GameManager.hard_mode_enabled)
	GameManager.vibrate(15)
	_update_buttons()


## FR-421-440: Kleine Hilfsfunktion für einheitlich gestaltete Buttons.
func _make_settings_button(vbox: VBoxContainer, callback: Callable) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(400, 76)
	btn.add_theme_font_size_override("font_size", 26)
	btn.pressed.connect(callback)
	vbox.add_child(btn)
	return btn


## FR-421: Farbenblind-Modus durchschalten.
func _on_colorblind_pressed() -> void:
	var order := [
		GameManager.ColorblindMode.NONE, GameManager.ColorblindMode.PROTANOPIA,
		GameManager.ColorblindMode.DEUTERANOPIA, GameManager.ColorblindMode.TRITANOPIA,
	]
	var next_idx := (order.find(GameManager.colorblind_mode) + 1) % order.size()
	GameManager.set_colorblind_mode(order[next_idx])
	GameManager.vibrate(15)
	_update_buttons()


## FR-422: Hoher-Kontrast-Modus umschalten.
func _on_contrast_pressed() -> void:
	GameManager.set_high_contrast_enabled(not GameManager.high_contrast_enabled)
	GameManager.vibrate(15)
	_update_buttons()


## FR-423: Reduzierte-Bewegung umschalten.
func _on_motion_pressed() -> void:
	GameManager.set_reduced_motion_enabled(not GameManager.reduced_motion_enabled)
	GameManager.vibrate(15)
	_update_buttons()


## FR-424: Menü-/Text-Skalierung in Stufen durchschalten.
func _on_ui_scale_pressed() -> void:
	var next := GameManager.menu_ui_scale + 0.15
	if next > 1.3:
		next = 0.85
	GameManager.set_menu_ui_scale(next)
	GameManager.vibrate(15)
	_update_buttons()


## FR-425: Untertitel für Soundeffekte umschalten.
func _on_captions_pressed() -> void:
	GameManager.set_sound_captions_enabled(not GameManager.sound_captions_enabled)
	GameManager.play_ui_click()
	GameManager.vibrate(15)
	_update_buttons()


## FR-426: Einhand-Modus umschalten.
func _on_one_handed_pressed() -> void:
	GameManager.set_one_handed_mode(not GameManager.one_handed_mode)
	GameManager.vibrate(15)
	_update_buttons()


## FR-427: Ziel-Assistenz umschalten.
func _on_assist_aim_pressed() -> void:
	GameManager.set_assist_aim_enabled(not GameManager.assist_aim_enabled)
	GameManager.vibrate(15)
	_update_buttons()


## FR-429: Bildschirm-Helligkeit in Stufen durchschalten.
func _on_brightness_pressed() -> void:
	var next := GameManager.screen_brightness - 0.1
	if next < 0.5:
		next = 1.0
	GameManager.set_screen_brightness(next)
	GameManager.vibrate(15)
	_update_buttons()


## FR-431: FPS-Anzeige umschalten.
func _on_fps_counter_pressed() -> void:
	GameManager.set_fps_counter_enabled(not GameManager.fps_counter_enabled)
	GameManager.play_ui_click()
	GameManager.vibrate(15)
	_update_buttons()


## FR-432: Bildratenbegrenzung durchschalten (unbegrenzt/30/60).
func _on_fps_limit_pressed() -> void:
	var order := [0, 30, 60]
	var next_idx := (order.find(GameManager.fps_limit) + 1) % order.size()
	GameManager.set_fps_limit(order[next_idx])
	GameManager.play_ui_click()
	GameManager.vibrate(15)
	_update_buttons()


## FR-435: Tipp-Bestätigungen umschalten.
func _on_tap_confirm_pressed() -> void:
	GameManager.set_tap_confirmations_enabled(not GameManager.tap_confirmations_enabled)
	GameManager.play_ui_click()
	GameManager.vibrate(15)
	_update_buttons()


## FR-436: Pause bei Fokusverlust umschalten.
func _on_focus_pause_pressed() -> void:
	GameManager.set_pause_on_focus_loss(not GameManager.pause_on_focus_loss)
	GameManager.play_ui_click()
	GameManager.vibrate(15)
	_update_buttons()


## FR-437: Schwierigkeits-Assist-Paket umschalten.
func _on_difficulty_assist_pressed() -> void:
	GameManager.set_difficulty_assist_enabled(not GameManager.difficulty_assist_enabled)
	GameManager.play_ui_click()
	GameManager.vibrate(15)
	_update_buttons()


## FR-438: Lautstärke in Stufen durchschalten.
func _on_volume_pressed() -> void:
	var next := GameManager.master_volume - 0.25
	if next < 0.0:
		next = 1.0
	GameManager.set_master_volume(next)
	GameManager.vibrate(15)
	_update_buttons()


## FR-439: Sprache durchschalten (Übersetzungs-Anwendung folgt in Batch 17).
func _on_language_pressed() -> void:
	var next_idx := (GameManager.LANGUAGES.find(GameManager.language) + 1) % GameManager.LANGUAGES.size()
	GameManager.set_language(GameManager.LANGUAGES[next_idx])
	GameManager.play_ui_click()
	GameManager.vibrate(15)
	_update_buttons()


## FR-440: Setzt nur die Einstellungen (nicht den Fortschritt) zurück.
func _on_reset_settings_pressed() -> void:
	GameManager.reset_settings_to_default()
	GameManager.vibrate(60)
	_update_buttons()


## FR-228: Zeigt den Bestätigungsdialog vor dem Zurücksetzen des Fortschritts.
func _on_reset_pressed() -> void:
	GameManager.play_ui_click()
	_confirm_dialog.confirmed.connect(_on_reset_confirmed, CONNECT_ONE_SHOT)
	_confirm_dialog.show_dialog(
		"Fortschritt zurücksetzen?",
		"Alle Sterne, Sammlungen, Statistiken und Einstellungen werden\nunwiderruflich gelöscht. Dies kann nicht rückgängig gemacht werden."
	)


func _on_reset_confirmed() -> void:
	GameManager.reset_all_progress()
	GameManager.vibrate(80)
	_update_buttons()
	get_tree().reload_current_scene()


## FR-403: Wechselt das aktive Speicherprofil und lädt die Szene neu,
## damit alle UI-Elemente den neuen Spielstand konsistent anzeigen.
func _on_slot_pressed(slot: int) -> void:
	GameManager.play_ui_click()
	GameManager.switch_save_slot(slot)
	GameManager.vibrate(30)
	get_tree().reload_current_scene()


## FR-406: Legt sofort ein Backup des aktuellen Spielstands an.
func _on_backup_pressed() -> void:
	GameManager.export_save()
	GameManager.play_ui_click()
	GameManager.vibrate(30)


## FR-407/411: Stellt das neueste Backup des aktuellen Profils wieder her.
func _on_restore_pressed() -> void:
	var backups := GameManager.list_backups()
	if backups.is_empty():
		GameManager.play_ui_click()
		return
	GameManager.play_ui_click()
	_confirm_dialog.confirmed.connect(func():
		GameManager.restore_backup(backups[0])
		GameManager.vibrate(60)
		get_tree().reload_current_scene()
	, CONNECT_ONE_SHOT)
	_confirm_dialog.show_dialog(
		"Backup wiederherstellen?",
		"Der aktuelle Spielstand wird durch das letzte Backup ersetzt."
	)


## FR-420: Zeigt den DSGVO-Lösch-Bestätigungsdialog vor dem
## vollständigen, unwiderruflichen Löschen aller lokalen Daten.
func _on_delete_all_pressed() -> void:
	GameManager.play_ui_click()
	_confirm_dialog.confirmed.connect(_on_delete_all_confirmed, CONNECT_ONE_SHOT)
	_confirm_dialog.show_dialog(
		"Wirklich ALLE Daten löschen?",
		"Alle Speicherplätze, Einstellungen und Erfolge werden unwiderruflich\ngelöscht — auch alle Backups. Dies kann nicht rückgängig gemacht werden."
	)


func _on_delete_all_confirmed() -> void:
	GameManager.delete_all_user_data()
	GameManager.vibrate(100)
	get_tree().reload_current_scene()


func _on_close_pressed() -> void:
	visible = false
	closed.emit()
