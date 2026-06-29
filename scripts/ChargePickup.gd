extends Area2D
## ChargePickup – Extra-Furz-Ladung
## ==================================
## FR-087: Ein sechseckiges grünes Pickup. Beim Berühren bekommt der
## Spieler sofort `charges` zusätzliche Furz-Ladungen.

@export var charges: int = 1     # FR-087: Anzahl nachgeladener Ladungen
@export var spin_speed: float = 2.0

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
	if body.is_in_group("player"):
		_collected = true
		for _i in range(charges):
			GameManager.add_charge()
		GameManager.vibrate(35)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(2.2, 2.2), 0.25)
		tween.tween_property(self, "modulate:a", 0.0, 0.25)
		await tween.finished
		queue_free()


func _build_visual() -> void:
	# Sechseck (grün)
	var hex := Polygon2D.new()
	hex.color = Color(0.25, 0.75, 0.25)
	var pts := PackedVector2Array()
	for i in range(6):
		var a := TAU * float(i) / 6.0 - PI / 6.0
		pts.append(Vector2(cos(a), sin(a)) * 22.0)
	hex.polygon = pts
	add_child(hex)
	# Innenkern (hellgrün)
	var inner := Polygon2D.new()
	inner.color = Color(0.55, 1.0, 0.55, 0.7)
	var ipts := PackedVector2Array()
	for i in range(6):
		var a := TAU * float(i) / 6.0 - PI / 6.0
		ipts.append(Vector2(cos(a), sin(a)) * 13.0)
	inner.polygon = ipts
	add_child(inner)
	# "+N"-Beschriftung
	var lbl := Label.new()
	lbl.text = "+%d" % charges
	lbl.position = Vector2(-14, -12)
	lbl.add_theme_font_size_override("font_size", 20)
	add_child(lbl)
