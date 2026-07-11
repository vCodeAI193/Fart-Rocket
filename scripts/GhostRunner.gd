extends Node2D
class_name GhostRunner
## GhostRunner – Geister-Rennen (FR-353)
## ========================================
## Spielt eine zuvor aufgezeichnete Positions-Spur (die Bestzeit-Fahrt)
## als halbtransparente Silhouette neben dem eigenen Männchen ab.

const SAMPLE_INTERVAL := 0.05

var _path: PackedVector2Array = PackedVector2Array()
var _index: int = 0
var _timer: float = 0.0


func _ready() -> void:
	modulate = Color(1.0, 1.0, 1.0, 0.35)
	z_index = -1
	_build_visual()


func set_path(path: PackedVector2Array) -> void:
	_path = path
	_index = 0
	_timer = 0.0
	visible = _path.size() > 0
	if _path.size() > 0:
		global_position = _path[0]


func _process(delta: float) -> void:
	if _path.is_empty() or _index >= _path.size() - 1:
		return
	_timer += delta
	while _timer >= SAMPLE_INTERVAL and _index < _path.size() - 1:
		_timer -= SAMPLE_INTERVAL
		_index += 1
	global_position = _path[_index]
	if _index >= _path.size() - 1:
		visible = false


func _build_visual() -> void:
	var body := Polygon2D.new()
	body.color = Color(0.6, 0.8, 1.0, 0.7)
	var pts := PackedVector2Array()
	for i in range(10):
		var a := TAU * float(i) / 10.0
		pts.append(Vector2(cos(a), sin(a)) * 16.0)
	body.polygon = pts
	add_child(body)
	var label := Label.new()
	label.text = "👻"
	label.add_theme_font_size_override("font_size", 20)
	label.position = Vector2(-10, -40)
	add_child(label)
