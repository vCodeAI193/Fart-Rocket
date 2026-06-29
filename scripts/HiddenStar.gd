extends Area2D
class_name HiddenStar
## HiddenStar – Versteckte Sterne (FR-088)
## =======================================
## Ein verstecktes Stern-Sammelobjekt, das der Spieler
## sammeln kann. Zählt zu speziellen Bonus-Punkten.

@export var size: float = 14.0
@export var star_color: Color = Color(1.0, 0.9, 0.2)
@export var pulse_speed: float = 3.0

var _collected: bool = false
var _float_offset: float = 0.0


func _ready() -> void:
	add_to_group("stars")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _process(delta: float) -> void:
	if not _collected:
		_float_offset += delta * pulse_speed
		position.y += sin(_float_offset) * 0.3 * delta
		rotation += delta * 1.5


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body is Player:
		_collected = true
		_on_collected()
		GameManager.vibrate(50)


func _on_collected() -> void:
	GameManager.add_coin(50)  # 50 Münzen für versteckten Stern
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	queue_free()


func _build_visual() -> void:
	# 5-zackiger Stern
	var star := Line2D.new()
	var points := []
	for i in range(10):
		var angle := TAU * float(i) / 10.0 - PI * 0.5
		var r := size if i % 2 == 0 else size * 0.4
		points.append(Vector2(cos(angle), sin(angle)) * r)
	points.append(points[0])
	star.points = points
	star.width = 2.0
	star.default_color = star_color
	add_child(star)

	# Innerer Glanz
	var inner := Line2D.new()
	var i_points := []
	for i in range(5):
		var angle := TAU * float(i) / 5.0 - PI * 0.5
		i_points.append(Vector2(cos(angle), sin(angle)) * size * 0.3)
	i_points.append(i_points[0])
	inner.points = i_points
	inner.width = 1.5
	inner.default_color = Color(1.0, 1.0, 0.8, 0.7)
	add_child(inner)

	# Outer Glow
	var glow := Line2D.new()
	var g_points := []
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		g_points.append(Vector2(cos(angle), sin(angle)) * (size + 5.0))
	g_points.append(g_points[0])
	glow.points = g_points
	glow.width = 1.0
	glow.default_color = Color(1.0, 0.9, 0.2, 0.3)
	add_child(glow)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size + 2.0
	cshape.shape = circle
	add_child(cshape)
