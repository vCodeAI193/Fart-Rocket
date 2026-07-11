extends Control
## SplashScreen – Logo-Intro (FR-230)
## ========================================
## Kurzer Splash-Bildschirm mit dem Spiel-Logo, der beim Start
## angezeigt wird, bevor es zum Hauptmenü weitergeht.

@export var display_duration: float = 1.6

var _logo_label: Label
var _rocket_shape: Polygon2D


func _ready() -> void:
	_build_ui()
	_play_intro()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var rocket_node := Node2D.new()
	rocket_node.position = Vector2(960, 500)
	rocket_node.scale = Vector2.ZERO
	add_child(rocket_node)
	_rocket_shape = Polygon2D.new()
	_rocket_shape.color = Color(0.9, 0.9, 0.95)
	_rocket_shape.polygon = PackedVector2Array([
		Vector2(0, -60), Vector2(30, 30), Vector2(0, 10), Vector2(-30, 30),
	])
	rocket_node.add_child(_rocket_shape)
	var flame := Polygon2D.new()
	flame.color = Color(1.0, 0.6, 0.1)
	flame.polygon = PackedVector2Array([Vector2(-14, 30), Vector2(14, 30), Vector2(0, 70)])
	rocket_node.add_child(flame)

	_logo_label = Label.new()
	_logo_label.text = "FART ROCKET"
	_logo_label.add_theme_font_size_override("font_size", 72)
	_logo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_logo_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_logo_label.offset_top = 650.0
	_logo_label.offset_left = -400.0
	_logo_label.offset_right = 400.0
	_logo_label.modulate.a = 0.0
	add_child(_logo_label)

	var tween := create_tween()
	tween.tween_property(rocket_node, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(_logo_label, "modulate:a", 1.0, 0.6).set_delay(0.2)


func _play_intro() -> void:
	await get_tree().create_timer(display_duration).timeout
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
