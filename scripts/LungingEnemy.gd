extends CharacterBody2D
class_name LungingEnemy
## LungingEnemy – Gegner mit telegrafiertem Sprungangriff (FR-111)
## ====================================================================
## Ein stationärer Gegner, der bei Spielernähe eine klare Vorwarnung
## zeigt (Ducken/Aufladen), bevor er in Spielerrichtung vorschnellt.

@export var detection_radius: float = 250.0
@export var telegraph_time: float = 0.6
@export var lunge_speed: float = 500.0
@export var lunge_duration: float = 0.3
@export var recovery_time: float = 1.0
@export var size: float = 18.0
@export var color: Color = Color(0.8, 0.4, 0.1)

enum State { IDLE, TELEGRAPH, LUNGING, RECOVERY }
var _state: State = State.IDLE
var _timer: float = 0.0
var _lunge_dir: Vector2 = Vector2.ZERO
var _player_ref: Player = null
var _body_visual: Polygon2D


func _ready() -> void:
	add_to_group("obstacles")
	GameManager.discover_enemy("LungingEnemy")  # FR-118: Bestiarium
	_build_visual()


func _physics_process(delta: float) -> void:
	_find_player()

	match _state:
		State.IDLE:
			if _player_ref != null and is_instance_valid(_player_ref):
				if global_position.distance_to(_player_ref.global_position) < detection_radius:
					_start_telegraph()
		State.TELEGRAPH:
			_timer -= delta
			# Ducken-Animation: Körper schrumpft leicht als Vorwarnung
			var progress := 1.0 - clampf(_timer / telegraph_time, 0.0, 1.0)
			_body_visual.scale = Vector2.ONE.lerp(Vector2(1.2, 0.7), progress)
			_body_visual.modulate = Color.WHITE.lerp(Color(1.0, 0.3, 0.2), progress)
			if _timer <= 0.0:
				_start_lunge()
		State.LUNGING:
			position += _lunge_dir * lunge_speed * delta
			_timer -= delta
			if _timer <= 0.0:
				_state = State.RECOVERY
				_timer = recovery_time
				_body_visual.scale = Vector2.ONE
				_body_visual.modulate = Color.WHITE
		State.RECOVERY:
			_timer -= delta
			if _timer <= 0.0:
				_state = State.IDLE


func _start_telegraph() -> void:
	_state = State.TELEGRAPH
	_timer = telegraph_time
	GameManager.vibrate(10)


func _start_lunge() -> void:
	_state = State.LUNGING
	_timer = lunge_duration
	if _player_ref != null and is_instance_valid(_player_ref):
		_lunge_dir = (_player_ref.global_position - global_position).normalized()
	else:
		_lunge_dir = Vector2.RIGHT
	GameManager.vibrate(40)


func _find_player() -> void:
	if _player_ref != null and is_instance_valid(_player_ref):
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0]


func _on_body_entered(body: Node) -> void:
	if body is Player:
		body._on_body_entered(self)


func _build_visual() -> void:
	_body_visual = Polygon2D.new()
	_body_visual.color = color
	var pts := PackedVector2Array()
	for i in range(9):
		var a := TAU * float(i) / 9.0
		pts.append(Vector2(cos(a), sin(a)) * size)
	_body_visual.polygon = pts
	add_child(_body_visual)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size
	cshape.shape = circle
	add_child(cshape)

	var area := Area2D.new()
	var area_shape := CollisionShape2D.new()
	area_shape.shape = circle.duplicate()
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)
