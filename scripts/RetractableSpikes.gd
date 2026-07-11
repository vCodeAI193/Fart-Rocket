extends StaticBody2D
class_name RetractableSpikes
## RetractableSpikes – Ein-/ausfahrende Stacheln (FR-064)
## =========================================================
## Stacheln, die rhythmisch aus dem Boden ein- und ausfahren.
## Timing-Rätsel: nur sicher wenn eingefahren.

@export var spike_count: int = 5
@export var spike_width: float = 24.0
@export var extended_height: float = 40.0
@export var retracted_time: float = 1.2
@export var extended_time: float = 0.8
@export var warning_time: float = 0.4
@export var color: Color = Color(0.6, 0.6, 0.65)

var _is_extended: bool = false
var _timer: float = 0.0
var _spikes_node: Node2D
var _cshape: CollisionShape2D


func _ready() -> void:
	add_to_group("obstacles")
	_timer = retracted_time
	_build_visual()
	_update_extension(0.0)


func _process(delta: float) -> void:
	_timer -= delta

	# Vorwarnung durch Vibrieren der Stacheln
	if not _is_extended and _timer <= warning_time and _timer > 0.0:
		_spikes_node.position.x = sin(Time.get_ticks_msec() * 0.05) * 2.0
	else:
		_spikes_node.position.x = 0.0

	if _timer <= 0.0:
		_toggle()


func _toggle() -> void:
	_is_extended = not _is_extended
	_timer = extended_time if _is_extended else retracted_time
	GameManager.vibrate(15)

	var tween := create_tween()
	var target := 1.0 if _is_extended else 0.0
	tween.tween_method(_update_extension, 1.0 - target, target, 0.15)


func _update_extension(t: float) -> void:
	_spikes_node.scale.y = t
	if _cshape != null:
		_cshape.disabled = t < 0.5


func _build_visual() -> void:
	_spikes_node = Node2D.new()
	_spikes_node.position = Vector2(0, -extended_height * 0.5)
	add_child(_spikes_node)

	var total_width := spike_count * spike_width
	for i in range(spike_count):
		var x := -total_width * 0.5 + i * spike_width + spike_width * 0.5
		var spike := Polygon2D.new()
		spike.color = color
		var pts := PackedVector2Array([
			Vector2(x - spike_width * 0.4, extended_height * 0.5),
			Vector2(x, -extended_height * 0.5),
			Vector2(x + spike_width * 0.4, extended_height * 0.5),
		])
		spike.polygon = pts
		_spikes_node.add_child(spike)

	_cshape = CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(total_width, extended_height)
	_cshape.shape = rect_shape
	_cshape.position = Vector2(0, -extended_height * 0.5)
	add_child(_cshape)
