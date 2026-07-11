extends Node2D
class_name EnemySpawner
## EnemySpawner – Gegner-Spawner und Nest (FR-114)
## ====================================================
## Erzeugt periodisch Instanzen einer Gegner-Szene, bis eine
## maximale Anzahl gleichzeitig lebender Gegner erreicht ist.

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 3.0
@export var max_alive: int = 3
@export var spawn_radius: float = 40.0
@export var nest_visual_radius: float = 24.0
@export var nest_color: Color = Color(0.35, 0.2, 0.1)

var _timer: float = 0.0
var _alive_enemies: Array[Node] = []


func _ready() -> void:
	_timer = spawn_interval * 0.5
	_build_visual()


func _process(delta: float) -> void:
	_alive_enemies = _alive_enemies.filter(func(e): return is_instance_valid(e))

	if enemy_scene == null:
		return

	_timer -= delta
	if _timer <= 0.0:
		_timer = spawn_interval
		if _alive_enemies.size() < max_alive:
			_spawn_enemy()


func _spawn_enemy() -> void:
	var enemy := enemy_scene.instantiate()
	var offset := Vector2(randf_range(-spawn_radius, spawn_radius), randf_range(-spawn_radius, spawn_radius))
	enemy.global_position = global_position + offset
	get_parent().add_child(enemy)
	_alive_enemies.append(enemy)

	# Spawn-Effekt
	if enemy is Node2D:
		enemy.scale = Vector2.ZERO
		var tween := enemy.create_tween()
		tween.tween_property(enemy, "scale", Vector2.ONE, 0.25)
	GameManager.vibrate(10)


func _build_visual() -> void:
	var nest := Polygon2D.new()
	nest.color = nest_color
	var pts := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	for i in range(12):
		var a := TAU * float(i) / 12.0
		var r := nest_visual_radius * rng.randf_range(0.85, 1.15)
		pts.append(Vector2(cos(a), sin(a)) * r)
	nest.polygon = pts
	add_child(nest)

	# Dunklerer innerer Ring (Nest-Öffnung)
	var opening := Polygon2D.new()
	opening.color = nest_color.darkened(0.5)
	var opts := PackedVector2Array()
	for i in range(10):
		var a := TAU * float(i) / 10.0
		opts.append(Vector2(cos(a), sin(a)) * nest_visual_radius * 0.4)
	opening.polygon = opts
	add_child(opening)
