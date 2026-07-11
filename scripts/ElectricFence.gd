extends Area2D
class_name ElectricFence
## ElectricFence – Elektro-Zaun mit Stromfeld (FR-069)
## ======================================================
## Ein Zaun, der periodisch unter Strom steht (aktiv/inaktiv).
## Nur während der aktiven Phase tödlich.

@export var fence_size: Vector2 = Vector2(20, 180)
@export var active_time: float = 1.0
@export var inactive_time: float = 1.0
@export var start_active: bool = true
@export var color_active: Color = Color(0.3, 0.9, 1.0, 0.9)
@export var color_inactive: Color = Color(0.3, 0.3, 0.35, 0.5)

var _is_active: bool = true
var _timer: float = 0.0
var _fence_visual: Node2D
var _cshape: CollisionShape2D


func _ready() -> void:
	add_to_group("obstacles")
	body_entered.connect(_on_body_entered)
	_is_active = start_active
	_timer = active_time if start_active else inactive_time
	_build_visual()
	_update_state()


func _process(delta: float) -> void:
	_timer -= delta

	if _is_active:
		# Elektrisches Flackern
		_fence_visual.modulate.a = 0.7 + sin(Time.get_ticks_msec() * 0.03) * 0.3

	if _timer <= 0.0:
		_is_active = not _is_active
		_timer = active_time if _is_active else inactive_time
		_update_state()
		GameManager.vibrate(10)


func _update_state() -> void:
	_cshape.disabled = not _is_active
	var tween := create_tween()
	var target_color := color_active if _is_active else color_inactive
	tween.tween_property(_fence_visual, "modulate", target_color, 0.1)


func _on_body_entered(body: Node) -> void:
	if body is Player and _is_active:
		body._on_body_entered(self)


func _build_visual() -> void:
	_fence_visual = Node2D.new()
	add_child(_fence_visual)

	# Zaun-Pfosten
	var post_count := int(fence_size.y / 30.0)
	for i in range(post_count):
		var y := -fence_size.y * 0.5 + i * 30.0
		var post := ColorRect.new()
		post.size = Vector2(fence_size.x, 6)
		post.position = Vector2(-fence_size.x * 0.5, y)
		post.color = Color(0.5, 0.5, 0.5)
		_fence_visual.add_child(post)

	# Blitz-Zickzack-Linie (Strom-Symbol)
	var bolt := Line2D.new()
	var points := []
	var step := fence_size.y / 8.0
	for i in range(9):
		var x := (10.0 if i % 2 == 0 else -10.0)
		var y := -fence_size.y * 0.5 + i * step
		points.append(Vector2(x, y))
	bolt.points = points
	bolt.width = 3.0
	bolt.default_color = Color(1.0, 1.0, 0.3, 0.9)
	_fence_visual.add_child(bolt)

	# Vertikale Seitenlinien
	for side in [-1, 1]:
		var line := Line2D.new()
		line.points = [
			Vector2(side * fence_size.x * 0.5, -fence_size.y * 0.5),
			Vector2(side * fence_size.x * 0.5, fence_size.y * 0.5),
		]
		line.width = 3.0
		line.default_color = color_active
		_fence_visual.add_child(line)

	_cshape = CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = fence_size
	_cshape.shape = rect_shape
	add_child(_cshape)
