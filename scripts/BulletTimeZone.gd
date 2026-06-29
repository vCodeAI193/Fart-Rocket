extends Area2D
class_name BulletTimeZone
## BulletTimeZone – Zeitlupen-Zone (FR-036)
## ==========================================
## Eine Zone, die Zeit verlangsamt, wenn der Spieler hineingeht.
## Nutzt Engine.time_scale, was das gesamte Spiel betrifft.

@export var time_scale: float = 0.3
@export var color: Color = Color(0.5, 0.5, 1.0, 0.3)
@export var zone_size: Vector2 = Vector2(300, 200)

var _original_time_scale: float = 1.0
var _players_in_zone: int = 0


func _ready() -> void:
	add_to_group("hazards")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_build_visual()


func _build_visual() -> void:
	var rect := ColorRect.new()
	rect.size = zone_size
	rect.position = -zone_size * 0.5
	rect.color = color
	add_child(rect)

	var border := Line2D.new()
	var points := [
		Vector2(-zone_size.x * 0.5, -zone_size.y * 0.5),
		Vector2(zone_size.x * 0.5, -zone_size.y * 0.5),
		Vector2(zone_size.x * 0.5, zone_size.y * 0.5),
		Vector2(-zone_size.x * 0.5, zone_size.y * 0.5),
		Vector2(-zone_size.x * 0.5, -zone_size.y * 0.5),
	]
	border.points = points
	border.width = 3.0
	border.default_color = Color(0.3, 0.3, 0.8, 0.8)
	add_child(border)

	var center_circle := ColorRect.new()
	center_circle.size = Vector2(20, 20)
	center_circle.position = -Vector2(10, 10)
	center_circle.color = Color(0.3, 0.3, 0.8)
	add_child(center_circle)

	var hand1 := Line2D.new()
	hand1.points = [Vector2(0, 0), Vector2(20, 0)]
	hand1.width = 2.0
	hand1.default_color = Color(0.7, 0.7, 1.0)
	add_child(hand1)

	var hand2 := Line2D.new()
	hand2.points = [Vector2(0, 0), Vector2(0, 20)]
	hand2.width = 2.0
	hand2.default_color = Color(0.7, 0.7, 1.0)
	add_child(hand2)

	var label := Label.new()
	label.text = "ZEITLUPE"
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.8, 0.8))
	label.position = Vector2(-zone_size.x * 0.5 + 10, zone_size.y * 0.5 - 40)
	add_child(label)

	var cshape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = zone_size
	cshape.shape = rect_shape
	add_child(cshape)


func _on_area_entered(area: Area2D) -> void:
	if area is Player or area.owner is Player:
		if _players_in_zone == 0:
			_original_time_scale = Engine.time_scale
			Engine.time_scale = time_scale
		_players_in_zone += 1


func _on_area_exited(area: Area2D) -> void:
	if area is Player or area.owner is Player:
		_players_in_zone -= 1
		if _players_in_zone <= 0:
			_players_in_zone = 0
			Engine.time_scale = _original_time_scale
