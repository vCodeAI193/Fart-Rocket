extends CharacterBody2D
class_name EndBoss
## EndBoss – End-Boss mit mehreren Phasen (FR-113)
## ====================================================
## Ein mehrphasiger Boss: startet vorsichtig (nur Lunge-Angriffe),
## wird nach jedem Schwachstellen-Treffer aggressiver (Phase 2:
## zusätzlich Projektile, Phase 3: "Rage"-Modus mit maximalem Tempo).

signal boss_defeated
signal phase_changed(phase: int)

@export var chase_speed: float = 90.0
@export var detection_radius: float = 500.0
@export var lunge_telegraph_time: float = 0.6
@export var lunge_speed: float = 380.0
@export var lunge_duration: float = 0.3
@export var lunge_cooldown: float = 1.8
@export var body_radius: float = 50.0
@export var total_weak_point_hits: int = 6
@export var projectile_speed: float = 380.0
@export var body_color: Color = Color(0.55, 0.1, 0.15)

enum State { CHASE, TELEGRAPH, LUNGE, COOLDOWN }
var _state: State = State.CHASE
var _timer: float = 0.0
var _shoot_timer: float = 0.0
var _lunge_dir: Vector2 = Vector2.ZERO
var _player_ref: Player = null
var _body_visual: Polygon2D
var _weak_point: BossWeakPoint
var _defeated: bool = false
var _phase: int = 1
var _hits_taken: int = 0


func _ready() -> void:
	add_to_group("obstacles")
	add_to_group("bosses")
	GameManager.discover_enemy("EndBoss")  # FR-118
	_build_visual()


func _physics_process(delta: float) -> void:
	if _defeated:
		return
	_find_player()
	if _player_ref == null or not is_instance_valid(_player_ref):
		return

	var difficulty := GameManager.get_difficulty_multiplier()
	var phase_speed_mult := 1.0 + (_phase - 1) * 0.35  # Phase 2 = 1.35x, Phase 3 = 1.7x

	# Phase 2+: gelegentlich Projektile abfeuern
	if _phase >= 2:
		_shoot_timer -= delta
		if _shoot_timer <= 0.0:
			_shoot_timer = 1.8 / phase_speed_mult
			_fire_projectile()

	match _state:
		State.CHASE:
			var to_player := _player_ref.global_position - global_position
			if to_player.length() < detection_radius:
				var dir := to_player.normalized()
				position += dir * chase_speed * difficulty * phase_speed_mult * delta
				rotation = lerp_angle(rotation, dir.angle(), 0.08)
				if to_player.length() < detection_radius * 0.6:
					_state = State.TELEGRAPH
					_timer = lunge_telegraph_time / phase_speed_mult
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
			position += _lunge_dir * lunge_speed * difficulty * phase_speed_mult * delta
			_timer -= delta
			if _timer <= 0.0:
				_state = State.COOLDOWN
				_timer = lunge_cooldown / phase_speed_mult
				_body_visual.modulate = Color.WHITE
		State.COOLDOWN:
			_timer -= delta
			if _timer <= 0.0:
				_state = State.CHASE


func _fire_projectile() -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	var dir := (_player_ref.global_position - global_position).normalized()
	var projectile := Projectile.new()
	projectile.direction = dir
	projectile.speed = projectile_speed
	projectile.global_position = global_position
	get_parent().add_child(projectile)
	GameManager.vibrate(15)


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


## FR-119: Wird bei jedem Schwachstellen-Treffer aufgerufen.
func _on_weak_point_hit(remaining: int) -> void:
	_hits_taken += 1
	var hits_per_phase := int(ceil(float(total_weak_point_hits) / 3.0))
	var new_phase := mini(3, 1 + _hits_taken / maxi(1, hits_per_phase))
	if new_phase != _phase:
		_phase = new_phase
		phase_changed.emit(_phase)
		GameManager.vibrate(70)
		# Rage-Farbwechsel je Phase
		match _phase:
			2: body_color = Color(0.7, 0.15, 0.1)
			3: body_color = Color(0.9, 0.1, 0.05)
		if FloatingText:
			FloatingText.spawn(get_parent(), global_position, "Phase %d!" % _phase, Color(1.0, 0.3, 0.2))


func _on_weak_point_defeated() -> void:
	_defeated = true
	remove_from_group("obstacles")
	GameManager.vibrate(150)
	var reward := GameManager.grant_enemy_defeat_reward(150)
	GameManager.add_xp(150)
	if FloatingText:
		FloatingText.spawn(get_parent(), global_position, "End-Boss besiegt!", Color(1.0, 0.85, 0.2))

	boss_defeated.emit()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.4)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
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
	for i in range(14):
		var a := TAU * float(i) / 14.0
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

	_weak_point = BossWeakPoint.new()
	_weak_point.hits_required = total_weak_point_hits
	_weak_point.radius = body_radius * 0.35
	_weak_point.hit_taken.connect(_on_weak_point_hit)
	_weak_point.defeated.connect(_on_weak_point_defeated)
	add_child(_weak_point)
