extends Area2D
class_name StickerCard
## StickerCard – Sammelkarte fürs Sticker-System (FR-089)
## =============================================================
## Ein Pickup, das beim Einsammeln eine zufällige, noch nicht
## besessene Sticker-Karte freischaltet (siehe GameManager.STICKER_SET).

var _collected: bool = false


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _process(delta: float) -> void:
	if not _collected:
		rotation = sin(Time.get_ticks_msec() * 0.0025) * 0.2


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body is Player:
		_collected = true
		var sticker := GameManager.collect_random_sticker()
		GameManager.vibrate(35)
		if sticker != "" and FloatingText:
			FloatingText.spawn(get_parent(), global_position, "Karte: %s!" % sticker, Color(0.9, 0.6, 1.0))
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.2)
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		await tween.finished
		queue_free()


func _build_visual() -> void:
	var card := Polygon2D.new()
	card.color = Color(0.9, 0.6, 1.0)
	card.polygon = PackedVector2Array([
		Vector2(-14, -20), Vector2(14, -20), Vector2(14, 20), Vector2(-14, 20),
	])
	add_child(card)

	var inner := Polygon2D.new()
	inner.color = Color(1.0, 0.9, 1.0)
	inner.polygon = PackedVector2Array([
		Vector2(-10, -14), Vector2(10, -14), Vector2(10, 14), Vector2(-10, 14),
	])
	add_child(inner)

	var star := Label.new()
	star.text = "★"
	star.add_theme_font_size_override("font_size", 20)
	star.add_theme_color_override("font_color", Color(0.8, 0.5, 0.9))
	star.position = Vector2(-9, -14)
	add_child(star)

	var cshape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(28, 40)
	cshape.shape = rect_shape
	add_child(cshape)
