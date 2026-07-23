extends Node
## AccessibilityManager (Autoload / Singleton)
## =====================================
## FR-421-440: Barrierefreiheits- und allgemeine Einstellungen (Farbenblind-
## Modus, hoher Kontrast, reduzierte Bewegung, Menü-Skalierung, Sound-
## Untertitel, Einhand-Modus, Ziel-Assistenz, Helligkeit, FPS-Anzeige/
## -Limit, Tipp-Bestätigungen, Pause bei Fokusverlust, Schwierigkeits-
## Assist, Sprache). Ausgelagert aus GameManager.gd im Rahmen des "God
## Object"-Refactorings (siehe README.md) — dieser Block war in sich
## geschlossen: eigenes Signal, eigener ConfigFile-Abschnitt, Setter, die
## nur zuweisen + speichern.
##
## master_volume/set_master_volume() bleiben bewusst in GameManager.gd
## (steuern denselben Master-Bus, den SoundManager.apply_mute() stumm-
## schaltet). sound_muted lebt in SoundManager.gd.

signal accessibility_changed  # löst UI-/Shader-Aktualisierungen aus

enum ColorblindMode { NONE, PROTANOPIA, DEUTERANOPIA, TRITANOPIA }  # FR-421/433
var colorblind_mode: ColorblindMode = ColorblindMode.NONE
var high_contrast_enabled: bool = false          # FR-422
var reduced_motion_enabled: bool = false          # FR-423
var menu_ui_scale: float = 1.0                    # FR-424 (0.85..1.3)
var sound_captions_enabled: bool = false          # FR-425
var one_handed_mode: bool = false                 # FR-426
var assist_aim_enabled: bool = false              # FR-427
var screen_brightness: float = 1.0                # FR-429 (0.5..1.0)
var fps_counter_enabled: bool = false             # FR-431
var fps_limit: int = 0                            # FR-432 (0 = unbegrenzt)
var tap_confirmations_enabled: bool = true        # FR-435
var pause_on_focus_loss: bool = true              # FR-436
var difficulty_assist_enabled: bool = false       # FR-437
const LANGUAGES := ["de", "en", "es", "fr"]        # FR-439
var language: String = "de"


func set_colorblind_mode(mode: ColorblindMode) -> void:
	colorblind_mode = mode
	accessibility_changed.emit()
	SaveManager.save_settings()


func set_high_contrast_enabled(enabled: bool) -> void:
	high_contrast_enabled = enabled
	accessibility_changed.emit()
	SaveManager.save_settings()


func set_reduced_motion_enabled(enabled: bool) -> void:
	reduced_motion_enabled = enabled
	SaveManager.save_settings()


func set_menu_ui_scale(value: float) -> void:
	menu_ui_scale = clampf(value, 0.85, 1.3)
	accessibility_changed.emit()
	SaveManager.save_settings()


## FR-424: Skaliert eine Menü-CanvasLayer um die Bildschirmmitte (gleiches
## Prinzip wie die bestehende HUD-Skalierung, FR-216) — wird von den
## einzelnen Overlay-Bildschirmen (Einstellungen, Shop, Sammlung, ...)
## aufgerufen, um lesbaren, größer skalierbaren Text/UI zu ermöglichen.
func apply_menu_ui_scale(layer: CanvasLayer, viewport_size: Vector2) -> void:
	var s := menu_ui_scale
	var pivot := viewport_size * 0.5
	layer.transform = Transform2D(0.0, Vector2.ONE * s, 0.0, pivot * (1.0 - s))


func set_sound_captions_enabled(enabled: bool) -> void:
	sound_captions_enabled = enabled
	SaveManager.save_settings()


func set_one_handed_mode(enabled: bool) -> void:
	one_handed_mode = enabled
	accessibility_changed.emit()
	SaveManager.save_settings()


func set_assist_aim_enabled(enabled: bool) -> void:
	assist_aim_enabled = enabled
	SaveManager.save_settings()


func set_screen_brightness(value: float) -> void:
	screen_brightness = clampf(value, 0.5, 1.0)
	accessibility_changed.emit()
	SaveManager.save_settings()


func set_fps_counter_enabled(enabled: bool) -> void:
	fps_counter_enabled = enabled
	SaveManager.save_settings()


## FR-432: 0 = unbegrenzt, sonst 30/60 als Akkuspar-Obergrenze.
func set_fps_limit(limit: int) -> void:
	fps_limit = limit
	Engine.max_fps = limit
	SaveManager.save_settings()


func set_tap_confirmations_enabled(enabled: bool) -> void:
	tap_confirmations_enabled = enabled
	SaveManager.save_settings()


func set_pause_on_focus_loss(enabled: bool) -> void:
	pause_on_focus_loss = enabled
	SaveManager.save_settings()


func set_difficulty_assist_enabled(enabled: bool) -> void:
	difficulty_assist_enabled = enabled
	SaveManager.save_settings()


## FR-439: Sprache umschalten.
func set_language(lang_code: String) -> void:
	if lang_code in LANGUAGES:
		language = lang_code
		TranslationServer.set_locale(lang_code)
		SaveManager.save_settings()


