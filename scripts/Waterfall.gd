extends Area2D
class_name Waterfall
## Waterfall – Wasserfall mit Abwärtsdruck (FR-076)
## ====================================================
## Eine Zone, die kontinuierlich nach unten drückt.
## Nicht tödlich, aber erschwert das Aufsteigen erheblich.

@export var zone_size: Vector2 = Vector2(120, 400)
@export var push_force: float = 900.0
@export var color: Color = Color(0.3, 0.6, 0.9, 0.35)

var _bodies_in_fall: Array[Node2D] = []


func _ready() -> void:
	add_to_group("hazards")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visual()


func _physics_process(delta: float) -> void:
	for body in _bodies_in_fall:
		if is_instance_valid(body) and body is RigidBody2D:
			body.apply_central_force(Vector2.DOWN * push_force)

	if randf() < 0.4:
		_spawn_droplet()


func _spawn_droplet() -> void:
	var drop := ColorRect.new()
	drop.size = Vector2(3, 10)
	drop.color = Color(0.6, 0.85, 1.0, 0.7)
	drop.position = Vector2(
		global_position.x + randf_range(-zone_size.x * 0.4, zone_size.x * 0.4),
		global_position.y - zone_size.y * 0.5
	)
	get_parent().add_child(drop)

	var tween := create_tween()
	tween.tween_property(drop, "position:y", drop.position.y + zone_size.y, 0.6)
	tween.parallel().tween_property(drop, "modulate:a", 0.0, 0.6)
	tween.tween_callback(drop.queue_free)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return
	if not player in _bodies_in_fall:
		_bodies_in_fall.append(player)


func _on_body_exited(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return
	_bodies_in_fall.erase(player)


func _build_visual() -> void:
	var rect := ColorRect.new()
	rect.size = zone_size
	rect.position = -zone_size * 0.5
	rect.color = color
	add_child(rect)

	# Vertikale Fließ-Linien
	for i in range(5):
		var x := -zone_size.x * 0.35 + i * zone_size.x * 0.17
		var line := Line2D.new()
		line.points = [Vector2(x, -zone_size.y * 0.5), Vector2(x, zone_size.y * 0.5)]
		line.width = 3.0
		line.default_color = Color(0.5, 0.8, 1.0, 0.5)
		add_child(line)

	var cshape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = zone_size
	cshape.shape = rect_shape
	add_child(cshape)
