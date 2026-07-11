extends Area2D
class_name MovingLaserWall
## MovingLaserWall – Wandernde Laserwand / Quetsch-Gefahr (FR-071)
## ===================================================================
## Eine vertikale Laserwand, die sich horizontal bewegt und
## den Spieler gegen den Levelrand quetschen kann.

@export var wall_height: float = 400.0
@export var travel_distance: float = 500.0
@export var move_speed: float = 150.0
@export var color: Color = Color(1.0, 0.2, 0.3, 0.85)

var _start_pos: Vector2
var _direction: float = 1.0
var _cshape: CollisionShape2D


func _ready() -> void:
	add_to_group("obstacles")
	body_entered.connect(_on_body_entered)
	_start_pos = global_position
	_build_visual()


func _physics_process(delta: float) -> void:
	position.x += _direction * move_speed * delta
	var dist := global_position.x - _start_pos.x
	if dist > travel_distance:
		_direction = -1.0
	elif dist < 0.0:
		_direction = 1.0


func _on_body_entered(body: Node) -> void:
	if body is Player:
		body._on_body_entered(self)


func _build_visual() -> void:
	var beam := Line2D.new()
	beam.points = [Vector2(0, -wall_height * 0.5), Vector2(0, wall_height * 0.5)]
	beam.width = 12.0
	beam.default_color = color
	add_child(beam)

	# Glüh-Rand (breiter, transparenter)
	var glow := Line2D.new()
	glow.points = beam.points
	glow.width = 24.0
	glow.default_color = Color(color.r, color.g, color.b, 0.3)
	add_child(glow)

	_cshape = CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(14, wall_height)
	_cshape.shape = rect_shape
	add_child(_cshape)
