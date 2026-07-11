extends CanvasLayer
class_name BestiaryScreen
## BestiaryScreen – Gegner-Bestiarium/Sammlung (FR-118)
## =========================================================
## Zeigt alle bekannten Gegner-Typen an. Noch nicht entdeckte
## Gegner werden als Silhouette ("???") dargestellt.

var _panel: Control
var _list: VBoxContainer


func _ready() -> void:
	layer = 90
	visible = false
	_build_ui()


func show_bestiary() -> void:
	_refresh_list()
	visible = true


func hide_bestiary() -> void:
	visible = false


func _refresh_list() -> void:
	for child in _list.get_children():
		child.queue_free()

	for class_id in GameManager.ENEMY_BESTIARY.keys():
		var display_name: String = GameManager.ENEMY_BESTIARY[class_id]
		var discovered: bool = class_id in GameManager.discovered_enemies

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)

		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(36, 36)
		icon.color = Color(0.5, 0.2, 0.6) if discovered else Color(0.15, 0.15, 0.15)
		row.add_child(icon)

		var label := Label.new()
		label.text = display_name if discovered else "???"
		label.add_theme_font_size_override("font_size", 32)
		label.add_theme_color_override("font_color", Color.WHITE if discovered else Color(0.4, 0.4, 0.4))
		row.add_child(label)

		_list.add_child(row)

	var count_label := Label.new()
	var total := GameManager.ENEMY_BESTIARY.size()
	var found := GameManager.discovered_enemies.size()
	count_label.text = "%d / %d entdeckt" % [found, total]
	count_label.add_theme_font_size_override("font_size", 28)
	count_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_list.add_child(count_label)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "Gegner-Bestiarium"
	title.add_theme_font_size_override("font_size", 48)
	title.position = Vector2(60, 40)
	bg.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 120
	scroll.offset_left = 60
	scroll.offset_right = -60
	scroll.offset_bottom = -100
	bg.add_child(scroll)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 16)
	scroll.add_child(_list)

	var close_btn := Button.new()
	close_btn.text = "Schließen"
	close_btn.custom_minimum_size = Vector2(240, 70)
	close_btn.add_theme_font_size_override("font_size", 32)
	close_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	close_btn.offset_left = -260
	close_btn.offset_top = -90
	close_btn.offset_right = -20
	close_btn.offset_bottom = -20
	close_btn.pressed.connect(hide_bestiary)
	bg.add_child(close_btn)

	_panel = bg
