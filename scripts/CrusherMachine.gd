extends Node2D
class_name CrusherMachine
## CrusherMachine – Komplexe Hindernis-Maschine (FR-075)
## =========================================================
## Ein Verbund-Hindernis: kombiniert eine stampfende Stachel-Platte
## (vertikale Quetsch-Bewegung) mit rotierenden Sägeblättern an den
## Seiten — mehrere Einzelteile, die als eine Maschine zusammenspielen.

@export var crush_travel: float = 160.0
@export var crush_speed_down: float = 700.0
@export var crush_speed_up: float = 200.0
@export var pause_at_bottom: float = 0.3
@export var pause_at_top: float = 0.6
@export var plate_size: Vector2 = Vector2(120, 30)
@export var side_saw_radius: float = 28.0

enum State { UP, MOVING_DOWN, DOWN, MOVING_UP }
var _state: State = State.UP
var _timer: float = 0.0
var _plate: Area2D
var _plate_cshape: CollisionShape2D
var _start_y: float = 0.0
var _left_saw: Node2D
var _right_saw: Node2D


func _ready() -> void:
	add_to_group("obstacles")  # für die seitlichen Sägen (_on_saw_body_entered)
	_start_y = 0.0
	_timer = pause_at_top
	_build_visual()


func _process(delta: float) -> void:
	if _left_saw != null:
		_left_saw.rotation += 4.0 * delta
	if _right_saw != null:
		_right_saw.rotation -= 4.0 * delta

	match _state:
		State.UP:
			_timer -= delta
			if _timer <= 0.0:
				_state = State.MOVING_DOWN
				GameManager.vibrate(15)
		State.MOVING_DOWN:
			_plate.position.y += crush_speed_down * delta
			if _plate.position.y >= crush_travel:
				_plate.position.y = crush_travel
				_state = State.DOWN
				_timer = pause_at_bottom
				GameManager.vibrate(50)
		State.DOWN:
			_timer -= delta
			if _timer <= 0.0:
				_state = State.MOVING_UP
		State.MOVING_UP:
			_plate.position.y -= crush_speed_up * delta
			if _plate.position.y <= 0.0:
				_plate.position.y = 0.0
				_state = State.UP
				_timer = pause_at_top


func _on_plate_body_entered(body: Node) -> void:
	if body is Player:
		body._on_body_entered(_plate)


func _on_saw_body_entered(body: Node) -> void:
	if body is Player:
		body._on_body_entered(self)


func _build_visual() -> void:
	# Obere Halterung
	var mount := ColorRect.new()
	mount.size = Vector2(20, 40)
	mount.position = Vector2(-10, -40)
	mount.color = Color(0.4, 0.4, 0.45)
	add_child(mount)

	# Stampf-Platte (Area2D, bewegt sich nach unten)
	_plate = Area2D.new()
	_plate.add_to_group("obstacles")
	_plate.body_entered.connect(_on_plate_body_entered)
	var plate_poly := Polygon2D.new()
	plate_poly.color = Color(0.6, 0.3, 0.3)
	plate_poly.polygon = PackedVector2Array([
		Vector2(-plate_size.x * 0.5, -plate_size.y * 0.5),
		Vector2(plate_size.x * 0.5, -plate_size.y * 0.5),
		Vector2(plate_size.x * 0.5, plate_size.y * 0.5),
		Vector2(-plate_size.x * 0.5, plate_size.y * 0.5),
	])
	_plate.add_child(plate_poly)
	# Stacheln unter der Platte
	for i in range(5):
		var x := -plate_size.x * 0.4 + i * plate_size.x * 0.2
		var spike := Polygon2D.new()
		spike.color = Color(0.7, 0.7, 0.72)
		spike.polygon = PackedVector2Array([
			Vector2(x - 8, plate_size.y * 0.5),
			Vector2(x + 8, plate_size.y * 0.5),
			Vector2(x, plate_size.y * 0.5 + 16),
		])
		_plate.add_child(spike)
	_plate_cshape = CollisionShape2D.new()
	var plate_shape := RectangleShape2D.new()
	plate_shape.size = Vector2(plate_size.x, plate_size.y + 32)
	_plate_cshape.shape = plate_shape
	_plate_cshape.position = Vector2(0, plate_size.y * 0.3)
	_plate.add_child(_plate_cshape)
	add_child(_plate)

	# Seitliche rotierende Sägeblätter (dekorativ-gefährliche Begleiter)
	_left_saw = _build_side_saw(Vector2(-plate_size.x * 0.5 - side_saw_radius * 0.6, crush_travel * 0.5))
	_right_saw = _build_side_saw(Vector2(plate_size.x * 0.5 + side_saw_radius * 0.6, crush_travel * 0.5))


func _build_side_saw(offset: Vector2) -> Node2D:
	var saw := Node2D.new()
	saw.position = offset
	add_child(saw)

	var pts := PackedVector2Array()
	var teeth := 10
	for i in range(teeth * 2):
		var a := TAU * float(i) / float(teeth * 2)
		var r := side_saw_radius if i % 2 == 0 else side_saw_radius * 0.75
		pts.append(Vector2(cos(a), sin(a)) * r)
	var poly := Polygon2D.new()
	poly.color = Color(0.65, 0.65, 0.68)
	poly.polygon = pts
	saw.add_child(poly)

	var area := Area2D.new()
	area.add_to_group("obstacles")
	area.body_entered.connect(_on_saw_body_entered)
	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = side_saw_radius * 0.9
	cshape.shape = circle
	area.add_child(cshape)
	saw.add_child(area)

	return saw
