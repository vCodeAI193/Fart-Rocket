extends Area2D
class_name ReverseGravityZone
## ReverseGravityZone – Umgekehrte Schwerkraft
## =============================================
## FR-022: Alle Spieler, die diese Zone betreten, bekommen invertierte Schwerkraft.

@export var gravity_factor: float = -1.0  # negativ = Schwerkraft nach oben

var _bodies_inside: Array[Node] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visual()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		_bodies_inside.append(body)
		body.gravity_scale = gravity_factor * body.level_gravity_scale


func _on_body_exited(body: Node) -> void:
	if body is Player:
		_bodies_inside.erase(body)
		body.gravity_scale = body.level_gravity_scale


func _build_visual() -> void:
	var rect := Polygon2D.new()
	rect.color = Color(0.4, 0.1, 0.8, 0.18)
	var cshape := $CollisionShape2D if has_node("CollisionShape2D") else null
	var w := 300.0
	var h := 200.0
	rect.polygon = PackedVector2Array([
		Vector2(-w * 0.5, -h * 0.5),
		Vector2(w * 0.5, -h * 0.5),
		Vector2(w * 0.5, h * 0.5),
		Vector2(-w * 0.5, h * 0.5),
	])
	add_child(rect)
	# Pfeil nach oben als Symbol
	var arrow := Line2D.new()
	arrow.width = 4.0
	arrow.default_color = Color(0.7, 0.3, 1.0, 0.8)
	arrow.add_point(Vector2(0, 60))
	arrow.add_point(Vector2(0, -60))
	arrow.add_point(Vector2(-20, -30))
	arrow.add_point(Vector2(0, -60))
	arrow.add_point(Vector2(20, -30))
	add_child(arrow)
