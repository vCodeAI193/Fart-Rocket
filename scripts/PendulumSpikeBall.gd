extends Node2D
class_name PendulumSpikeBall
## PendulumSpikeBall – Pendelnde Stachelkugel / Morgenstern (FR-063)
## ====================================================================
## Eine Stachelkugel, die an einer Kette hängt und wie ein
## Pendel schwingt. Trifft sie den Spieler, ist es tödlich.

@export var chain_length: float = 200.0
@export var swing_amplitude: float = 60.0  # Grad
@export var swing_speed: float = 1.2
@export var ball_radius: float = 22.0
@export var spike_count: int = 10
@export var color: Color = Color(0.4, 0.4, 0.45)

var _anchor_pos: Vector2
var _ball_node: Node2D
var _time: float = 0.0


func _ready() -> void:
	_anchor_pos = global_position
	_build_visual()


func _process(delta: float) -> void:
	_time += delta * swing_speed
	var angle_rad := deg_to_rad(swing_amplitude) * sin(_time)
	var ball_pos := _anchor_pos + Vector2(sin(angle_rad), cos(angle_rad)) * chain_length
	_ball_node.global_position = ball_pos
	_ball_node.rotation += delta * 1.5

	queue_redraw()


func _draw() -> void:
	if _ball_node == null:
		return
	# Kette zeichnen
	var local_ball_pos := to_local(_ball_node.global_position)
	draw_line(Vector2.ZERO, local_ball_pos, Color(0.3, 0.3, 0.3, 0.9), 3.0)
	# Kettenglieder
	var segments := int(chain_length / 20.0)
	for i in range(segments):
		var t := float(i) / segments
		var pos := local_ball_pos * t
		draw_circle(pos, 3.0, Color(0.4, 0.4, 0.4))


func _build_visual() -> void:
	_ball_node = Node2D.new()
	add_child(_ball_node)

	var core := Polygon2D.new()
	core.color = color
	var pts := PackedVector2Array()
	for i in range(16):
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a), sin(a)) * ball_radius * 0.6)
	core.polygon = pts
	_ball_node.add_child(core)

	for i in range(spike_count):
		var angle := TAU * float(i) / spike_count
		var spike := Polygon2D.new()
		spike.color = color.darkened(0.15)
		var base := Vector2(cos(angle), sin(angle)) * ball_radius * 0.55
		var tip := Vector2(cos(angle), sin(angle)) * ball_radius
		var perp := Vector2(-sin(angle), cos(angle)) * ball_radius * 0.15
		spike.polygon = PackedVector2Array([base - perp, tip, base + perp])
		_ball_node.add_child(spike)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = ball_radius
	cshape.shape = circle
	_ball_node.add_child(cshape)

	var area := Area2D.new()
	var area_shape := CollisionShape2D.new()
	area_shape.shape = circle.duplicate()
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	_ball_node.add_child(area)

	# StaticBody-Rolle für Player._on_body_entered's is_in_group check
	_ball_node.add_to_group("obstacles")


func _on_body_entered(body: Node) -> void:
	if body is Player:
		body._on_body_entered(_ball_node)
