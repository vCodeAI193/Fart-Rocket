class_name UIHelpers
extends RefCounted
## UIHelpers – gemeinsame UI-Konstruktions-Hilfsfunktionen
## =========================================================
## Reine, zustandslose Node-Fabrikfunktionen für die Bildschirm-Skripte
## (SettingsScreen, ShopScreen, ProgressionScreen, CollectionScreen,
## MainMenu, GameModeScreen). RefCounted + statische Methoden statt eines
## eigenen Autoloads, da kein Bedarf für Lifecycle/Signale/persistenten
## Zustand besteht — anders als SaveManager/SoundManager/etc.
##
## Deckt in dieser Runde die beiden am eindeutigsten wiederholten Fälle ab:
##  - make_button(): der immer gleiche "Text-Button in einer Liste"-Fall
##    (vormals SettingsScreens lokale, nur dort nutzbare
##    _make_settings_button()).
##  - make_close_button(): ein byteidentischer 11-Zeilen-Block, der zuvor
##    wortwörtlich in ShopScreen.gd/ProgressionScreen.gd/
##    CollectionScreen.gd/GameModeScreen.gd dupliziert war.
## Die zahlreichen individuell positionierten Label/Anchor-Kombinationen
## (Titel, Balance-Anzeigen, Badges, ...) bleiben bewusst unangetastet —
## ohne visuelle Prüfmöglichkeit in dieser Umgebung wäre ein blindes
## mechanisches Umschreiben ihrer Einzel-Offsets ein unnötig hohes
## Regressions-Risiko für wenig Zusatznutzen gegenüber den beiden klar
## wiederholten Fällen oben.


## Einheitlich großer Text-Button, an ein Elternelement gehängt (z.B. eine
## VBoxContainer-Liste). Größe/Schriftgröße sind für Einstellungs-Listen
## voreingestellt, aber überschreibbar.
static func make_button(parent: Node, callback: Callable,
		size: Vector2 = Vector2(400, 76), font_size: int = 26) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = size
	btn.add_theme_font_size_override("font_size", font_size)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


## Standard-"Schließen"-Button unten rechts (spielt einen UI-Klick und
## ruft danach on_close auf, üblicherweise "visible = false" des Overlays).
static func make_close_button(parent: Node, on_close: Callable) -> Button:
	var close_btn := Button.new()
	close_btn.text = "Schließen"
	close_btn.custom_minimum_size = Vector2(240, 70)
	close_btn.add_theme_font_size_override("font_size", 32)
	close_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	close_btn.offset_left = -260
	close_btn.offset_top = -90
	close_btn.offset_right = -20
	close_btn.offset_bottom = -20
	close_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		on_close.call()
	)
	parent.add_child(close_btn)
	return close_btn
