extends CharacterBody2D
class_name BlowableEnemy
## BlowableEnemy – Gegner, der vom Furz weggeblasen wird (FR-115)
## ===================================================================
## Ein leichter, schwebender Gegner, der beim nahen Furz-Stoß des
## Spielers weggeschleudert wird (statt tödlich zu bleiben). Ruhig
## danach kehrt er langsam wieder zur Ausgangsposition zurück.

@export var size: float = 15.0
@export var color: Color = Color(0.9, 0.7, 0.2)
@export var return_speed: float = 2.0

var _push_velocity: Vector2 = Vector2.ZERO
var _home_position: Vector2


func _ready() -> void:
	add_to_group("obstacles")
	GameManager.discover_enemy("BlowableEnemy")  # FR-118: Bestiarium
	add_to_group("blowable")
	_home_position = global_position
	_build_visual()


func _physics_process(delta: float) -> void:
	if _push_velocity.length() > 5.0:
		position += _push_velocity * delta
		_push_velocity = _push_velocity.lerp(Vector2.ZERO, delta * 3.0)
	else:
		# Sanft zur Ausgangsposition zurückschweben
		position = position.lerp(_home_position, delta * return_speed)


## Wird vom Player beim Furz-Stoß aufgerufen (FR-115).
func apply_fart_push(force: Vector2) -> void:
	_push_velocity += force * 0.4
	GameManager.vibrate(15)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		body._on_body_entered(self)


func _build_visual() -> void:
	var body := Polygon2D.new()
	body.color = color
	var pts := PackedVector2Array()
	for i in range(10):
		var a := TAU * float(i) / 10.0
		pts.append(Vector2(cos(a), sin(a)) * size)
	body.polygon = pts
	add_child(body)

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
