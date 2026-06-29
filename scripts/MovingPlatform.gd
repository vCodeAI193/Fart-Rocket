extends AnimatableBody2D
class_name MovingPlatform
## MovingPlatform – Bewegliche Plattform
## ======================================
## FR-024: Hin- und herpendelnde Plattform als sichere Landezone.

@export var move_offset: Vector2 = Vector2(300, 0)  # Bewegungsrichtung & Distanz
@export var move_duration: float = 2.0              # Sekunden pro Richtung
@export var platform_size: Vector2 = Vector2(160, 24)
@export var platform_color: Color = Color(0.3, 0.75, 0.35)


func _ready() -> void:
	add_to_group("moving_platforms")
	_build_visual()
	_start_motion()


func _build_visual() -> void:
	var poly := Polygon2D.new()
	poly.color = platform_color
	var hw := platform_size.x * 0.5
	var hh := platform_size.y * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh),
	])
	add_child(poly)
	# Kollisionsform
	var cshape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = platform_size
	cshape.shape = rect
	add_child(cshape)
	# Oberkante-Markierung
	var line := Line2D.new()
	line.width = 4.0
	line.default_color = platform_color.lightened(0.3)
	line.add_point(Vector2(-platform_size.x * 0.5 + 4, -platform_size.y * 0.5))
	line.add_point(Vector2(platform_size.x * 0.5 - 4, -platform_size.y * 0.5))
	add_child(line)


func _start_motion() -> void:
	var start_pos := position
	var end_pos := position + move_offset
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(self, "position", end_pos, move_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", start_pos, move_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
