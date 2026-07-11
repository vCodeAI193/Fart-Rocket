extends CharacterBody2D
class_name ShieldedEnemy
## ShieldedEnemy – Schild-Gegner, nur von hinten verwundbar (FR-109)
## =====================================================================
## Ein Gegner mit einem Schild auf der Vorderseite. Berührt der Spieler
## ihn von vorne, stirbt der Spieler. Trifft der Spieler ihn von hinten
## (mit ausreichend Tempo), wird der Gegner besiegt und verschwindet.

@export var facing_direction: Vector2 = Vector2.RIGHT
@export var defeat_speed_threshold: float = 300.0
@export var size: float = 20.0
@export var shield_color: Color = Color(0.3, 0.5, 0.9)
@export var body_color: Color = Color(0.6, 0.2, 0.2)

var _defeated: bool = false


func _ready() -> void:
	add_to_group("obstacles")
	rotation = facing_direction.angle()
	_build_visual()


func _on_body_entered(body: Node) -> void:
	if _defeated or not (body is Player):
		return

	var player: Player = body
	var to_player := (player.global_position - global_position).normalized()
	var facing_dot := to_player.dot(facing_direction)

	# facing_dot > 0 -> Spieler kommt von vorne (Schildseite) -> Spieler stirbt
	# facing_dot <= 0 -> Spieler kommt von hinten -> ggf. Gegner besiegt
	if facing_dot > 0.2:
		player._on_body_entered(self)
	else:
		if player.linear_velocity.length() >= defeat_speed_threshold:
			_defeat(player)
		else:
			# Zu langsam von hinten getroffen: schiebt Gegner nur weg, kein Kill
			player._on_body_entered(self)


func _defeat(player: Player) -> void:
	_defeated = true
	GameManager.vibrate(50)
	GameManager.add_coin(25)  # kleine Belohnung fürs Besiegen
	if FloatingText:
		FloatingText.spawn(get_parent(), global_position, "Besiegt!", Color(0.4, 1.0, 0.5))

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.4, 0.3), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	queue_free()


func _build_visual() -> void:
	var body := Polygon2D.new()
	body.color = body_color
	var pts := PackedVector2Array()
	for i in range(10):
		var a := TAU * float(i) / 10.0
		pts.append(Vector2(cos(a), sin(a)) * size)
	body.polygon = pts
	add_child(body)

	# Schild auf der Vorderseite (halbmondförmig)
	var shield := Polygon2D.new()
	shield.color = shield_color
	var spts := PackedVector2Array()
	for i in range(9):
		var a := -PI * 0.4 + PI * 0.8 * float(i) / 8.0
		spts.append(Vector2(cos(a), sin(a)) * size * 1.15)
	spts.append(Vector2(size * 0.3, 0))
	shield.polygon = spts
	add_child(shield)

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
