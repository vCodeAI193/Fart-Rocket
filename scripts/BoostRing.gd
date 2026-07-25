extends Area2D
class_name BoostRing
## BoostRing – Furz-Boost-Ring
## ============================
## FR-019: Durchfliegen laedt sofort eine Ladung nach und gibt einen kleinen Schub.

@export var boost_speed: float = 350.0   # zusaetzliche Geschwindigkeit (px/s)
@export var ring_radius: float = 45.0

var _triggered: bool = false


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _process(delta: float) -> void:
	if not _triggered:
		rotation += 1.2 * delta


func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	var player := body as Player
	if player != null:
		_triggered = true
		# Ladung nachladen
		GameManager.add_charge()
		GameManager.vibrate(25)
		# Schub in Flugrichtung
		var vel: Vector2 = player.linear_velocity
		if vel.length() > 10.0:
			player.apply_central_impulse(vel.normalized() * boost_speed * player.mass)
		# Aufleuchten und verschwinden
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.2)
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		await tween.finished
		queue_free()


func _build_visual() -> void:
	# Aeusserer Ring (gelb-gold)
	var outer := Polygon2D.new()
	outer.color = Color(1.0, 0.88, 0.1, 0.9)
	var pts_o := PackedVector2Array()
	var pts_i := PackedVector2Array()
	var segs := 32
	for i in range(segs):
		var a := TAU * float(i) / float(segs)
		pts_o.append(Vector2(cos(a), sin(a)) * ring_radius)
		pts_i.append(Vector2(cos(a), sin(a)) * (ring_radius - 10.0))
	outer.polygon = pts_o
	add_child(outer)
	var inner_bg := Polygon2D.new()
	inner_bg.color = Color(1.0, 0.7, 0.0, 0.25)
	inner_bg.polygon = pts_i
	add_child(inner_bg)
	# Pfeil-Symbol in der Mitte
	var arrow := Line2D.new()
	arrow.width = 5.0
	arrow.default_color = Color(1.0, 0.95, 0.4)
	arrow.add_point(Vector2(-16, 0))
	arrow.add_point(Vector2(16, 0))
	arrow.add_point(Vector2(6, -10))
	arrow.add_point(Vector2(16, 0))
	arrow.add_point(Vector2(6, 10))
	add_child(arrow)
	# Kollision
	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = ring_radius
	cshape.shape = circle
	add_child(cshape)
