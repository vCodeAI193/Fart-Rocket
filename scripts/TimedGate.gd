extends StaticBody2D
class_name TimedGate
## TimedGate – Schließendes Tor mit Timing (FR-073)
## =================================================
## Ein Tor, das sich rhythmisch öffnet und schließt.
## Der Spieler muss den richtigen Moment abpassen.

@export var gate_size: Vector2 = Vector2(20, 200)
@export var open_time: float = 1.5
@export var closed_time: float = 1.5
@export var warning_time: float = 0.5  # Vorwarnzeit vor dem Schließen
@export var start_open: bool = true

var _is_open: bool = true
var _timer: float = 0.0
var _gate_rect: ColorRect
var _warning_flash: bool = false


func _ready() -> void:
	add_to_group("obstacles")
	_is_open = start_open
	_timer = open_time if start_open else closed_time
	_build_visual()
	_update_collision()


func _process(delta: float) -> void:
	_timer -= delta

	# Vorwarnung: Blinken bevor sich das Tor schließt
	if _is_open and _timer <= warning_time and _timer > 0.0:
		_warning_flash = true
		_gate_rect.modulate.a = 0.4 + sin(Time.get_ticks_msec() * 0.02) * 0.3
	else:
		_warning_flash = false

	if _timer <= 0.0:
		_toggle_gate()


func _toggle_gate() -> void:
	_is_open = not _is_open
	_timer = open_time if _is_open else closed_time
	_update_collision()
	GameManager.vibrate(10)

	var tween := create_tween()
	if _is_open:
		tween.tween_property(_gate_rect, "modulate:a", 0.15, 0.15)
	else:
		tween.tween_property(_gate_rect, "modulate:a", 1.0, 0.15)


func _update_collision() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = _is_open


func _build_visual() -> void:
	_gate_rect = ColorRect.new()
	_gate_rect.size = gate_size
	_gate_rect.position = -gate_size * 0.5
	_gate_rect.color = Color(0.8, 0.2, 0.2, 0.9)
	_gate_rect.modulate.a = 0.15 if start_open else 1.0
	add_child(_gate_rect)

	# Streifen-Muster (Warnstreifen)
	var stripe_count := int(gate_size.y / 30.0)
	for i in range(stripe_count):
		var y := -gate_size.y * 0.5 + i * 30.0
		var stripe := ColorRect.new()
		stripe.size = Vector2(gate_size.x, 10)
		stripe.position = Vector2(-gate_size.x * 0.5, y)
		stripe.color = Color(1.0, 0.8, 0.1, 0.8)
		_gate_rect.add_child(stripe)

	var cshape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = gate_size
	cshape.shape = rect_shape
	add_child(cshape)
