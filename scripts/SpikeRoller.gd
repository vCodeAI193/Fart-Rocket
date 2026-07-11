extends StaticBody2D
class_name SpikeRoller
## SpikeRoller – Bewegliche Stachel-Walze (FR-062)
## ==================================================
## Eine rotierende Walze mit Stacheln, die zwischen zwei
## Punkten hin- und herfährt (horizontal oder vertikal).

@export var travel_distance: float = 250.0
@export var move_speed: float = 100.0
@export var vertical: bool = false
@export var radius: float = 28.0
@export var spike_count: int = 8
@export var color: Color = Color(0.5, 0.5, 0.55)

var _start_pos: Vector2
var _direction: float = 1.0
var _roller_node: Node2D


func _ready() -> void:
	add_to_group("obstacles")
	_start_pos = global_position
	_build_visual()


func _physics_process(delta: float) -> void:
	var axis := Vector2.RIGHT if not vertical else Vector2.DOWN
	position += axis * _direction * move_speed * delta

	var offset := global_position - _start_pos
	var dist := offset.dot(axis)
	if dist > travel_distance:
		_direction = -1.0
	elif dist < 0.0:
		_direction = 1.0

	# Walze rotiert passend zur Bewegungsrichtung (Rollen-Effekt)
	_roller_node.rotation += (move_speed / radius) * delta * _direction


func _build_visual() -> void:
	_roller_node = Node2D.new()
	add_child(_roller_node)

	# Zentral-Zylinder
	var core := Polygon2D.new()
	core.color = color
	var pts := PackedVector2Array()
	for i in range(16):
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a), sin(a)) * radius * 0.6)
	core.polygon = pts
	_roller_node.add_child(core)

	# Stacheln rundherum
	for i in range(spike_count):
		var angle := TAU * float(i) / spike_count
		var spike := Polygon2D.new()
		spike.color = color.darkened(0.1)
		var base := Vector2(cos(angle), sin(angle)) * radius * 0.55
		var tip := Vector2(cos(angle), sin(angle)) * radius
		var perp := Vector2(-sin(angle), cos(angle)) * radius * 0.15
		var spts := PackedVector2Array([base - perp, tip, base + perp])
		spike.polygon = spts
		_roller_node.add_child(spike)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	cshape.shape = circle
	add_child(cshape)

	var area := Area2D.new()
	var area_shape := CollisionShape2D.new()
	area_shape.shape = circle.duplicate()
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		body._on_body_entered(self)
