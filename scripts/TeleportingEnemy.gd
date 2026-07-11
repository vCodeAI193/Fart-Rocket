extends CharacterBody2D
class_name TeleportingEnemy
## TeleportingEnemy – Teleportierender Gegner (FR-110)
## ========================================================
## Ein Gegner, der sich in regelmäßigen Abständen unsichtbar
## macht und an einer neuen zufälligen Position in der Nähe
## wieder erscheint — unvorhersehbar und schwer zu timen.

@export var teleport_interval: float = 2.0
@export var teleport_range: float = 200.0
@export var warning_time: float = 0.4
@export var size: float = 17.0
@export var color: Color = Color(0.55, 0.15, 0.7)

var _timer: float = 0.0
var _visual_node: Node2D
var _cshape: CollisionShape2D


func _ready() -> void:
	add_to_group("obstacles")
	_timer = teleport_interval
	_build_visual()


func _process(delta: float) -> void:
	_timer -= delta

	if _timer <= warning_time and _timer > 0.0:
		_visual_node.modulate.a = 0.3 + sin(Time.get_ticks_msec() * 0.05) * 0.3

	if _timer <= 0.0:
		_teleport()
		_timer = teleport_interval


func _teleport() -> void:
	GameManager.vibrate(20)
	var tween_out := create_tween()
	tween_out.tween_property(_visual_node, "scale", Vector2.ZERO, 0.1)
	await tween_out.finished

	var offset := Vector2(
		randf_range(-teleport_range, teleport_range),
		randf_range(-teleport_range, teleport_range)
	)
	position += offset

	var tween_in := create_tween()
	tween_in.tween_property(_visual_node, "scale", Vector2.ONE, 0.15)
	_visual_node.modulate.a = 1.0


func _on_body_entered(body: Node) -> void:
	if body is Player:
		body._on_body_entered(self)


func _build_visual() -> void:
	_visual_node = Node2D.new()
	add_child(_visual_node)

	var body := Polygon2D.new()
	body.color = color
	var pts := PackedVector2Array()
	for i in range(6):
		var a := TAU * float(i) / 6.0
		pts.append(Vector2(cos(a), sin(a)) * size)
	body.polygon = pts
	_visual_node.add_child(body)

	# Funkel-Partikel-Look (Sterne um den Körper)
	for i in range(4):
		var a := TAU * float(i) / 4.0 + 0.3
		var spark := Polygon2D.new()
		spark.color = Color(0.9, 0.6, 1.0, 0.7)
		var spts := PackedVector2Array()
		for j in range(4):
			var sa := TAU * float(j) / 4.0
			spts.append(Vector2(cos(sa), sin(sa)) * 3.0)
		spark.polygon = spts
		spark.position = Vector2(cos(a), sin(a)) * size * 1.4
		_visual_node.add_child(spark)

	_cshape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size
	_cshape.shape = circle
	add_child(_cshape)

	var area := Area2D.new()
	var area_shape := CollisionShape2D.new()
	area_shape.shape = circle.duplicate()
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)
