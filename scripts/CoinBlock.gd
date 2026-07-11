extends StaticBody2D
class_name CoinBlock
## CoinBlock – Zerstörbare Münzblöcke (FR-097)
## =================================================
## Ein solider Block, der bei ausreichend hoher Aufprall-
## geschwindigkeit zerbricht und dabei mehrere Münzen freigibt.

@export var block_size: Vector2 = Vector2(60, 60)
@export var break_speed: float = 700.0
@export var coin_scene: PackedScene
@export var coin_reward_count: int = 3
@export var coin_value: int = 10
@export var color: Color = Color(0.75, 0.55, 0.2)

var _destroyed: bool = false
var _cshape: CollisionShape2D


func _ready() -> void:
	add_to_group("obstacles_neutral")
	_build_visual()


func _on_body_entered(body: Node) -> void:
	if _destroyed or not (body is Player):
		return
	if body.linear_velocity.length() >= break_speed:
		_break_block()


func _break_block() -> void:
	_destroyed = true
	_cshape.disabled = true
	GameManager.vibrate(40)

	# Münzen freisetzen (fliegen leicht auseinander)
	if coin_scene != null:
		for i in range(coin_reward_count):
			var coin = coin_scene.instantiate()
			coin.coin_value = coin_value
			get_parent().add_child(coin)
			coin.global_position = global_position
			var target_offset := Vector2(randf_range(-40, 40), randf_range(-50, -10))
			var tween := create_tween()
			tween.tween_property(coin, "global_position", global_position + target_offset, 0.3)

	# Bruchstück-Partikel
	for i in range(6):
		var frag := ColorRect.new()
		frag.size = Vector2(12, 12)
		frag.color = color
		frag.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		get_parent().add_child(frag)
		var ftween := create_tween()
		ftween.set_parallel(true)
		ftween.tween_property(frag, "position", frag.position + Vector2(randf_range(-60, 60), randf_range(-80, 20)), 0.5)
		ftween.tween_property(frag, "modulate:a", 0.0, 0.5)
		ftween.tween_callback(frag.queue_free)

	queue_free()


func _build_visual() -> void:
	var block := Polygon2D.new()
	block.color = color
	block.polygon = PackedVector2Array([
		Vector2(-block_size.x * 0.5, -block_size.y * 0.5),
		Vector2(block_size.x * 0.5, -block_size.y * 0.5),
		Vector2(block_size.x * 0.5, block_size.y * 0.5),
		Vector2(-block_size.x * 0.5, block_size.y * 0.5),
	])
	add_child(block)

	# Münz-Symbol darauf
	var label := Label.new()
	label.text = "$"
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	label.position = Vector2(-8, -18)
	add_child(label)

	_cshape = CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = block_size
	_cshape.shape = rect_shape
	add_child(_cshape)

	var area := Area2D.new()
	var area_shape := CollisionShape2D.new()
	area_shape.shape = rect_shape.duplicate()
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)
