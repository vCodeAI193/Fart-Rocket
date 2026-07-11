extends Node2D
class_name SeededObstacleField
## SeededObstacleField – Zufällig generierte Hindernis-Layouts (FR-079)
## ========================================================================
## Erzeugt ein deterministisches Feld aus Hindernissen (Obstacle.gd)
## basierend auf einem festen Seed. Gleicher Seed = identisches Layout,
## reproduzierbar über mehrere Spieldurchläufe hinweg.

@export var seed_value: int = 12345
@export var field_size: Vector2 = Vector2(1200, 800)
@export var obstacle_count: int = 8
@export var min_spacing: float = 120.0

var _placed_positions: Array[Vector2] = []


func _ready() -> void:
	_generate_field()


func _generate_field() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var attempts := 0
	var placed := 0
	while placed < obstacle_count and attempts < obstacle_count * 20:
		attempts += 1
		var pos := Vector2(
			rng.randf_range(0, field_size.x),
			rng.randf_range(0, field_size.y)
		)

		# Mindestabstand zu bereits platzierten Hindernissen prüfen
		var too_close := false
		for existing in _placed_positions:
			if existing.distance_to(pos) < min_spacing:
				too_close = true
				break
		if too_close:
			continue

		_placed_positions.append(pos)
		_spawn_obstacle(pos, rng)
		placed += 1


func _spawn_obstacle(local_pos: Vector2, rng: RandomNumberGenerator) -> void:
	var obstacle := Obstacle.new()
	var type_roll: int = rng.randi_range(0, 2)
	obstacle.type = type_roll

	match obstacle.type:
		Obstacle.ObstacleType.BALKEN:
			obstacle.obstacle_size = Vector2(rng.randf_range(80, 220), rng.randf_range(20, 50))
		Obstacle.ObstacleType.STACHELN:
			obstacle.obstacle_size = Vector2(rng.randf_range(100, 200), rng.randf_range(30, 60))
		Obstacle.ObstacleType.SAEGE:
			obstacle.saw_radius = rng.randf_range(40, 90)
			obstacle.rotation_speed = rng.randf_range(1.5, 4.5)

	obstacle.position = local_pos
	obstacle.rotation = rng.randf_range(0, TAU) if obstacle.type == Obstacle.ObstacleType.BALKEN else 0.0
	add_child(obstacle)
