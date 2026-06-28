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
	_panel.custom_minimum_size = Vector2(520, 420)
	_panel.offset_left = -260.0
	_panel.offset_top = -210.0
	_panel.offset_right = 260.0
	_panel.offset_bottom = 210.0
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(vbox)

	# Titel
	var title := Label.new()
	title.text = "Einstellungen"
	title.add_theme_font_size_override("font_size", 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Haptik-Toggle
	_haptics_btn = Button.new()
	_haptics_btn.custom_minimum_size = Vector2(400, 80)
	_haptics_btn.add_theme_font_size_override("font_size", 38)
	_haptics_btn.pressed.connect(_on_haptics_pressed)
	vbox.add_child(_haptics_btn)

	# Ton-Toggle
	_mute_btn = Button.new()
	_mute_btn.custom_minimum_size = Vector2(400, 80)
	_mute_btn.add_theme_font_size_override("font_size", 38)
	_mute_btn.pressed.connect(_on_mute_pressed)
	vbox.add_child(_mute_btn)

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


func _on_haptics_pressed() -> void:
	GameManager.set_haptics(not GameManager.haptics_enabled)
	_update_buttons()


func _on_mute_pressed() -> void:
	GameManager.toggle_muted()
	_update_buttons()


func _on_close_pressed() -> void:
	visible = false
	closed.emit()
