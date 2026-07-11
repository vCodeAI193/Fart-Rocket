extends Area2D
class_name Projectile
## Projectile – Gegner-Projektil (Teil von FR-103)
## ================================================
## Ein einfaches Projektil, das sich in eine Richtung bewegt
## und bei Treffer den Spieler tötet.

@export var speed: float = 400.0
@export var direction: Vector2 = Vector2.RIGHT
@export var lifetime: float = 4.0
@export var size: float = 8.0
@export var color: Color = Color(1.0, 0.3, 0.2)

var _elapsed: float = 0.0


func _ready() -> void:
	add_to_group("obstacles")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_elapsed += delta
	if _elapsed > lifetime:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		queue_free()  # Projektil verschwindet nach Treffer (Player._on_body_entered übernimmt Tod)


func _build_visual() -> void:
	var core := Polygon2D.new()
	core.color = color
	var pts := PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		pts.append(Vector2(cos(a), sin(a)) * size)
	core.polygon = pts
	add_child(core)

	# Trail-Effekt
	var trail := Line2D.new()
	trail.points = [Vector2.ZERO, -direction * 20.0]
	trail.width = 3.0
	trail.default_color = Color(color.r, color.g, color.b, 0.4)
	add_child(trail)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size
	cshape.shape = circle
	add_child(cshape)
