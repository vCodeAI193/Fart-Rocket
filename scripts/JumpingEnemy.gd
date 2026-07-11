extends CharacterBody2D
class_name JumpingEnemy
## JumpingEnemy – Springender Boden-Gegner (FR-107)
## ===================================================
## Ein Gegner, der rhythmisch in die Höhe springt und
## wieder landet — muss übersprungen oder umflogen werden.

@export var jump_height: float = 150.0
@export var jump_interval: float = 1.5
@export var size: float = 16.0
@export var color: Color = Color(0.6, 0.3, 0.7)
@export var gravity: float = 900.0

var _start_y: float = 0.0
var _velocity_y: float = 0.0
var _jump_timer: float = 0.0
var _on_ground: bool = true


func _ready() -> void:
	add_to_group("obstacles")
	_start_y = global_position.y
	_jump_timer = jump_interval * 0.3
	_build_visual()


func _physics_process(delta: float) -> void:
	_jump_timer -= delta
	if _jump_timer <= 0.0 and _on_ground:
		_velocity_y = -sqrt(2.0 * gravity * jump_height)
		_on_ground = false
		_jump_timer = jump_interval

	_velocity_y += gravity * delta
	position.y += _velocity_y * delta

	if position.y >= _start_y:
		position.y = _start_y
		_velocity_y = 0.0
		_on_ground = true

	# Squash-and-stretch beim Springen/Landen
	var stretch := clampf(abs(_velocity_y) / 400.0, 0.0, 0.4)
	scale = Vector2(1.0 - stretch * 0.3, 1.0 + stretch * 0.3)


func _build_visual() -> void:
	var body := Polygon2D.new()
	body.color = color
	var pts := PackedVector2Array()
	for i in range(10):
		var a := TAU * float(i) / 10.0
		pts.append(Vector2(cos(a), sin(a) * 0.8) * size)
	body.polygon = pts
	add_child(body)

	# Augen
	for side in [-1, 1]:
		var eye := Polygon2D.new()
		eye.color = Color(1.0, 1.0, 1.0)
		var epts := PackedVector2Array()
		for i in range(8):
			var a := TAU * float(i) / 8.0
			epts.append(Vector2(cos(a), sin(a)) * 2.5)
		eye.polygon = epts
		eye.position = Vector2(side * size * 0.35, -size * 0.15)
		add_child(eye)

	# Beine (2 kleine Striche unten)
	for side in [-1, 1]:
		var leg := Line2D.new()
		leg.points = [Vector2(side * size * 0.4, size * 0.6), Vector2(side * size * 0.5, size * 0.9)]
		leg.width = 3.0
		leg.default_color = color.darkened(0.3)
		add_child(leg)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size
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
