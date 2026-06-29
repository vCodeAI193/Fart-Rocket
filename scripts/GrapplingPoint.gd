extends Area2D
class_name GrapplingPoint
## GrapplingPoint – Schwungpunkt für Pendel-Mechanik (FR-037)
## =========================================================
## Ein Punkt, an dem sich der Spieler "festhalten" kann
## und dann wie an einem Seil schwingt.

@export var rope_length: float = 150.0
@export var size: float = 12.0
@export var color: Color = Color(1.0, 0.7, 0.2)

var _player: Player = null
var _grappled: bool = false
var _rope_angle: float = 0.0
var _rope_speed: float = 0.0


func _ready() -> void:
	add_to_group("hazards")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_build_visual()


func _physics_process(delta: float) -> void:
	if not _grappled or _player == null:
		return

	if not is_instance_valid(_player):
		_grappled = false
		return

	# Schwung-Physik: Pendel an einem Seil
	var player_pos := _player.global_position
	var rope_vec := player_pos - global_position
	var current_length := rope_vec.length()

	# Wenn der Spieler zu weit weg ist, entfernen wir den Grapple
	if current_length > rope_length * 1.5:
		_grappled = false
		_player = null
		return

	# Begrenze die Position auf Seil-Länge
	if current_length > rope_length:
		var direction := rope_vec.normalized()
		_player.global_position = global_position + direction * rope_length

	# Schwung-Simulation: Die Geschwindigkeit tangential zur Seil-Richtung anwenden
	var player_vel := _player.linear_velocity
	var rope_direction := (player_pos - global_position).normalized()
	var tangent_direction := Vector2(-rope_direction.y, rope_direction.x)
	var tangent_vel := player_vel.dot(tangent_direction)

	# Weniger Bremsung durch Schwerkraft
	_player.gravity_scale = 0.2

	# Schwung-Kraft: radiale Komponente reduzieren (weg vom Punkt)
	var radial_vel := player_vel.dot(rope_direction)
	if radial_vel > 0:  # Spieler entfernt sich — bremsen
		var correction := -radial_vel * rope_direction * 0.5
		_player.linear_velocity += correction


func _on_area_entered(area: Area2D) -> void:
	if area is Player and not _grappled:
		_player = area
		_grappled = true
		GameManager.vibrate(20)


func _on_area_exited(area: Area2D) -> void:
	if area is Player and _grappled:
		_grappled = false
		# Wiederherstellen der Original-Schwerkraft
		_player.gravity_scale = _player.level_gravity_scale
		_player = null


func _build_visual() -> void:
	# Zentraler Punkt
	var center := ColorRect.new()
	center.size = Vector2(size, size)
	center.position = -Vector2(size * 0.5, size * 0.5)
	center.color = color
	add_child(center)

	# Ring um den Punkt
	var ring := Line2D.new()
	var points := []
	for i in range(12):
		var a := TAU * float(i) / 12.0
		points.append(Vector2(cos(a), sin(a)) * (size + 4.0))
	points.append(points[0])
	ring.points = points
	ring.width = 2.0
	ring.default_color = color
	add_child(ring)

	# Seil-Visualisierung (wird in _draw aktualisiert)
	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size + 6.0
	cshape.shape = circle
	add_child(cshape)


func _draw() -> void:
	if _grappled and _player != null:
		# Seil zeichnen
		var player_pos := _player.global_position - global_position
		draw_line(Vector2.ZERO, player_pos, Color(1.0, 0.8, 0.3, 0.6), 2.0)
