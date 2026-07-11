extends Node2D
class_name CoinChain
## CoinChain – Combo-Münzketten (FR-095)
## ===========================================
## Ein Container mit mehreren Münzen, die in fester Reihenfolge
## eingesammelt werden sollen. Werden alle in Folge (ohne eine
## andere Münze dazwischen zu verpassen) eingesammelt, gibt es
## einen Bonus. Nutzt die vorhandene Coin.tscn als Kind-Instanzen.

@export var coin_scene: PackedScene
@export var chain_bonus: int = 100
@export var positions: Array[Vector2] = [Vector2(0, 0), Vector2(60, -20), Vector2(120, -30), Vector2(180, -20), Vector2(240, 0)]

var _expected_index: int = 0
var _chain_broken: bool = false
var _coins: Array[Node] = []


func _ready() -> void:
	if coin_scene == null:
		return
	for i in range(positions.size()):
		var coin = coin_scene.instantiate()
		coin.position = positions[i]
		coin.coin_value = 15
		add_child(coin)
		_coins.append(coin)
		if coin.has_signal("collected"):
			coin.collected.connect(_on_coin_collected.bind(i))


func _on_coin_collected(_value: int, index: int) -> void:
	if _chain_broken:
		return
	if index == _expected_index:
		_expected_index += 1
		if _expected_index >= positions.size():
			_award_chain_bonus()
	else:
		_chain_broken = true


func _award_chain_bonus() -> void:
	GameManager.add_coin(chain_bonus)
	GameManager.vibrate(70)
	if FloatingText:
		FloatingText.spawn(get_parent(), global_position + positions[positions.size() - 1], "Ketten-Bonus +%d!" % chain_bonus, Color(1.0, 0.9, 0.3))
