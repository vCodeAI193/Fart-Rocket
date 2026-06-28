extends Area2D
class_name CoinMagnet
## CoinMagnet – Münz-Magnet-Power-up
## ====================================
## FR-269: Zieht alle Münzen zum Spieler, die er einsammelt.

@export var duration: float = 6.0
@export var pull_force: float = 400.0
@export var magnet_radius: float = 200.0

var _collected: bool = false


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _process(delta: float) -> void:
	if not _collected:
		rotation += 2.5 * delta


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body is Player:
		_collected = true
		_activate_magnet(body)
		GameManager.vibrate(50)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(2.5, 2.5), 0.2)
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		await tween.finished
		queue_free()


func _activate_magnet(player: Player) -> void:
	var start_time := Time.get_ticks_msec() / 1000.0
	var pull_timer := func() -> void:
		var elapsed := Time.get_ticks_msec() / 1000.0 - start_time
		if elapsed > duration:
			return
		for coin in get_tree().get_nodes_in_group("coins"):
			if not coin._collected:
				var dist := coin.global_position.distance_to(player.global_position)
				if dist < magnet_radius and dist > 1.0:
					var dir := (player.global_position - coin.global_position).normalized()
					coin.apply_central_force(dir * pull_force)
	var interval_timer := get_tree().create_timer(duration, false, false, true)
	while elapsed < duration:
		pull_timer.call()
		await get_tree().create_timer(0.05).timeout


func _build_visual() -> void:
	var outer := Polygon2D.new()
	outer.color = Color(1.0, 0.6, 0.2, 0.85)
	var pts := PackedVector2Array()
	for i in range(12):
		var a := TAU * float(i) / 12.0
		pts.append(Vector2(cos(a), sin(a)) * 24.0)
	outer.polygon = pts
	add_child(outer)
	var inner := Polygon2D.new()
	inner.color = Color(1.0, 0.85, 0.3)
	pts = PackedVector2Array()
	for i in range(12):
		var a := TAU * float(i) / 12.0
		pts.append(Vector2(cos(a), sin(a)) * 14.0)
	inner.polygon = pts
	add_child(inner)
	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 26.0
	cshape.shape = circle
	add_child(cshape)
