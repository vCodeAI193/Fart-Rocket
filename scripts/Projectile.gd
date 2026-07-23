extends Area2D
class_name Projectile
## Projectile – Gegner-Projektil (Teil von FR-103)
## ================================================
## Ein einfaches Projektil, das sich in eine Richtung bewegt
## und bei Treffer den Spieler tötet.
##
## FR-461: Pool-fähig — ShooterEnemy.gd/EndBoss.gd können Instanzen über
## activate_for_shot() für den nächsten Schuss wiederverwenden, statt bei
## jedem Schuss neu zu instanziieren/zu entfernen.

@export var speed: float = 400.0
@export var direction: Vector2 = Vector2.RIGHT
@export var lifetime: float = 4.0
@export var size: float = 8.0
@export var color: Color = Color(1.0, 0.3, 0.2)

var is_active: bool = false
var _elapsed: float = 0.0
var _trail: Line2D


func _ready() -> void:
	add_to_group("obstacles")
	body_entered.connect(_on_body_entered)
	_build_visual()
	is_active = true


func _physics_process(delta: float) -> void:
	if not is_active:
		return
	position += direction * speed * delta
	_elapsed += delta
	if _elapsed > lifetime:
		_deactivate()


func _on_body_entered(body: Node) -> void:
	if body is Player and is_active:
		_deactivate()  # Projektil verschwindet nach Treffer (Player._on_body_entered übernimmt Tod)


## FR-461: Setzt eine gepoolte Instanz für einen neuen Schuss zurück
## (Richtung/Position/Sichtbarkeit/Trail), statt eine neue zu instanziieren.
func activate_for_shot(new_direction: Vector2, new_speed: float, new_position: Vector2) -> void:
	direction = new_direction
	speed = new_speed
	global_position = new_position
	_elapsed = 0.0
	is_active = true
	visible = true
	monitoring = true
	monitorable = true
	if _trail != null:
		_trail.points = [Vector2.ZERO, -direction * 20.0]


func _deactivate() -> void:
	is_active = false
	visible = false
	monitoring = false
	monitorable = false


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
	_trail = Line2D.new()
	_trail.points = [Vector2.ZERO, -direction * 20.0]
	_trail.width = 3.0
	_trail.default_color = Color(color.r, color.g, color.b, 0.4)
	add_child(_trail)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size
	cshape.shape = circle
	add_child(cshape)
