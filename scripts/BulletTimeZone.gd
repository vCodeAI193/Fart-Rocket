extends Area2D
class_name BulletTimeZone
## BulletTimeZone – Zeitlupen-Zone
## =================================
## FR-036: Reduziert Engine.time_scale wenn der Spieler drin ist.

@export var slow_scale: float = 0.4
@export var zone_size: Vector2 = Vector2(200, 300)
@export var zone_color: Color = Color(0.6, 0.2, 0.8, 0.15)

var _players_inside: int = 0
var _normal_scale: float = 1.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visual()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		_players_inside += 1
		if _players_inside == 1:
			_normal_scale = Engine.time_scale
			Engine.time_scale = slow_scale


func _on_body_exited(body: Node) -> void:
	if body is Player:
		_players_inside = maxi(0, _players_inside - 1)
		if _players_inside == 0:
			Engine.time_scale = _normal_scale


func _build_visual() -> void:
	var cshape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = zone_size
	cshape.shape = rect
	add_child(cshape)
	var poly := Polygon2D.new()
	poly.color = zone_color
	var hw := zone_size.x * 0.5
	var hh := zone_size.y * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh),
	])
	add_child(poly)
	var lbl := Label.new()
	lbl.text = "ZEITLUPE"
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.5, 1.0, 0.9))
	lbl.position = Vector2(-52, -14)
	add_child(lbl)
