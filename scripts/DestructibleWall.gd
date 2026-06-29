extends StaticBody2D
class_name DestructibleWall
## DestructibleWall – Zerstörbare Wände (FR-035)
## ===============================================
## Eine Wand, die bei ausreichend hoher Aufprallgeschwindigkeit
## zerstört wird und verschwindet.

@export var size: Vector2 = Vector2(100, 100)
@export var break_speed: float = 1000.0  # Mindest-Geschwindigkeit zum Zerstören
@export var color: Color = Color(0.7, 0.5, 0.2, 0.8)
@export var break_particle_count: int = 10

var _destroyed: bool = false


func _ready() -> void:
	add_to_group("hazards")
	_build_visual()


func _on_body_entered(body: Node) -> void:
	if _destroyed:
		return

	if not (body is Player or (body.owner is Player)):
		return

	if body is RigidBody2D:
		var speed := body.linear_velocity.length()
		if speed >= break_speed:
			_destroy()


func _destroy() -> void:
	_destroyed = true

	# Partikel-Effekt
	for i in range(break_particle_count):
		var particle := ColorRect.new()
		particle.size = Vector2(10, 10)
		particle.color = color
		particle.position = global_position + Vector2(
			randf_range(-size.x * 0.5, size.x * 0.5),
			randf_range(-size.y * 0.5, size.y * 0.5)
		)
		get_parent().add_child(particle)

		var vel := Vector2(
			randf_range(-500, 500),
			randf_range(-500, 500)
		)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", particle.position + vel * 0.5, 0.5)
		tween.tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)

	# Vibration
	GameManager.vibrate(50)

	# Wand verschwinden
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _build_visual() -> void:
	var rect := ColorRect.new()
	rect.size = size
	rect.position = -size * 0.5
	rect.color = color
	add_child(rect)

	# Risse-Muster (horizontale und vertikale Linien)
	for i in range(3):
		var x := -size.x * 0.5 + (i + 1) * size.x * 0.25
		var line := Line2D.new()
		line.points = [
			Vector2(x, -size.y * 0.5),
			Vector2(x, size.y * 0.5)
		]
		line.width = 2.0
		line.default_color = Color(0.3, 0.2, 0.05, 0.5)
		add_child(line)

	for i in range(2):
		var y := -size.y * 0.5 + (i + 1) * size.y * 0.33
		var line := Line2D.new()
		line.points = [
			Vector2(-size.x * 0.5, y),
			Vector2(size.x * 0.5, y)
		]
		line.width = 2.0
		line.default_color = Color(0.3, 0.2, 0.05, 0.5)
		add_child(line)

	# "ZERSTÖRBAR" Label
	var label := Label.new()
	label.text = "X"
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.1, 0.8))
	label.position = -Vector2(12, 16)
	add_child(label)

	# Collision Shape
	var cshape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	cshape.shape = rect_shape
	add_child(cshape)

	# Area für Collision-Detection
	var area := Area2D.new()
	var area_shape := CollisionShape2D.new()
	area_shape.shape = rect_shape.duplicate()
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)
