extends Node2D
class_name RotatingWheel
## RotatingWheel – Rotierendes Hindernis-Rad mit Lücken (FR-070)
## =================================================================
## Ein Rad mit Stacheln, das sich dreht und Lücken hat,
## durch die der Spieler hindurchfliegen kann (Timing-Rätsel).

@export var radius: float = 90.0
@export var spike_count: int = 8
@export var gap_count: int = 2  # Anzahl der Lücken im Stachel-Ring
@export var rotation_speed: float = 1.0  # Rad/Sekunde
@export var color: Color = Color(0.55, 0.5, 0.55)

var _wheel_node: Node2D


func _ready() -> void:
	_build_visual()


func _process(delta: float) -> void:
	_wheel_node.rotation += rotation_speed * TAU * delta


func _build_visual() -> void:
	_wheel_node = Node2D.new()
	add_child(_wheel_node)

	# Zentral-Nabe
	var hub := Polygon2D.new()
	hub.color = color.darkened(0.2)
	var hpts := PackedVector2Array()
	for i in range(12):
		var a := TAU * float(i) / 12.0
		hpts.append(Vector2(cos(a), sin(a)) * radius * 0.25)
	hub.polygon = hpts
	_wheel_node.add_child(hub)

	# Speichen + Stacheln, mit Lücken ausgespart
	var gap_indices := {}
	var gap_step := spike_count / maxi(gap_count, 1)
	for g in range(gap_count):
		gap_indices[g * gap_step] = true

	for i in range(spike_count):
		if gap_indices.has(i):
			continue
		var angle := TAU * float(i) / spike_count

		# Speiche
		var spoke := Line2D.new()
		spoke.points = [Vector2.ZERO, Vector2(cos(angle), sin(angle)) * radius * 0.7]
		spoke.width = 6.0
		spoke.default_color = color
		_wheel_node.add_child(spoke)

		# Stachel-Spitze
		var spike := Polygon2D.new()
		spike.color = color.darkened(0.1)
		var base := Vector2(cos(angle), sin(angle)) * radius * 0.65
		var tip := Vector2(cos(angle), sin(angle)) * radius
		var perp := Vector2(-sin(angle), cos(angle)) * radius * 0.12
		spike.polygon = PackedVector2Array([base - perp, tip, base + perp])
		_wheel_node.add_child(spike)

		# Collision nur an Stachel-Position (Segment-Shape)
		var area := Area2D.new()
		var cshape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = radius * 0.18
		cshape.shape = circle
		cshape.position = Vector2(cos(angle), sin(angle)) * radius * 0.85
		area.add_child(cshape)
		area.body_entered.connect(_on_body_entered)
		area.add_to_group("obstacles")
		_wheel_node.add_child(area)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		body._on_body_entered(self)
