extends StaticBody2D
class_name ConveyorBelt
## ConveyorBelt – Förderband
## =========================
## FR-025: Schiebt das Männchen in eine Richtung, wenn es darauf landet.

@export var belt_speed: float = 300.0             # px/s Schubgeschwindigkeit
@export var belt_direction: Vector2 = Vector2.RIGHT
@export var belt_size: Vector2 = Vector2(200, 20)
@export var belt_color: Color = Color(0.5, 0.4, 0.3)

var _bodies_on_belt: Array[RigidBody2D] = []


func _ready() -> void:
	_build_visual()
	var area := Area2D.new()
	var cshape2 := CollisionShape2D.new()
	var rect2 := RectangleShape2D.new()
	rect2.size = belt_size + Vector2(0, 10)
	cshape2.shape = rect2
	area.add_child(cshape2)
	area.collision_layer = 0
	area.collision_mask = 1
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _physics_process(_delta: float) -> void:
	var push := belt_direction.normalized() * belt_speed
	for body in _bodies_on_belt:
		if is_instance_valid(body):
			body.apply_central_force(push * body.mass)


func _on_body_entered(body: Node) -> void:
	if body is RigidBody2D:
		_bodies_on_belt.append(body as RigidBody2D)


func _on_body_exited(body: Node) -> void:
	if body is RigidBody2D:
		_bodies_on_belt.erase(body as RigidBody2D)


func _build_visual() -> void:
	# Kollision
	var cshape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = belt_size
	cshape.shape = rect
	add_child(cshape)
	# Band-Fläche
	var poly := Polygon2D.new()
	poly.color = belt_color
	var hw := belt_size.x * 0.5
	var hh := belt_size.y * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh),
	])
	add_child(poly)
	# Pfeil-Streifen auf dem Band
	var dir := belt_direction.normalized()
	for i in range(4):
		var line := Line2D.new()
		line.width = 3.0
		line.default_color = Color(0.7, 0.6, 0.4)
		var x := -hw + (float(i) + 0.5) * (belt_size.x / 4.0)
		line.add_point(Vector2(x - dir.x * 12, 0))
		line.add_point(Vector2(x + dir.x * 12, 0))
		add_child(line)
