extends CharacterBody2D
class_name DodgingEnemy
## DodgingEnemy – Ausweichender Gegner (FR-106)
## ================================================
## Ein Gegner, der bei Annäherung des Spielers seitlich
## ausweicht, um einem Zusammenstoß zu entgehen — wird dadurch
## schwerer zu treffen bzw. zu umfliegen.

@export var dodge_radius: float = 180.0
@export var dodge_speed: float = 320.0
@export var dodge_cooldown: float = 0.8
@export var size: float = 15.0
@export var color: Color = Color(0.2, 0.7, 0.75)

var _player_ref: Player = null
var _dodge_timer: float = 0.0
var _dodge_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("obstacles")
	GameManager.discover_enemy("DodgingEnemy")  # FR-118: Bestiarium
	_build_visual()


func _physics_process(delta: float) -> void:
	_find_player()
	_dodge_timer = maxf(0.0, _dodge_timer - delta)

	if _player_ref != null and is_instance_valid(_player_ref):
		var to_player := _player_ref.global_position - global_position
		if to_player.length() < dodge_radius and _dodge_timer <= 0.0:
			# Seitlich ausweichen (senkrecht zur Annäherungsrichtung)
			var perp := Vector2(-to_player.y, to_player.x).normalized()
			if randf() < 0.5:
				perp = -perp
			_dodge_velocity = perp * dodge_speed
			_dodge_timer = dodge_cooldown

	if _dodge_velocity.length() > 1.0:
		position += _dodge_velocity * delta
		_dodge_velocity = _dodge_velocity.lerp(Vector2.ZERO, delta * 3.0)


func _find_player() -> void:
	if _player_ref != null and is_instance_valid(_player_ref):
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0]


func _build_visual() -> void:
	var body := Polygon2D.new()
	body.color = color
	var pts := PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		pts.append(Vector2(cos(a), sin(a) * 0.8) * size)
	body.polygon = pts
	add_child(body)

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


func _on_body_entered(body: Node) -> void:
	if body is Player:
		body._on_body_entered(self)
