extends CharacterBody2D
class_name CoinThiefEnemy
## CoinThiefEnemy – Gegner, der Münzen klaut (FR-105)
## =====================================================
## Ein Gegner, der bei Kontakt Münzen vom Spieler stiehlt,
## anstatt ihn zu töten. Fliegt anschließend eilig davon.

@export var steal_amount: int = 15
@export var flee_speed: float = 350.0
@export var patrol_speed: float = 80.0
@export var patrol_distance: float = 200.0
@export var size: float = 16.0
@export var color: Color = Color(0.7, 0.55, 0.15)

var _start_pos: Vector2
var _direction: float = 1.0
var _fleeing: bool = false
var _flee_direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("thieves")
	GameManager.discover_enemy("CoinThiefEnemy")  # FR-118: Bestiarium
	_start_pos = global_position
	_build_visual()


func _physics_process(delta: float) -> void:
	if _fleeing:
		position += _flee_direction * flee_speed * delta
		modulate.a = maxf(0.0, modulate.a - delta * 0.5)
		if modulate.a <= 0.0:
			queue_free()
		return

	position += Vector2.RIGHT * _direction * patrol_speed * delta
	var dist := (global_position - _start_pos).x
	if dist > patrol_distance:
		_direction = -1.0
	elif dist < -patrol_distance:
		_direction = 1.0

	rotation = sin(Time.get_ticks_msec() * 0.005) * 0.1


func _on_body_entered(body: Node) -> void:
	if _fleeing or not (body is Player):
		return

	if GameManager.total_coins > 0:
		var stolen := mini(steal_amount, GameManager.total_coins)
		GameManager.total_coins -= stolen
		GameManager.coins_changed.emit(GameManager.total_coins)
		GameManager.vibrate(30)

		if FloatingText:
			FloatingText.spawn(get_parent(), global_position, "-%d!" % stolen, Color(1.0, 0.3, 0.2))

	_fleeing = true
	_flee_direction = (global_position - body.global_position).normalized()


func _build_visual() -> void:
	var body := Polygon2D.new()
	body.color = color
	var pts := PackedVector2Array()
	for i in range(10):
		var a := TAU * float(i) / 10.0
		pts.append(Vector2(cos(a), sin(a) * 0.9) * size)
	body.polygon = pts
	add_child(body)

	# Maske/Augen (Dieb-Look)
	var mask := ColorRect.new()
	mask.size = Vector2(size * 1.2, size * 0.4)
	mask.position = Vector2(-size * 0.6, -size * 0.3)
	mask.color = Color(0.15, 0.1, 0.05)
	add_child(mask)

	for side in [-1, 1]:
		var eye := Polygon2D.new()
		eye.color = Color(1.0, 1.0, 1.0)
		var epts := PackedVector2Array()
		for i in range(6):
			var a := TAU * float(i) / 6.0
			epts.append(Vector2(cos(a), sin(a)) * 2.5)
		eye.polygon = epts
		eye.position = Vector2(side * size * 0.35, -size * 0.1)
		add_child(eye)

	# Beutel-Symbol
	var bag := Polygon2D.new()
	bag.color = Color(0.5, 0.3, 0.1)
	bag.polygon = PackedVector2Array([
		Vector2(-4, size * 0.3), Vector2(4, size * 0.3),
		Vector2(6, size * 0.6), Vector2(-6, size * 0.6),
	])
	add_child(bag)

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
