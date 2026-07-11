extends Area2D
class_name IntervalLaser
## IntervalLaser – Laserstrahl mit Intervall-Schaltung (FR-065)
## ================================================================
## Ein Laserstrahl, der periodisch an- und ausgeht.
## Vorwarnung durch schwaches Aufleuchten vor der Aktivierung.

@export var laser_length: float = 300.0
@export var laser_width: float = 8.0
@export var on_time: float = 1.0
@export var off_time: float = 1.2
@export var warning_time: float = 0.4
@export var start_on: bool = false
@export var color: Color = Color(1.0, 0.15, 0.15)

var _is_on: bool = false
var _timer: float = 0.0
var _beam: Line2D
var _cshape: CollisionShape2D


func _ready() -> void:
	add_to_group("obstacles")
	body_entered.connect(_on_body_entered)
	_is_on = start_on
	_timer = on_time if start_on else off_time
	_build_visual()
	_update_state()


func _process(delta: float) -> void:
	_timer -= delta

	if not _is_on and _timer <= warning_time and _timer > 0.0:
		_beam.modulate.a = 0.15 + sin(Time.get_ticks_msec() * 0.04) * 0.15
		_beam.visible = true
	elif not _is_on:
		_beam.visible = false

	if _timer <= 0.0:
		_is_on = not _is_on
		_timer = on_time if _is_on else off_time
		_update_state()
		GameManager.vibrate(15)


func _update_state() -> void:
	_beam.visible = _is_on
	_beam.modulate.a = 1.0
	_cshape.disabled = not _is_on


func _on_body_entered(body: Node) -> void:
	if body is Player and _is_on:
		body._on_body_entered(self)


func _build_visual() -> void:
	_beam = Line2D.new()
	_beam.points = [Vector2.ZERO, Vector2(laser_length, 0)]
	_beam.width = laser_width
	_beam.default_color = color
	add_child(_beam)

	# Emitter-Punkt am Ursprung
	var emitter := Polygon2D.new()
	emitter.color = color.darkened(0.2)
	var pts := PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		pts.append(Vector2(cos(a), sin(a)) * laser_width)
	emitter.polygon = pts
	add_child(emitter)

	_cshape = CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(laser_length, laser_width)
	_cshape.position = Vector2(laser_length * 0.5, 0)
	_cshape.shape = rect_shape
	add_child(_cshape)
