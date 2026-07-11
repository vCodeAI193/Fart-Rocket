extends Area2D
class_name PoisonGasZone
## PoisonGasZone – Zeitbegrenzte Giftgaswolke als Level-Hindernis (FR-072)
## ==========================================================================
## Im Gegensatz zu GasCloud (FR-017, nach Furz erzeugt) ist dies eine
## fest im Level platzierte Zone, die zyklisch erscheint und verschwindet
## und bei Kontakt tödlich ist.

@export var zone_size: Vector2 = Vector2(180, 140)
@export var visible_time: float = 2.5
@export var hidden_time: float = 1.5
@export var warning_time: float = 0.5
@export var color: Color = Color(0.4, 0.75, 0.15, 0.65)

var _is_visible_phase: bool = true
var _timer: float = 0.0
var _cloud_visual: Polygon2D
var _cshape: CollisionShape2D


func _ready() -> void:
	add_to_group("obstacles")
	body_entered.connect(_on_body_entered)
	_timer = visible_time
	_build_visual()


func _process(delta: float) -> void:
	_timer -= delta

	if _cloud_visual != null:
		var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.003) * 0.05
		_cloud_visual.scale = Vector2(pulse, pulse)

	if not _is_visible_phase and _timer <= warning_time and _timer > 0.0:
		_cloud_visual.modulate.a = 0.2 + sin(Time.get_ticks_msec() * 0.02) * 0.15
		_cloud_visual.visible = true

	if _timer <= 0.0:
		_is_visible_phase = not _is_visible_phase
		_timer = visible_time if _is_visible_phase else hidden_time
		_update_state()


func _update_state() -> void:
	_cloud_visual.visible = _is_visible_phase
	_cloud_visual.modulate.a = 1.0
	_cshape.disabled = not _is_visible_phase


func _on_body_entered(body: Node) -> void:
	if body is Player and _is_visible_phase:
		body._on_body_entered(self)


func _build_visual() -> void:
	_cloud_visual = Polygon2D.new()
	_cloud_visual.color = color
	var pts := PackedVector2Array()
	var segs := 16
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(segs):
		var a := TAU * float(i) / float(segs)
		var rx := zone_size.x * 0.5 * rng.randf_range(0.8, 1.1)
		var ry := zone_size.y * 0.5 * rng.randf_range(0.8, 1.1)
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	_cloud_visual.polygon = pts
	add_child(_cloud_visual)

	# Schädel-Symbol als Warnhinweis
	var label := Label.new()
	label.text = "☠"
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.2, 0.4, 0.1, 0.9))
	label.position = Vector2(-14, -18)
	_cloud_visual.add_child(label)

	_cshape = CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = zone_size
	_cshape.shape = rect_shape
	add_child(_cshape)
