extends Area2D
class_name MysteryBox
## MysteryBox – Power-up-Roulette (FR-094)
## =============================================
## Eine Box, die beim Berühren zufällig eines von mehreren
## Power-ups auslöst (Schild, Zeitlupe, Doppelmünzen, Ladung).
## Zeigt vor der endgültigen Wahl eine kurze "Roulette"-Animation.

@export var size: float = 26.0
@export var roulette_duration: float = 0.8

enum RewardType { SHIELD, SLOWMO, DOUBLE_COINS, CHARGE, COINS }
const REWARD_LABELS := {
	RewardType.SHIELD: "Schild!",
	RewardType.SLOWMO: "Zeitlupe!",
	RewardType.DOUBLE_COINS: "x2 Münzen!",
	RewardType.CHARGE: "+1 Ladung!",
	RewardType.COINS: "Bonus-Münzen!",
}

var _collected: bool = false
var _icon_label: Label


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _process(delta: float) -> void:
	if not _collected:
		rotation = sin(Time.get_ticks_msec() * 0.002) * 0.1


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body is Player:
		_collected = true
		_start_roulette(body)


func _start_roulette(player: Player) -> void:
	GameManager.vibrate(30)
	var roulette_tween := create_tween()
	var flashes := 8
	for i in range(flashes):
		var r := randi_range(0, RewardType.size() - 1)
		roulette_tween.tween_callback(func(): _icon_label.text = REWARD_LABELS[r])
		roulette_tween.tween_interval(roulette_duration / float(flashes))
	roulette_tween.tween_callback(func(): _resolve_reward(player))
	await roulette_tween.finished


func _resolve_reward(player: Player) -> void:
	var reward: int = randi_range(0, RewardType.size() - 1)
	match reward:
		RewardType.SHIELD:
			player.activate_shield(6.0)
		RewardType.SLOWMO:
			Engine.time_scale = 0.4
			get_tree().create_timer(3.0, false, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
		RewardType.DOUBLE_COINS:
			GameManager.activate_double_coins(8.0)
		RewardType.CHARGE:
			GameManager.add_charge()
		RewardType.COINS:
			GameManager.add_coin(60)

	if FloatingText:
		FloatingText.spawn(get_parent(), global_position, REWARD_LABELS[reward], Color(1.0, 0.85, 0.2))
	GameManager.vibrate(60)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	queue_free()


func _build_visual() -> void:
	var box := Polygon2D.new()
	box.color = Color(0.6, 0.3, 0.75)
	box.polygon = PackedVector2Array([
		Vector2(-size, -size), Vector2(size, -size),
		Vector2(size, size), Vector2(-size, size),
	])
	add_child(box)

	_icon_label = Label.new()
	_icon_label.text = "?"
	_icon_label.add_theme_font_size_override("font_size", 32)
	_icon_label.add_theme_color_override("font_color", Color.WHITE)
	_icon_label.position = Vector2(-10, -20)
	add_child(_icon_label)

	var cshape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(size * 2.0, size * 2.0)
	cshape.shape = rect_shape
	add_child(cshape)
