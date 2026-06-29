extends Area2D
class_name StickyZone
## StickyZone – Schleim-/Klebebereich
## =====================================
## FR-028: Verlangsamt den Spieler stark beim Durchfliegen.

@export var drag_factor: float = 12.0       # Dämpfungsfaktor (hoch = dickflüssig)
@export var zone_size: Vector2 = Vector2(200, 250)
@export var zone_color: Color = Color(0.2, 0.8, 0.3, 0.2)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visual()


var _bodies: Array[RigidBody2D] = []
var _saved_damping: Dictionary = {}


func _on_body_entered(body: Node) -> void:
	if body is RigidBody2D:
		var rb := body as RigidBody2D
		_saved_damping[rb.get_instance_id()] = rb.linear_damp
		rb.linear_damp = drag_factor
		_bodies.append(rb)


func _on_body_exited(body: Node) -> void:
	if body is RigidBody2D:
		var rb := body as RigidBody2D
		var id := rb.get_instance_id()
		if _saved_damping.has(id):
			rb.linear_damp = _saved_damping[id]
			_saved_damping.erase(id)
		_bodies.erase(rb)


func _build_visual() -> void:
	var cshape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = zone_size
	cshape.shape = rect
	add_child(cshape)
	# Schleim-Rechteck
	var poly := Polygon2D.new()
	poly.color = zone_color
	var hw := zone_size.x * 0.5
	var hh := zone_size.y * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh),
	])
	add_child(poly)
	# Wellige Linien als Schleim-Symbol
	for i in range(4):
		var line := Line2D.new()
		line.width = 3.0
		line.default_color = Color(0.3, 0.9, 0.4, 0.6)
		var y := -hh * 0.5 + hh * float(i) / 3.0 + hh * 0.15
		for j in range(9):
			var x := -hw + (float(j) / 8.0) * zone_size.x
			var wy := y + sin(j * 0.8) * 8.0
			line.add_point(Vector2(x, wy))
		add_child(line)
	var lbl := Label.new()
	lbl.text = "SCHLEIM"
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 0.8))
	lbl.position = Vector2(-40, -14)
	add_child(lbl)
