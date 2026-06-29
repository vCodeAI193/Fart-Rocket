extends Area2D
class_name BuoyancyZone
## BuoyancyZone – Auftrieb-Zone mit komplexer Wasser-Physik (FR-023)
## ================================================================
## Eine Zone mit Wasserdynamik: Auftriebskraft, Widerstand,
## und Wirbel-Effekte.

@export var buoyancy_force: float = 500.0
@export var drag_coefficient: float = 2.5
@export var current_direction: Vector2 = Vector2(0.5, 0).normalized()
@export var current_strength: float = 150.0
@export var zone_size: Vector2 = Vector2(500, 400)
@export var color: Color = Color(0.1, 0.5, 0.9, 0.2)

var _bodies_in_zone: Array[Node2D] = []


func _ready() -> void:
	add_to_group("hazards")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_build_visual()


func _physics_process(delta: float) -> void:
	for body in _bodies_in_zone:
		if not is_instance_valid(body):
			continue
		if body is RigidBody2D:
			# Auftrieb nach oben
			body.apply_central_force(Vector2.UP * buoyancy_force)

			# Strömungs-Kraft
			body.apply_central_force(current_direction * current_strength)

			# Widerstand (proportional zur Geschwindigkeit)
			var vel := body.linear_velocity
			var drag := -vel * drag_coefficient
			body.apply_central_force(drag)

			# Wirbel-Effekt (Rotation erzeugen)
			var torque := vel.x * 0.5
			body.apply_torque_impulse(torque)


func _on_area_entered(area: Area2D) -> void:
	if area is Player or (area.owner is Player):
		if not area in _bodies_in_zone:
			_bodies_in_zone.append(area if area is RigidBody2D else area.owner)


func _on_area_exited(area: Area2D) -> void:
	if area is Player or (area.owner is Player):
		_bodies_in_zone.erase(area if area is RigidBody2D else area.owner)


func _build_visual() -> void:
	var rect := ColorRect.new()
	rect.size = zone_size
	rect.position = -zone_size * 0.5
	rect.color = color
	add_child(rect)

	# Strömungs-Pfeile
	for i in range(6):
		for j in range(4):
			var x := -zone_size.x * 0.4 + i * zone_size.x * 0.2
			var y := -zone_size.y * 0.3 + j * zone_size.y * 0.2
			var arrow := Line2D.new()
			var arrow_size = 10.0
			arrow.points = [
				Vector2(x, y),
				Vector2(x + arrow_size, y),
				Vector2(x + arrow_size - 3, y - 3),
			]
			arrow.width = 1.5
			arrow.default_color = Color(0.2, 0.6, 1.0, 0.5)
			add_child(arrow)

	# Wirbel-Kreis unten (Sog)
	var vortex := Line2D.new()
	var v_points := []
	for i in range(20):
		var a := TAU * float(i) / 20.0
		var r := zone_size.x * 0.15 * (0.5 + 0.5 * sin(a * 3.0))
		v_points.append(Vector2(cos(a), sin(a)) * r + Vector2(0, zone_size.y * 0.3))
	vortex.points = v_points
	vortex.width = 2.0
	vortex.default_color = Color(0.1, 0.4, 0.8, 0.6)
	add_child(vortex)

	# "AUFTRIEB" Label
	var label := Label.new()
	label.text = "AUFTRIEB"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0, 0.9))
	label.position = Vector2(-zone_size.x * 0.5 + 10, -zone_size.y * 0.5 + 5)
	add_child(label)

	var cshape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = zone_size
	cshape.shape = rect_shape
	add_child(cshape)
