extends CharacterBody2D
class_name PatrolEnemy
## PatrolEnemy – Patrouillierender Flug-Gegner (FR-101)
## ======================================================
## Ein Gegner, der zwischen zwei Punkten hin- und herfliegt.
## Bei Kontakt mit dem Spieler stirbt dieser (außer Schild aktiv).

@export var patrol_distance: float = 300.0
@export var patrol_speed: float = 120.0
@export var vertical: bool = false  # false = horizontal, true = vertikal
@export var size: float = 18.0
@export var color: Color = Color(0.8, 0.2, 0.5)

var _start_pos: Vector2
var _direction: float = 1.0


func _ready() -> void:
	add_to_group("obstacles")
	_start_pos = global_position
	_build_visual()


func _physics_process(delta: float) -> void:
	var axis := Vector2.RIGHT if not vertical else Vector2.DOWN
	position += axis * _direction * patrol_speed * delta

	var offset := (global_position - _start_pos)
	var dist := offset.dot(axis)
	if dist > patrol_distance:
		_direction = -1.0
	elif dist < 0.0:
		_direction = 1.0

	# Leichtes Auf-und-Ab-Wackeln für organische Bewegung
	rotation = sin(Time.get_ticks_msec() * 0.004) * 0.15


func _build_visual() -> void:
	# Körper (Rhombus-Form für Flug-Gegner)
	var body := Polygon2D.new()
	body.color = color
	var pts := PackedVector2Array([
		Vector2(0, -size),
		Vector2(size * 0.7, 0),
		Vector2(0, size),
		Vector2(-size * 0.7, 0),
	])
	body.polygon = pts
	add_child(body)

	# Augen (2 kleine Punkte)
	for side in [-1, 1]:
		var eye := Polygon2D.new()
		eye.color = Color(1.0, 1.0, 1.0)
		var epts := PackedVector2Array()
		for i in range(8):
			var a := TAU * float(i) / 8.0
			epts.append(Vector2(cos(a), sin(a)) * 3.0)
		eye.polygon = epts
		eye.position = Vector2(side * size * 0.3, -size * 0.2)
		add_child(eye)

	# Flügel-Andeutung (2 Linien)
	for side in [-1, 1]:
		var wing := Line2D.new()
		wing.points = [Vector2.ZERO, Vector2(side * size * 1.3, size * 0.3)]
		wing.width = 3.0
		wing.default_color = Color(color.r, color.g, color.b, 0.6)
		add_child(wing)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size
	cshape.shape = circle
	add_child(cshape)

	# Area2D für Kollisionserkennung mit Spieler
	var area := Area2D.new()
	var area_shape := CollisionShape2D.new()
	area_shape.shape = circle.duplicate()
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		body._on_body_entered(self)
