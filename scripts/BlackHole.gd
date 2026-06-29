extends Area2D
class_name BlackHole
## BlackHole – Schwarzes Loch mit Anziehungskraft (FR-031)
## ====================================================
## Eine Zone, die alles zu sich anzieht. Der Spieler wird
## beschleunigt, wenn er zu nah dran ist.

@export var pull_force: float = 800.0
@export var effect_radius: float = 400.0
@export var color: Color = Color(0.2, 0.0, 0.3, 0.4)
@export var zone_size: Vector2 = Vector2(100, 100)

var _affected_bodies: Array[Node2D] = []


func _ready() -> void:
	add_to_group("hazards")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_build_visual()


func _physics_process(delta: float) -> void:
	for body in _affected_bodies:
		if not is_instance_valid(body):
			continue
		if body is RigidBody2D:
			var dist := global_position.distance_to(body.global_position)
			if dist < effect_radius and dist > 1.0:
				var direction := (global_position - body.global_position).normalized()
				var force := pull_force * (1.0 - (dist / effect_radius))
				body.apply_central_force(direction * force)


func _on_area_entered(area: Area2D) -> void:
	if area is Player or (area.owner is Player):
		if not area in _affected_bodies:
			_affected_bodies.append(area)
		GameManager.vibrate(10)


func _on_area_exited(area: Area2D) -> void:
	if area is Player or (area.owner is Player):
		_affected_bodies.erase(area)


func _build_visual() -> void:
	var outer_circle := ColorRect.new()
	outer_circle.size = zone_size
	outer_circle.position = -zone_size * 0.5
	outer_circle.color = color
	add_child(outer_circle)

	# Äußere Sternenkranz
	var points := []
	for i in range(16):
		var angle := TAU * float(i) / 16.0
		var radius := effect_radius * 0.8 if i % 2 == 0 else effect_radius * 0.9
		points.append(global_position + Vector2(cos(angle), sin(angle)) * radius)

	# Schwarzloch-Kern (dunkelster Punkt)
	var core := ColorRect.new()
	var core_size = 20
	core.size = Vector2(core_size, core_size)
	core.position = -Vector2(core_size * 0.5, core_size * 0.5)
	core.color = Color(0.05, 0.0, 0.1, 0.9)
	add_child(core)

	# Event-Horizont-Ring
	var horizon := Line2D.new()
	var h_points := []
	for i in range(20):
		var a := TAU * float(i) / 20.0
		h_points.append(Vector2(cos(a), sin(a)) * zone_size.x * 0.5)
	h_points.append(h_points[0])
	horizon.points = h_points
	horizon.width = 3.0
	horizon.default_color = Color(0.8, 0.3, 0.9, 0.8)
	add_child(horizon)

	# Spiral-Effekt (2 spiralen)
	for spiral_idx in range(2):
		var spiral := Line2D.new()
		var s_points := []
		for i in range(30):
			var t := float(i) / 30.0
			var angle := TAU * (spiral_idx * 0.5) + TAU * t * 3.0
			var radius := zone_size.x * 0.2 * (1.0 + t * 0.5)
			s_points.append(Vector2(cos(angle), sin(angle)) * radius)
		spiral.points = s_points
		spiral.width = 2.0
		spiral.default_color = Color(0.7, 0.2, 0.8, 0.5)
		add_child(spiral)

	# Collision Shape
	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = zone_size.x * 0.5 + 10.0
	cshape.shape = circle
	add_child(cshape)
