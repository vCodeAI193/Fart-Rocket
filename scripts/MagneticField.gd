extends Area2D
class_name MagneticField
## MagneticField – Magnetfeld
## ==========================
## FR-027: Zieht den Spieler an oder stösst ihn ab.

@export var attract: bool = true          # true = Anziehung, false = Abstossung
@export var strength: float = 500.0      # Kraft in px/s²
@export var field_radius: float = 160.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visual()


var _bodies: Array[RigidBody2D] = []


func _physics_process(_delta: float) -> void:
	for body in _bodies:
		if not is_instance_valid(body):
			continue
		var to_center := global_position - body.global_position
		var dist := to_center.length()
		if dist < 1.0:
			continue
		var force_dir := to_center.normalized() if attract else -to_center.normalized()
		# Kraft nimmt mit Abstand ab (invers)
		var force_mag := strength * clampf(1.0 - dist / field_radius, 0.0, 1.0)
		body.apply_central_force(force_dir * force_mag * body.mass)


func _on_body_entered(body: Node) -> void:
	if body is RigidBody2D:
		_bodies.append(body as RigidBody2D)


func _on_body_exited(body: Node) -> void:
	if body is RigidBody2D:
		_bodies.erase(body as RigidBody2D)


func _build_visual() -> void:
	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = field_radius
	cshape.shape = circle
	add_child(cshape)
	# Konzentrische Kreise
	var col := Color(0.3, 0.6, 1.0, 0.4) if attract else Color(1.0, 0.4, 0.2, 0.4)
	for r in [field_radius, field_radius * 0.65, field_radius * 0.35]:
		var ring := Polygon2D.new()
		ring.color = col
		var pts := PackedVector2Array()
		for i in range(32):
			var a := TAU * float(i) / 32.0
			pts.append(Vector2(cos(a), sin(a)) * r)
		ring.polygon = pts
		add_child(ring)
	# Symbol +/- in der Mitte
	var lbl := Label.new()
	lbl.text = "+" if attract else "-"
	lbl.add_theme_font_size_override("font_size", 52)
	lbl.add_theme_color_override("font_color", col.lightened(0.4))
	lbl.position = Vector2(-16, -28)
	add_child(lbl)
