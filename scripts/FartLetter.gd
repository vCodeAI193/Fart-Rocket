extends Area2D
class_name FartLetter
## FartLetter – Sammel-Buchstabe für F-A-R-T Bonus (FR-092)
## ==========================================================
## Sammle alle 4 Buchstaben F-A-R-T im Level für einen Bonus.

@export var letter: String = "F"
@export var size: float = 20.0
@export var letter_color: Color = Color(1.0, 0.6, 0.1)

var _collected: bool = false


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _process(delta: float) -> void:
	if not _collected:
		position.y += sin(Time.get_ticks_msec() * 0.003) * 0.3
		rotation = sin(Time.get_ticks_msec() * 0.002) * 0.15


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body is Player:
		_collected = true
		GameManager.collect_fart_letter(letter)
		GameManager.vibrate(40)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.25)
		tween.tween_property(self, "modulate:a", 0.0, 0.25)
		await tween.finished
		queue_free()


func _build_visual() -> void:
	# Hintergrund-Kreis
	var bg := Polygon2D.new()
	bg.color = letter_color
	var pts := PackedVector2Array()
	for i in range(16):
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a), sin(a)) * size)
	bg.polygon = pts
	add_child(bg)

	# Buchstabe
	var label := Label.new()
	label.text = letter
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(-10, -18)
	add_child(label)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size + 2.0
	cshape.shape = circle
	add_child(cshape)
