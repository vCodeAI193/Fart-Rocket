extends Area2D
class_name BossWeakPoint
## BossWeakPoint – Wiederverwendbare Boss-Schwachstelle (FR-119)
## ===================================================================
## Eine verwundbare Stelle an einem Boss. Trifft der Spieler sie mit
## ausreichend Tempo, registriert sie einen Treffer. Nach `hits_required`
## Treffern gilt die Schwachstelle als besiegt.

signal hit_taken(remaining: int)
signal defeated

@export var hits_required: int = 3
@export var min_impact_speed: float = 350.0
@export var radius: float = 22.0
@export var hit_cooldown: float = 0.6

var _hits_remaining: int
var _cooldown_timer: float = 0.0
var _visual: Polygon2D
var _is_defeated: bool = false


func _ready() -> void:
	_hits_remaining = hits_required
	body_entered.connect(_on_body_entered)
	_build_visual()


func _process(delta: float) -> void:
	_cooldown_timer = maxf(0.0, _cooldown_timer - delta)
	if not _is_defeated and _visual != null:
		_visual.modulate.a = 0.7 + sin(Time.get_ticks_msec() * 0.006) * 0.3


func _on_body_entered(body: Node) -> void:
	if _is_defeated or _cooldown_timer > 0.0:
		return
	if body is Player and body.linear_velocity.length() >= min_impact_speed:
		_register_hit()


func _register_hit() -> void:
	_hits_remaining -= 1
	_cooldown_timer = hit_cooldown
	GameManager.vibrate(40)
	hit_taken.emit(_hits_remaining)

	var tween := create_tween()
	tween.tween_property(_visual, "modulate", Color(1.0, 1.0, 1.0), 0.08)
	tween.tween_property(_visual, "modulate", Color(1.0, 0.3, 0.2), 0.08)

	if _hits_remaining <= 0:
		_is_defeated = true
		defeated.emit()
		var death_tween := create_tween()
		death_tween.tween_property(_visual, "scale", Vector2.ZERO, 0.3)
		death_tween.tween_callback(func(): visible = false)
		set_deferred("monitoring", false)


func _build_visual() -> void:
	_visual = Polygon2D.new()
	_visual.color = Color(1.0, 0.3, 0.2)
	var pts := PackedVector2Array()
	for i in range(10):
		var a := TAU * float(i) / 10.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	_visual.polygon = pts
	add_child(_visual)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	cshape.shape = circle
	add_child(cshape)
