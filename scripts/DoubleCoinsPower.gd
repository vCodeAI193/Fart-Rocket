extends Area2D
## DoubleCoinsPower – Doppel-Münzen-Power-up
## ===========================================
## FR-086: Aktiviert für `duration` Sekunden den Doppel-Münzen-Modus.
## Alle Münzen zählen in dieser Zeit doppelt.

@export var duration: float = 8.0
@export var spin_speed: float = 2.2

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
		GameManager.activate_double_coins(duration)
		GameManager.vibrate(40)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(2.2, 2.2), 0.25)
		tween.tween_property(self, "modulate:a", 0.0, 0.25)
		await tween.finished
		queue_free()


func _build_visual() -> void:
	# Zwei ineinander geschachtelte Münzen (gelb/gold)
	for j in range(2):
		var off := Vector2(-5.0 + j * 10.0, -4.0 + j * 8.0)
		var coin := Polygon2D.new()
		coin.color = Color(1.0, 0.82 - j * 0.12, 0.1 + j * 0.1)
		var pts := PackedVector2Array()
		for i in range(12):
			var a := TAU * float(i) / 12.0
			pts.append(off + Vector2(cos(a), sin(a)) * (18.0 - j * 4.0))
		coin.polygon = pts
		add_child(coin)
	# "x2"-Beschriftung
	var lbl := Label.new()
	lbl.text = "x2"
	lbl.position = Vector2(-12, -12)
	lbl.add_theme_font_size_override("font_size", 18)
	add_child(lbl)
