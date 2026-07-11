extends CharacterBody2D
class_name MiniBoss
## MiniBoss – Mini-Boss pro Welt (FR-112)
## ===========================================
## Ein kompakter Boss-Gegner: Verfolgt den Spieler, lungt gelegentlich
## nach vorn, und hat eine zentrale Schwachstelle (FR-119). Der Körper
## selbst ist bei Frontalkontakt tödlich; nur die Schwachstelle kann
## den Boss besiegen.

signal boss_defeated

@export var chase_speed: float = 100.0
@export var detection_radius: float = 400.0
@export var lunge_telegraph_time: float = 0.7
@export var lunge_speed: float = 420.0
@export var lunge_duration: float = 0.35
@export var lunge_cooldown: float = 2.0
@export var body_radius: float = 40.0
@export var weak_point_hits: int = 3
@export var body_color: Color = Color(0.5, 0.15, 0.6)

enum State { CHASE, TELEGRAPH, LUNGE, COOLDOWN }
var _state: State = State.CHASE
var _timer: float = 0.0
var _lunge_dir: Vector2 = Vector2.ZERO
var _player_ref: Player = null
var _body_visual: Polygon2D
var _weak_point: BossWeakPoint
var _defeated: bool = false


func _ready() -> void:
	add_to_group("obstacles")
	add_to_group("bosses")
	GameManager.discover_enemy("MiniBoss")  # FR-118
	_build_visual()


func _physics_process(delta: float) -> void:
	if _defeated:
		return
	_find_player()
	if _player_ref == null or not is_instance_valid(_player_ref):
		return

	# FR-117: KI-Schwierigkeitsskalierung
	var difficulty := GameManager.get_difficulty_multiplier()

	match _state:
		State.CHASE:
			var to_player := _player_ref.global_position - global_position
			if to_player.length() < detection_radius:
				var dir := to_player.normalized()
				position += dir * chase_speed * difficulty * delta
				rotation = lerp_angle(rotation, dir.angle(), 0.08)
				if to_player.length() < detection_radius * 0.6:
					_state = State.TELEGRAPH
					_timer = lunge_telegraph_time
		State.TELEGRAPH:
			_timer -= delta
			var progress := 1.0 - clampf(_timer / lunge_telegraph_time, 0.0, 1.0)
			_body_visual.modulate = Color.WHITE.lerp(Color(1.0, 0.4, 0.3), progress)
			if _timer <= 0.0:
				_state = State.LUNGE
				_timer = lunge_duration
				_lunge_dir = (_player_ref.global_position - global_position).normalized()
				GameManager.vibrate(40)
		State.LUNGE:
			position += _lunge_dir * lunge_speed * difficulty * delta
			_timer -= delta
			if _timer <= 0.0:
				_state = State.COOLDOWN
				_timer = lunge_cooldown
				_body_visual.modulate = Color.WHITE
		State.COOLDOWN:
			_timer -= delta
			if _timer <= 0.0:
				_state = State.CHASE


func _find_player() -> void:
	if _player_ref != null and is_instance_valid(_player_ref):
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0]


## FR-347: Verdoppelt die benötigten Treffer für den Boss-Rush-Modus.
func double_difficulty() -> void:
	if is_instance_valid(_weak_point):
		_weak_point.hits_required *= 2


func _on_weak_point_defeated() -> void:
	_defeated = true
	add_to_group("obstacles_neutral")  # nicht länger tödlich
	remove_from_group("obstacles")
	GameManager.vibrate(100)
	var reward := GameManager.grant_enemy_defeat_reward(80)
	GameManager.add_xp(60)
	if FloatingText:
		FloatingText.spawn(get_parent(), global_position, "Boss besiegt!", Color(1.0, 0.85, 0.2))

	boss_defeated.emit()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished
	queue_free()


func _on_body_entered(body: Node) -> void:
	if _defeated or not (body is Player):
		return
	body._on_body_entered(self)


func _build_visual() -> void:
	_body_visual = Polygon2D.new()
	_body_visual.color = body_color
	var pts := PackedVector2Array()
	for i in range(12):
		var a := TAU * float(i) / 12.0
		pts.append(Vector2(cos(a), sin(a)) * body_radius)
	_body_visual.polygon = pts
	add_child(_body_visual)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = body_radius
	cshape.shape = circle
	add_child(cshape)

	var area := Area2D.new()
	var area_shape := CollisionShape2D.new()
	area_shape.shape = circle.duplicate()
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

	# Zentrale Schwachstelle (FR-119)
	_weak_point = BossWeakPoint.new()
	_weak_point.hits_required = weak_point_hits
	_weak_point.radius = body_radius * 0.4
	_weak_point.defeated.connect(_on_weak_point_defeated)
	add_child(_weak_point)
