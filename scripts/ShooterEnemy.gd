extends StaticBody2D
class_name ShooterEnemy
## ShooterEnemy – Schießender Gegner (FR-103)
## ===========================================
## Ein stationärer Gegner-Geschützturm, der in regelmäßigen
## Abständen Projektile in Richtung des Spielers abfeuert.

@export var fire_interval: float = 2.0
@export var projectile_speed: float = 400.0
@export var detection_radius: float = 500.0
@export var size: float = 24.0
@export var color: Color = Color(0.7, 0.15, 0.15)
@export var projectile_scene: PackedScene

var _fire_timer: float = 0.0
var _player_ref: Player = null


func _ready() -> void:
	add_to_group("obstacles")
	_build_visual()
	_fire_timer = fire_interval * 0.5


func _process(delta: float) -> void:
	_find_player()
	if _player_ref == null:
		return

	var dist := global_position.distance_to(_player_ref.global_position)
	if dist > detection_radius:
		return

	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = fire_interval
		_shoot()


func _find_player() -> void:
	if _player_ref != null and is_instance_valid(_player_ref):
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0]


func _shoot() -> void:
	if _player_ref == null:
		return

	var dir := (_player_ref.global_position - global_position).normalized()

	var projectile: Projectile
	if projectile_scene != null:
		projectile = projectile_scene.instantiate()
	else:
		projectile = Projectile.new()

	projectile.direction = dir
	projectile.speed = projectile_speed
	projectile.global_position = global_position

	get_parent().add_child(projectile)

	GameManager.vibrate(15)
	_muzzle_flash(dir)


func _muzzle_flash(dir: Vector2) -> void:
	var flash := ColorRect.new()
	flash.size = Vector2(16, 16)
	flash.position = dir * size - Vector2(8, 8)
	flash.color = Color(1.0, 0.9, 0.3, 0.9)
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.15)
	tween.tween_callback(flash.queue_free)


func _build_visual() -> void:
	# Turm-Basis
	var base := Polygon2D.new()
	base.color = color
	var pts := PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		pts.append(Vector2(cos(a), sin(a)) * size)
	base.polygon = pts
	add_child(base)

	# Innerer Kern (dunkler)
	var core := Polygon2D.new()
	core.color = Color(0.3, 0.05, 0.05)
	pts = PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		pts.append(Vector2(cos(a), sin(a)) * (size * 0.5))
	core.polygon = pts
	add_child(core)

	# Kanonenrohr
	var barrel := ColorRect.new()
	barrel.size = Vector2(size * 1.2, 8)
	barrel.position = Vector2(0, -4)
	barrel.color = Color(0.3, 0.1, 0.1)
	add_child(barrel)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size
	cshape.shape = circle
	add_child(cshape)
