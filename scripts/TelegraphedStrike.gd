extends Area2D
class_name TelegraphedStrike
## TelegraphedStrike – Angriff mit deutlicher Vorwarn-Animation (FR-080)
## =========================================================================
## Ein generisches "Angriffs"-Hindernis: zeigt zuerst eine klare
## Vorwarnung (rote wachsende Warnzone), schlägt dann kurz zu und
## zieht sich danach zurück. Eignet sich als Baustein für Bosse/Fallen.

@export var strike_radius: float = 60.0
@export var warning_time: float = 0.8
@export var strike_time: float = 0.25
@export var cooldown_time: float = 1.5
@export var color: Color = Color(0.9, 0.2, 0.2)

enum State { IDLE, WARNING, STRIKING, COOLDOWN }
var _state: State = State.IDLE
var _timer: float = 0.0
var _warning_visual: Polygon2D
var _cshape: CollisionShape2D


func _ready() -> void:
	add_to_group("obstacles")
	body_entered.connect(_on_body_entered)
	_timer = cooldown_time
	_state = State.COOLDOWN
	_build_visual()
	_cshape.disabled = true


func _process(delta: float) -> void:
	_timer -= delta

	match _state:
		State.COOLDOWN:
			if _timer <= 0.0:
				_start_warning()
		State.WARNING:
			# Wachsende Warnzone + Puls-Blinken
			var progress := 1.0 - clampf(_timer / warning_time, 0.0, 1.0)
			_warning_visual.scale = Vector2.ONE * lerpf(0.2, 1.0, progress)
			_warning_visual.modulate.a = 0.3 + sin(Time.get_ticks_msec() * 0.03) * 0.25
			if _timer <= 0.0:
				_start_strike()
		State.STRIKING:
			if _timer <= 0.0:
				_end_strike()


func _start_warning() -> void:
	_state = State.WARNING
	_timer = warning_time
	_warning_visual.visible = true
	_warning_visual.color = Color(color.r, color.g, color.b, 0.35)


func _start_strike() -> void:
	_state = State.STRIKING
	_timer = strike_time
	_cshape.disabled = false
	_warning_visual.color = color
	_warning_visual.modulate.a = 0.9
	_warning_visual.scale = Vector2.ONE
	GameManager.vibrate(35)


func _end_strike() -> void:
	_state = State.COOLDOWN
	_timer = cooldown_time
	_cshape.disabled = true
	_warning_visual.visible = false


func _on_body_entered(body: Node) -> void:
	if body is Player and _state == State.STRIKING:
		body._on_body_entered(self)


func _build_visual() -> void:
	_warning_visual = Polygon2D.new()
	_warning_visual.color = Color(color.r, color.g, color.b, 0.3)
	var pts := PackedVector2Array()
	for i in range(16):
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a), sin(a)) * strike_radius)
	_warning_visual.polygon = pts
	_warning_visual.visible = false
	add_child(_warning_visual)

	_cshape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = strike_radius
	_cshape.shape = circle
	add_child(_cshape)
