extends Area2D
class_name SpiderWeb
## SpiderWeb – Klebrige Spinnweben (FR-077)
## ============================================
## Ein Spinnennetz, das den Spieler festhält. Je nach Konfiguration
## kann es entweder nur verzögern (Standard) oder nach zu langem
## Verweilen tödlich sein (is_lethal = true, nach `lethal_delay`).

@export var web_size: Vector2 = Vector2(90, 90)
@export var slow_factor: float = 0.08  # Bewegungs-Multiplikator im Netz
@export var is_lethal: bool = false
@export var lethal_delay: float = 2.0
@export var color: Color = Color(0.85, 0.85, 0.8, 0.5)

var _stuck_time: float = 0.0
var _player_stuck: Player = null
var _original_damp: float = 0.0


func _ready() -> void:
	add_to_group("hazards")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visual()


func _process(delta: float) -> void:
	if _player_stuck != null and is_instance_valid(_player_stuck):
		_stuck_time += delta
		if is_lethal and _stuck_time >= lethal_delay:
			_player_stuck._on_body_entered(self)
	else:
		_stuck_time = 0.0


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return
	_player_stuck = player
	_original_damp = player.linear_damp
	player.linear_damp = 1.0 / maxf(slow_factor, 0.01)
	GameManager.vibrate(15)


func _on_body_exited(body: Node2D) -> void:
	var player := body as Player
	if player == null or player != _player_stuck:
		return
	player.linear_damp = _original_damp
	_player_stuck = null
	_stuck_time = 0.0


func _build_visual() -> void:
	if is_lethal:
		add_to_group("obstacles")  # damit _on_body_entered(self) korrekt greift

	# Radiale Netz-Linien
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var line := Line2D.new()
		line.points = [Vector2.ZERO, Vector2(cos(angle), sin(angle)) * web_size.x * 0.5]
		line.width = 1.5
		line.default_color = color
		add_child(line)

	# Konzentrische Ringe
	for ring in range(1, 4):
		var ring_line := Line2D.new()
		var pts := PackedVector2Array()
		var r := web_size.x * 0.5 * (float(ring) / 3.0)
		for i in range(17):
			var a := TAU * float(i) / 16.0
			pts.append(Vector2(cos(a), sin(a)) * r)
		ring_line.points = pts
		ring_line.width = 1.2
		ring_line.default_color = color
		add_child(ring_line)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = web_size.x * 0.5
	cshape.shape = circle
	add_child(cshape)
