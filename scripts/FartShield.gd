extends Area2D
## FartShield – Schild-Power-up
## =============================
## FR-084: Ein rotierendes blaues Oktagon. Beim Berühren erhält der Spieler
## für `shield_duration` Sekunden Unverwundbarkeit (ein Treffer wird absorbiert).

@export var shield_duration: float = 5.0
@export var spin_speed: float = 1.8

var _collected: bool = false


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _process(delta: float) -> void:
	if not _collected:
		rotation += spin_speed * delta


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body is Player:
		_collected = true
		body.activate_shield(shield_duration)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(2.2, 2.2), 0.3)
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		await tween.finished
		queue_free()


func _build_visual() -> void:
	# Oktagon (blau)
	var oct := Polygon2D.new()
	oct.color = Color(0.25, 0.55, 1.0, 0.9)
	var pts := PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		pts.append(Vector2(cos(a), sin(a)) * 24.0)
	oct.polygon = pts
	add_child(oct)
	# Innenleuchten
	var glow := Polygon2D.new()
	glow.color = Color(0.65, 0.85, 1.0, 0.65)
	var gpts := PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		gpts.append(Vector2(cos(a), sin(a)) * 14.0)
	glow.polygon = gpts
	add_child(glow)
	# Schild-Symbol (kleines "S")
	var lbl := Label.new()
	lbl.text = "S"
	lbl.position = Vector2(-9, -14)
	lbl.add_theme_font_size_override("font_size", 22)
	add_child(lbl)
