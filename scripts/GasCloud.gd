extends Area2D
class_name GasCloud
## GasCloud – Verweilende Geruchswolke
## =====================================
## FR-017: Entsteht nach einem Furz und schadet Spielern, die sie berühren.
## Verblasst und verschwindet nach `lifetime` Sekunden.

@export var lifetime: float = 3.5
@export var damage_radius: float = 50.0

var _age: float = 0.0
var _visual: Polygon2D


func _ready() -> void:
	add_to_group("hazards")
	body_entered.connect(_on_body_entered)
	_build_visual()
	# Kollision aufbauen
	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = damage_radius
	cshape.shape = circle
	add_child(cshape)


func _process(delta: float) -> void:
	_age += delta
	var frac := _age / lifetime
	# Langsam ausblenden
	modulate.a = lerpf(0.75, 0.0, frac)
	# Leicht pulsieren
	var scale_v := 1.0 + sin(_age * 3.0) * 0.08
	scale = Vector2(scale_v, scale_v)
	if _age >= lifetime:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		# Schadet dem Spieler nur einmal beim Eintreten (kein instant-kill, nur Schub)
		(body as Player).apply_central_impulse(Vector2(0, -200))
		GameManager.vibrate(30)


func _build_visual() -> void:
	_visual = Polygon2D.new()
	_visual.color = Color(0.5, 0.85, 0.2, 0.6)
	var pts := PackedVector2Array()
	var segs := 20
	for i in range(segs):
		var a := TAU * float(i) / float(segs)
		var r := damage_radius * (0.8 + randf() * 0.4)
		pts.append(Vector2(cos(a), sin(a)) * r)
	_visual.polygon = pts
	add_child(_visual)


## Erzeugt eine GasCloud an einer Weltposition (Fabrik-Methode).
static func spawn(parent: Node, world_pos: Vector2) -> void:
	var cloud := GasCloud.new()
	parent.add_child(cloud)
	cloud.global_position = world_pos
