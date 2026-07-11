extends Node2D
class_name SwarmEnemy
## SwarmEnemy – Schwarm-Gegner / Insekten (FR-108)
## ====================================================
## Erzeugt eine Gruppe kleiner fliegender Gegner, die sich in
## einem lockeren Schwarm-Muster um einen Mittelpunkt bewegen
## (einfaches Boid-artiges Verhalten: Kohäsion + individuelles Wackeln).

@export var insect_count: int = 6
@export var swarm_radius: float = 80.0
@export var insect_speed: float = 60.0
@export var insect_size: float = 7.0
@export var color: Color = Color(0.3, 0.2, 0.1)

var _insects: Array[Dictionary] = []  # {node, area, phase, radius_offset}


func _ready() -> void:
	add_to_group("obstacles")  # für den self-Verweis in _on_insect_body_entered
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	for i in range(insect_count):
		var insect := _build_insect()
		var phase := rng.randf_range(0, TAU)
		var radius_offset := rng.randf_range(0.6, 1.0)
		var speed_variance := rng.randf_range(0.8, 1.3)
		_insects.append({
			"node": insect,
			"phase": phase,
			"radius_offset": radius_offset,
			"speed_variance": speed_variance,
			"angle": phase,
		})
		add_child(insect)


func _process(delta: float) -> void:
	for data in _insects:
		data["angle"] += (insect_speed / swarm_radius) * data["speed_variance"] * delta
		var r := swarm_radius * data["radius_offset"]
		var wobble := sin(Time.get_ticks_msec() * 0.005 + data["phase"]) * 10.0
		var pos := Vector2(cos(data["angle"]), sin(data["angle"])) * (r + wobble)
		data["node"].position = pos


func _build_insect() -> Node2D:
	var insect := Node2D.new()

	var body := Polygon2D.new()
	body.color = color
	var pts := PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		pts.append(Vector2(cos(a), sin(a) * 0.7) * insect_size)
	body.polygon = pts
	insect.add_child(body)

	# Flügel (transparente Dreiecke)
	for side in [-1, 1]:
		var wing := Polygon2D.new()
		wing.color = Color(0.9, 0.9, 1.0, 0.4)
		wing.polygon = PackedVector2Array([
			Vector2.ZERO,
			Vector2(side * insect_size * 1.5, -insect_size * 0.8),
			Vector2(side * insect_size * 0.5, insect_size * 0.3),
		])
		insect.add_child(wing)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = insect_size
	cshape.shape = circle
	insect.add_child(cshape)

	var area := Area2D.new()
	var area_shape := CollisionShape2D.new()
	area_shape.shape = circle.duplicate()
	area.add_child(area_shape)
	area.body_entered.connect(_on_insect_body_entered)
	insect.add_child(area)

	return insect


func _on_insect_body_entered(body: Node) -> void:
	if body is Player:
		body._on_body_entered(self)
