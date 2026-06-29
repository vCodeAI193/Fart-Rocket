extends CanvasLayer
class_name OnboardingScreen
## OnboardingScreen – Einführungs-Tutorial
## =========================================
## FR-240: Zeigt beim ersten Start eine kurze Anleitung mit 3 Slides.

signal finished

const SAVE_KEY := "onboarding_done"

var _slide_index: int = 0
var _panel: PanelContainer
var _title_label: Label
var _desc_label: Label
var _next_btn: Button
var _dot_indicators: Array[ColorRect] = []

const SLIDES := [
	{
		"title": "Willkommen bei Fart Rocket!",
		"desc": "Steuere dein Strichmännchen durch Hindernisse – mit Furzkraft!"
	},
	{
		"title": "So steuerst du",
		"desc": "Halte den Finger gedrückt und ziehe in die gewünschte Richtung.\nLasse los – und der Furz schiesst dich vorwärts!"
	},
	{
		"title": "Münzen sammeln",
		"desc": "Sammle Münzen für Punkte. Schnelle Folgezüge geben Combo-Bonus!\nViel Spass – und guten Wind!"
	},
]


func _ready() -> void:
	layer = 20
	visible = false


## Zeigt das Onboarding, falls noch nicht gesehen.
func show_if_needed() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://fartrocket_save.cfg") == OK:
		if bool(cfg.get_value("meta", SAVE_KEY, false)):
			finished.emit()
			return
	_build_ui()
	visible = true
	_show_slide(0)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.18, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(700, 500)
	_panel.offset_left = -350.0
	_panel.offset_top = -250.0
	_panel.offset_right = 350.0
	_panel.offset_bottom = 250.0
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 28)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(vbox)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 46)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_title_label)

	_desc_label = Label.new()
	_desc_label.add_theme_font_size_override("font_size", 34)
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_desc_label)

	# Punkt-Indikatoren
	var dots_box := HBoxContainer.new()
	dots_box.alignment = BoxContainer.ALIGNMENT_CENTER
	dots_box.add_theme_constant_override("separation", 14)
	vbox.add_child(dots_box)
	for i in range(SLIDES.size()):
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(14, 14)
		dot.color = Color(0.5, 0.5, 0.6)
		dots_box.add_child(dot)
		_dot_indicators.append(dot)

	_next_btn = Button.new()
	_next_btn.custom_minimum_size = Vector2(300, 80)
	_next_btn.add_theme_font_size_override("font_size", 38)
	_next_btn.pressed.connect(_on_next_pressed)
	vbox.add_child(_next_btn)


func _show_slide(index: int) -> void:
	_slide_index = index
	var slide: Dictionary = SLIDES[index]
	_title_label.text = slide["title"]
	_desc_label.text = slide["desc"]
	_next_btn.text = "Weiter >" if index < SLIDES.size() - 1 else "Los geht's!"
	for i in range(_dot_indicators.size()):
		_dot_indicators[i].color = Color(1.0, 0.85, 0.2) if i == index else Color(0.4, 0.4, 0.5)


func _on_next_pressed() -> void:
	if _slide_index < SLIDES.size() - 1:
		_show_slide(_slide_index + 1)
	else:
		_mark_done()
		visible = false
		finished.emit()


func _mark_done() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://fartrocket_save.cfg")
	cfg.set_value("meta", SAVE_KEY, true)
	cfg.save("user://fartrocket_save.cfg")
