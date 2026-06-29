extends StaticBody2D
class_name BouncyWall
## BouncyWall – Elastische Wände mit Energieerhalt (FR-034)
## ========================================================
## Eine Wand, die den Spieler mit voller Energie zurückwirft.
## Ideal für Rätsel mit Richtungswechseln.

@export var size: Vector2 = Vector2(100, 20)
@export var bounce_elasticity: float = 1.1  # >1 = mehr Energie zurück
@export var color: Color = Color(1.0, 0.6, 0.2, 0.8)

var _last_bounce_body: Node = null
var _last_bounce_time: float = 0.0


func _ready() -> void:
	add_to_group("hazards")
	_build_visual()


func _on_body_entered(body: Node) -> void:
	if not (body is Player or (body.owner is Player)):
		return

	# Nur wenn nicht gerade geprellt
	if _last_bounce_body == body and Time.get_ticks_msec() / 1000.0 - _last_bounce_time < 0.1:
		return

	if body is RigidBody2D:
		var vel := body.linear_velocity
		var normal := _get_bounce_normal(body.global_position)

		# Elastischer Rückprall
		var reflected := vel.reflect(normal) * bounce_elasticity
		body.linear_velocity = reflected

		_last_bounce_body = body
		_last_bounce_time = Time.get_ticks_msec() / 1000.0

		GameManager.vibrate(30)


func _get_bounce_normal(body_pos: Vector2) -> Vector2:
	# Bestimme welche Seite der Wand getroffen wurde
	var local_pos := body_pos - global_position
	var abs_x := abs(local_pos.x)
	var abs_y := abs(local_pos.y)

	if abs_x > abs_y:
		return Vector2(1.0 if local_pos.x > 0 else -1.0, 0)
	else:
		return Vector2(0, 1.0 if local_pos.y > 0 else -1.0)


func _build_visual() -> void:
	var rect := ColorRect.new()
	rect.size = size
	rect.position = -size * 0.5
	rect.color = color
	add_child(rect)

	# Diagonal-Muster (Federn-Design)
	var pattern_width := size.x / 4.0
	for i in range(4):
		var line := Line2D.new()
		var x := -size.x * 0.5 + i * pattern_width + pattern_width * 0.5
		line.points = [
			Vector2(x - pattern_width * 0.3, -size.y * 0.5),
			Vector2(x + pattern_width * 0.3, size.y * 0.5)
		]
		line.width = 3.0
		line.default_color = Color(1.0, 0.9, 0.6, 0.9)
		add_child(line)

	# "BOUNCE" Label
	var label := Label.new()
	label.text = "BOUNCE"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
	label.position = Vector2(-size.x * 0.5 + 5, -size.y * 0.5 + 2)
	add_child(label)

	# Collision Shape
	var cshape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	cshape.shape = rect_shape
	add_child(cshape)

	# Verbinde body_entered Signal
	var area := Area2D.new()
	area.position = Vector2.ZERO
	var area_shape := CollisionShape2D.new()
	area_shape.shape = rect_shape.duplicate()
	area.add_child(area_shape)
	area.area_entered.connect(_on_area_entered)
	add_child(area)


func _on_area_entered(area: Area2D) -> void:
	if area is Player or (area.owner is Player):
		_on_body_entered(area if area is RigidBody2D else area.owner)
