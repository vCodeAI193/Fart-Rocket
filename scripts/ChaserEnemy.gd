extends CharacterBody2D
class_name ChaserEnemy
## ChaserEnemy – Verfolger-Gegner (FR-102)
## ===========================================
## Ein Gegner, der dem Spieler kontinuierlich folgt,
## sobald dieser in Reichweite kommt.

@export var chase_speed: float = 180.0
@export var detection_radius: float = 450.0
@export var size: float = 17.0
@export var color: Color = Color(0.75, 0.15, 0.2)

var _player_ref: Player = null


func _ready() -> void:
	add_to_group("obstacles")
	_build_visual()


func _physics_process(delta: float) -> void:
	_find_player()
	if _player_ref == null or not is_instance_valid(_player_ref):
		return

	var to_player := _player_ref.global_position - global_position
	if to_player.length() < detection_radius:
		var dir := to_player.normalized()
		position += dir * chase_speed * delta
		rotation = lerp_angle(rotation, dir.angle(), 0.1)


func _find_player() -> void:
	if _player_ref != null and is_instance_valid(_player_ref):
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0]


func _build_visual() -> void:
	var body := Polygon2D.new()
	body.color = color
	body.polygon = PackedVector2Array([
		Vector2(size, 0),
		Vector2(-size * 0.6, size * 0.7),
		Vector2(-size * 0.3, 0),
		Vector2(-size * 0.6, -size * 0.7),
	])
	add_child(body)

	var eye := Polygon2D.new()
	eye.color = Color(1.0, 0.9, 0.2)
	var epts := PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		epts.append(Vector2(cos(a), sin(a)) * 3.0)
	eye.polygon = epts
	eye.position = Vector2(size * 0.3, 0)
	add_child(eye)

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
