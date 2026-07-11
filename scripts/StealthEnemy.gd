extends CharacterBody2D
class_name StealthEnemy
## StealthEnemy – Tarn-Gegner, sichtbar bei Nähe (FR-116)
## ===========================================================
## Ein Gegner, der fast unsichtbar ist, bis sich der Spieler
## nähert — dann wird er zunehmend sichtbar (und gefährlich).

@export var reveal_radius: float = 180.0
@export var hidden_alpha: float = 0.05
@export var size: float = 17.0
@export var color: Color = Color(0.3, 0.55, 0.3)

var _player_ref: Player = null
var _visual: Polygon2D


func _ready() -> void:
	add_to_group("obstacles")
	GameManager.discover_enemy("StealthEnemy")  # FR-118: Bestiarium
	_build_visual()


func _process(delta: float) -> void:
	_find_player()
	var target_alpha := hidden_alpha
	if _player_ref != null and is_instance_valid(_player_ref):
		var dist := global_position.distance_to(_player_ref.global_position)
		if dist < reveal_radius:
			target_alpha = lerpf(1.0, hidden_alpha, dist / reveal_radius)
	_visual.modulate.a = lerpf(_visual.modulate.a, target_alpha, delta * 5.0)


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
	_visual = Polygon2D.new()
	_visual.color = color
	_visual.modulate.a = hidden_alpha
	var pts := PackedVector2Array()
	for i in range(9):
		var a := TAU * float(i) / 9.0
		pts.append(Vector2(cos(a), sin(a)) * size)
	_visual.polygon = pts
	add_child(_visual)

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
