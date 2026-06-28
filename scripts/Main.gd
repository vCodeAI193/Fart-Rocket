extends Node2D
## Main – Level-Lader & Spielablauf
## ================================
## Lädt das im GameManager gewählte Level, verbindet die Signale von
## Player und Ziel-Flagge, steuert Kamera, HUD und den
## Abschlussbildschirm (LevelComplete).

@onready var _level_container: Node2D = $LevelContainer
@onready var _camera: Camera2D = $Camera2D
@onready var _hud: HUD = $HUD
@onready var _level_complete: LevelComplete = $LevelComplete

var _player: Player
var _level_end: LevelEnd
var _max_charges: int = 0
var _level_finished: bool = false

# Fällt das Männchen unter diese Grenze (oder fliegt weit darüber hinaus),
# gilt das Level als verloren und wird neu gestartet.
const FALL_LIMIT_Y := 1700.0
const SKY_LIMIT_Y := -1200.0


func _ready() -> void:
	# Abschluss-Buttons verbinden
	_level_complete.next_level_pressed.connect(_on_next_level)
	_level_complete.retry_pressed.connect(_on_retry)
	_level_complete.menu_pressed.connect(_on_menu)

	_load_current_level()


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	# Kamera folgt dem Männchen (nur Position, keine Rotation)
	_camera.global_position = _player.global_position
	# Aus dem Spielfeld gefallen? -> Level neu starten
	if not _level_finished:
		var y := _player.global_position.y
		if y > FALL_LIMIT_Y or y < SKY_LIMIT_Y:
			_level_finished = true
			get_tree().reload_current_scene()


## Lädt die aktuelle Level-Szene und richtet das Spiel ein.
func _load_current_level() -> void:
	_level_finished = false
	var path := GameManager.get_level_scene_path(GameManager.current_level)
	var level_scene: PackedScene = load(path)
	var level := level_scene.instantiate()
	_level_container.add_child(level)

	# Player und Ziel im Level finden (mit Cast auf die konkreten Typen)
	_player = _find_in_group(level, "player") as Player
	_level_end = _find_in_group(level, "level_end") as LevelEnd

	if _player == null:
		push_error("Kein Player (Gruppe 'player') im Level gefunden!")
		return

	# Furz-Ladungen aus dem Player übernehmen
	_max_charges = _player.max_fart_charges
	GameManager.start_level(GameManager.current_level, _max_charges)

	# HUD einrichten
	_hud.set_max_charges(_max_charges)
	_hud.start_timer()

	# FR-002: Furz-Typ-Auswahl aufbauen und mit dem Player verbinden
	_hud.setup_fart_types(_player.get_fart_types(), _player.get_fart_type_index())
	_hud.fart_type_selected.connect(_player.set_fart_type)
	_player.fart_type_changed.connect(_hud.highlight_fart_type)

	# Signale verbinden
	_player.died.connect(_on_player_died)
	if _level_end != null:
		_level_end.reached.connect(_on_level_reached)

	# Kamera sofort auf den Player setzen
	_camera.global_position = _player.global_position
	_camera.make_current()


# --- Spielereignisse --------------------------------------------
func _on_player_died() -> void:
	# Männchen hat ein Hindernis getroffen -> Level neu starten
	get_tree().reload_current_scene()


func _on_level_reached() -> void:
	if _level_finished:
		return
	_level_finished = true

	# Zeit stoppen und Sterne berechnen
	var time_sec: float = _hud.stop_timer()
	var stars := GameManager.calculate_stars(_max_charges)
	GameManager.record_stars(GameManager.current_level, stars)

	# Abschlussbildschirm anzeigen
	_level_complete.show_result(
		stars,
		GameManager.total_coins,
		time_sec,
		GameManager.has_next_level()
	)


# --- Buttons im Abschlussbildschirm -----------------------------
func _on_next_level() -> void:
	if GameManager.has_next_level():
		GameManager.current_level += 1
	get_tree().reload_current_scene()


func _on_retry() -> void:
	get_tree().reload_current_scene()


func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


# --- Hilfsfunktion: ersten Knoten einer Gruppe im Baum finden ---
func _find_in_group(root: Node, group_name: String) -> Node:
	if root.is_in_group(group_name):
		return root
	for child in root.get_children():
		var found := _find_in_group(child, group_name)
		if found != null:
			return found
	return null
