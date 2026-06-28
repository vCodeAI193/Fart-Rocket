extends Area2D
class_name WindZone
## WindZone – Windströmung
## =======================
## FR-013/FR-030: Übt eine konstante Kraft auf den Spieler aus.

@export var wind_force: Vector2 = Vector2(-200, 0)  # Kraft in px/s² (negativ = links)
@export var zone_size: Vector2 = Vector2(250, 300)
@export var wind_color: Color = Color(0.5, 0.8, 1.0, 0.15)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visual()


var _bodies: Array[RigidBody2D] = []


func _physics_process(delta: float) -> void:
	for body in _bodies:
		if is_instance_valid(body):
			body.apply_central_force(wind_force)


func _on_body_entered(body: Node) -> void:
	if body is RigidBody2D:
		_bodies.append(body as RigidBody2D)


func _on_body_exited(body: Node) -> void:
	if body is RigidBody2D:
		_bodies.erase(body as RigidBody2D)


func _build_visual() -> void:
	# Kollisionsform
	var cshape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = zone_size
	cshape.shape = rect
	add_child(cshape)

	# Hintergrund-Tint
	var bg := Polygon2D.new()
	var hw := zone_size.x * 0.5
	var hh := zone_size.y * 0.5
	bg.color = wind_color
	bg.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh),
	])
	add_child(bg)

	# Windpfeile (3 horizontale Linien)
	var dir := wind_force.normalized()
	for i in range(3):
		var arrow := Line2D.new()
		arrow.width = 3.5
		arrow.default_color = Color(0.6, 0.85, 1.0, 0.7)
		var y := -hh * 0.5 + hh * float(i) / 2.0 + hh * 0.25
		var length := zone_size.x * 0.5
		arrow.add_point(Vector2(-dir.x * length, y))
		arrow.add_point(Vector2(dir.x * length, y))
		# Pfeilspitze
		var tip := Vector2(dir.x * length, y)
		arrow.add_point(tip - dir.rotated(0.5) * 18.0)
		arrow.add_point(tip)
		arrow.add_point(tip - dir.rotated(-0.5) * 18.0)
		add_child(arrow)