# --- FR-425: Untertitel für Soundeffekte --------------------------------

## Zeigt eine kurze Bildschirm-Einblendung, die einen Soundeffekt in
## Textform beschreibt (Barrierefreiheit für gehörlose/schwerhörige
## Spieler), sofern in den Einstellungen aktiviert.
func show_sound_caption(text: String) -> void:
	if not sound_captions_enabled:
		return
	var tree := get_tree()
	if tree == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 96
	tree.root.add_child(layer)
	var label := Label.new()
	label.text = "♪ " + text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	label.offset_left = 20
	label.offset_bottom = -140
	label.offset_top = -170
	label.modulate.a = 0.0
	layer.add_child(label)
	var tween := tree.create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.15)
	tween.tween_interval(0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(layer.queue_free)


# --- Persistenz-Schnittstelle für SaveManager.gd ------------------------

## Schreibt alle Barrierefreiheits-/Einstellungs-Felder in die übergebene
## ConfigFile — Abschnitt/Schlüssel exakt wie zuvor in
## SaveManager._save_settings(), damit bestehende Einstellungsdateien
## kompatibel bleiben.
func write_to_save(cfg: ConfigFile) -> void:
	cfg.set_value("accessibility", "colorblind_mode", colorblind_mode)  # FR-421
	cfg.set_value("accessibility", "high_contrast", high_contrast_enabled)  # FR-422
	cfg.set_value("accessibility", "reduced_motion", reduced_motion_enabled)  # FR-423
	cfg.set_value("accessibility", "menu_ui_scale", menu_ui_scale)      # FR-424
	cfg.set_value("accessibility", "sound_captions", sound_captions_enabled)  # FR-425
	cfg.set_value("accessibility", "one_handed", one_handed_mode)       # FR-426
	cfg.set_value("accessibility", "assist_aim", assist_aim_enabled)    # FR-427
	cfg.set_value("accessibility", "screen_brightness", screen_brightness)  # FR-429
	cfg.set_value("accessibility", "fps_counter", fps_counter_enabled)  # FR-431
	cfg.set_value("accessibility", "fps_limit", fps_limit)              # FR-432
	cfg.set_value("accessibility", "tap_confirmations", tap_confirmations_enabled)  # FR-435
	cfg.set_value("accessibility", "pause_on_focus_loss", pause_on_focus_loss)  # FR-436
	cfg.set_value("accessibility", "difficulty_assist", difficulty_assist_enabled)  # FR-437
	cfg.set_value("accessibility", "language", language)                # FR-439


## Liest alle Barrierefreiheits-/Einstellungs-Felder aus der ConfigFile —
## Abschnitt/Schlüssel exakt wie zuvor in SaveManager._load_settings().
func read_from_save(cfg: ConfigFile) -> void:
	colorblind_mode = cfg.get_value("accessibility", "colorblind_mode", ColorblindMode.NONE)  # FR-421
	high_contrast_enabled = cfg.get_value("accessibility", "high_contrast", false)  # FR-422
	reduced_motion_enabled = cfg.get_value("accessibility", "reduced_motion", false)  # FR-423
	menu_ui_scale = cfg.get_value("accessibility", "menu_ui_scale", 1.0)            # FR-424
	sound_captions_enabled = cfg.get_value("accessibility", "sound_captions", false)  # FR-425
	one_handed_mode = cfg.get_value("accessibility", "one_handed", false)           # FR-426
	assist_aim_enabled = cfg.get_value("accessibility", "assist_aim", false)        # FR-427
	screen_brightness = cfg.get_value("accessibility", "screen_brightness", 1.0)    # FR-429
	fps_counter_enabled = cfg.get_value("accessibility", "fps_counter", false)      # FR-431
	fps_limit = cfg.get_value("accessibility", "fps_limit", 0)                      # FR-432
	tap_confirmations_enabled = cfg.get_value("accessibility", "tap_confirmations", true)  # FR-435
	pause_on_focus_loss = cfg.get_value("accessibility", "pause_on_focus_loss", true)  # FR-436
	difficulty_assist_enabled = cfg.get_value("accessibility", "difficulty_assist", false)  # FR-437
	language = cfg.get_value("accessibility", "language", "de")                    # FR-439


## Setzt alle Felder auf ihre Werkseinstellung zurück. Wird von
## GameManager.reset_settings_to_default() aufgerufen.
func reset_to_default() -> void:
	colorblind_mode = ColorblindMode.NONE
	high_contrast_enabled = false
	reduced_motion_enabled = false
	menu_ui_scale = 1.0
	sound_captions_enabled = false
	one_handed_mode = false
	assist_aim_enabled = false
	screen_brightness = 1.0
	fps_counter_enabled = false
	fps_limit = 0
	tap_confirmations_enabled = true
	pause_on_focus_loss = true
	difficulty_assist_enabled = false
	language = "de"
	Engine.max_fps = 0
	accessibility_changed.emit()
