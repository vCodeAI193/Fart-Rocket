extends Area2D
class_name ProximityMine
## ProximityMine – Tickende Mine, explodiert bei Nähe (FR-078)
## ================================================================
## Eine Mine, die bei Annäherung des Spielers zu ticken beginnt
## und nach kurzer Verzögerung explodiert.

@export var trigger_radius: float = 100.0
@export var fuse_time: float = 1.0
@export var explosion_radius: float = 70.0
@export var size: float = 16.0
@export var color: Color = Color(0.25, 0.25, 0.3)

var _triggered: bool = false
var _fuse_timer: float = 0.0
var _player_ref: Player = null
var _body_node: Polygon2D


func _ready() -> void:
	add_to_group("obstacles")
	_build_visual()


func _process(delta: float) -> void:
	if _triggered:
		_fuse_timer -= delta
		# Beschleunigtes Blinken je näher die Explosion
		var blink_speed := lerpf(6.0, 20.0, 1.0 - clampf(_fuse_timer / fuse_time, 0.0, 1.0))
		_body_node.modulate = Color(1.0, 0.2, 0.1).lerp(color, (sin(Time.get_ticks_msec() * 0.001 * blink_speed) + 1.0) * 0.5)
		if _fuse_timer <= 0.0:
			_explode()
		return

	_find_player()
	if _player_ref != null and is_instance_valid(_player_ref):
		if global_position.distance_to(_player_ref.global_position) < trigger_radius:
			_triggered = true
			_fuse_timer = fuse_time
			GameManager.vibrate(20)


func _find_player() -> void:
	if _player_ref != null and is_instance_valid(_player_ref):
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0]


func _explode() -> void:
	GameManager.vibrate(90)

	# Explosions-Partikel
	var p := CPUParticles2D.new()
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.amount = 24
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.direction = Vector2.ZERO
	p.spread = 180.0
	p.initial_velocity_min = 150.0
	p.initial_velocity_max = 400.0
	p.color = Color(1.0, 0.5, 0.1)
	get_tree().create_timer(0.6).timeout.connect(p.queue_free)

	# Spieler in Radius töten
	if _player_ref != null and is_instance_valid(_player_ref):
		if global_position.distance_to(_player_ref.global_position) < explosion_radius:
			_player_ref._on_body_entered(self)

	queue_free()


func _build_visual() -> void:
	_body_node = Polygon2D.new()
	_body_node.color = color
	var pts := PackedVector2Array()
	for i in range(10):
		var a := TAU * float(i) / 10.0
		pts.append(Vector2(cos(a), sin(a)) * size)
	_body_node.polygon = pts
	add_child(_body_node)

	# Stacheln (Mine-Look)
	for i in range(6):
		var angle := TAU * float(i) / 6.0
		var spike := Line2D.new()
		spike.points = [Vector2(cos(angle), sin(angle)) * size * 0.7, Vector2(cos(angle), sin(angle)) * size * 1.3]
		spike.width = 2.5
		spike.default_color = color.darkened(0.2)
		add_child(spike)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size
	cshape.shape = circle
	add_child(cshape)
