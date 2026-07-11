extends StaticBody2D
class_name StaticTurret
## StaticTurret – Stationärer Geschützturm mit Sweep-Laser (FR-104)
## =====================================================================
## Anders als ShooterEnemy (FR-103, feuert Projektile) rotiert dieser
## Turm kontinuierlich und schwenkt einen tödlichen Laserstrahl.

@export var sweep_speed: float = 1.2  # Umdrehungen pro Sekunde
@export var beam_length: float = 280.0
@export var beam_width: float = 6.0
@export var size: float = 20.0
@export var color: Color = Color(0.5, 0.15, 0.55)

var _beam: Line2D
var _beam_area: Area2D


func _ready() -> void:
	add_to_group("obstacles")
	GameManager.discover_enemy("StaticTurret")  # FR-118: Bestiarium
	_build_visual()


func _process(delta: float) -> void:
	rotation += sweep_speed * TAU * delta


func _on_beam_body_entered(body: Node) -> void:
	if body is Player:
		body._on_body_entered(self)


func _build_visual() -> void:
	var base := Polygon2D.new()
	base.color = color
	var pts := PackedVector2Array()
	for i in range(10):
		var a := TAU * float(i) / 10.0
		pts.append(Vector2(cos(a), sin(a)) * size)
	base.polygon = pts
	add_child(base)

	_beam = Line2D.new()
	_beam.points = [Vector2.ZERO, Vector2(beam_length, 0)]
	_beam.width = beam_width
	_beam.default_color = Color(1.0, 0.3, 0.9, 0.75)
	add_child(_beam)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size
	cshape.shape = circle
	add_child(cshape)

	_beam_area = Area2D.new()
	_beam_area.body_entered.connect(_on_beam_body_entered)
	var beam_shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(beam_length, beam_width)
	beam_shape.position = Vector2(beam_length * 0.5, 0)
	beam_shape.shape = rect_shape
	_beam_area.add_child(beam_shape)
	add_child(_beam_area)
