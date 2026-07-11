extends CanvasLayer
class_name LoadingScreen
## LoadingScreen – Lade-Bildschirm mit Tipps (FR-229)
## =========================================================
## Kurzer Übergangs-Bildschirm mit rotierenden Gameplay-Tipps,
## während das nächste Level geladen wird.

const TIPS := [
	"Halte länger gezielt für einen stärkeren Furz-Stoß!",
	"Perfekte Kardinalwinkel (oben/unten/links/rechts) geben Bonus-Schub.",
	"Sammle Combo-Münzen schnell hintereinander für mehr Punkte.",
	"Ein Doppel-Tipp startet das Level sofort neu.",
	"Checkpoints retten deinen Fortschritt — fliege durch die Flaggen!",
	"Im Einstellungsmenü kannst du die Steuerung kalibrieren.",
	"Manche Gegner lassen sich nur von hinten besiegen.",
	"Münzblöcke zerbrechen bei genug Aufprall-Tempo.",
]

var _label: Label


func _ready() -> void:
	layer = 130
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.08, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "Lädt..."
	title.add_theme_font_size_override("font_size", 56)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_top = 300.0
	title.offset_left = -200.0
	title.offset_right = 200.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg.add_child(title)

	_label = Label.new()
	_label.text = TIPS[randi() % TIPS.size()]
	_label.add_theme_font_size_override("font_size", 32)
	_label.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0))
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.offset_left = -500.0
	_label.offset_right = 500.0
	_label.offset_top = -40.0
	_label.offset_bottom = 40.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	bg.add_child(_label)


## Zeigt den Ladebildschirm für `duration` Sekunden, dann ruft er `callback` auf.
static func show_and_call(parent: Node, duration: float, callback: Callable) -> void:
	var screen := LoadingScreen.new()
	parent.add_child(screen)
	await parent.get_tree().create_timer(duration).timeout
	callback.call()
	if is_instance_valid(screen):
		screen.queue_free()
