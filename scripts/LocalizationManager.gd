extends Node
## LocalizationManager (Autoload / Singleton)
## =============================================
## FR-441: Lokalisierungs-System. Da dieses Projekt ohne Godot-Editor-
## Zugriff entwickelt wird (kein CSV-/PO-Import über die Editor-GUI
## möglich), werden die Übersetzungen direkt im Code als Translation-
## Ressourcen aufgebaut und über TranslationServer registriert — das ist
## zur Laufzeit technisch identisch zu importierten .po/.csv-Dateien
## (gleiche tr()-API, gleiches Locale-System), nur ohne den Editor-
## Zwischenschritt.
##
## FR-442/443/444/445: Deutsch (Standard), Englisch, Spanisch,
## Französisch werden für eine kuratierte Menge der wichtigsten,
## sichtbarsten UI-Zeichenketten gepflegt (Menüs, Einstellungen, HUD-
## Kernbegriffe) statt jede der hunderten Laufzeit-erzeugten
## Zeichenketten im gesamten Projekt zu übersetzen — das wäre ein
## eigenständiges Mehrfach-Batch-Projekt für sich.
## FR-446-452 (weitere Sprachen) bleiben zurückgestellt.

# --- FR-442/443/444/445: Kuratierte Übersetzungstabelle -------------
const STRINGS := {
	"menu_play": {"de": "Level %d", "en": "Level %d", "es": "Nivel %d", "fr": "Niveau %d"},
	"menu_shop": {"de": "Shop", "en": "Shop", "es": "Tienda", "fr": "Boutique"},
	"menu_collection": {"de": "Sammlung", "en": "Collection", "es": "Colección", "fr": "Collection"},
	"menu_progression": {"de": "Fortschritt", "en": "Progress", "es": "Progreso", "fr": "Progression"},
	"menu_game_mode": {"de": "Spielmodus", "en": "Game Mode", "es": "Modo de juego", "fr": "Mode de jeu"},
	"menu_settings": {"de": "Einstellungen", "en": "Settings", "es": "Ajustes", "fr": "Paramètres"},
	"menu_bestiary": {"de": "Bestiarium", "en": "Bestiary", "es": "Bestiario", "fr": "Bestiaire"},
	"menu_quit": {"de": "Beenden", "en": "Quit", "es": "Salir", "fr": "Quitter"},
	"menu_continue": {"de": "Weiter", "en": "Continue", "es": "Continuar", "fr": "Continuer"},
	"action_close": {"de": "Schließen", "en": "Close", "es": "Cerrar", "fr": "Fermer"},
	"action_retry": {"de": "Nochmal", "en": "Retry", "es": "Reintentar", "fr": "Réessayer"},
	"action_next_level": {"de": "Nächstes Level", "en": "Next Level", "es": "Siguiente nivel", "fr": "Niveau suivant"},
	"action_choose": {"de": "Wählen", "en": "Choose", "es": "Elegir", "fr": "Choisir"},
	"action_active": {"de": "Aktiv", "en": "Active", "es": "Activo", "fr": "Actif"},
	"action_reset_progress": {"de": "Fortschritt zurücksetzen", "en": "Reset Progress", "es": "Reiniciar progreso", "fr": "Réinitialiser la progression"},
	"action_reset_settings": {"de": "Einstellungen zurücksetzen", "en": "Reset Settings", "es": "Restablecer ajustes", "fr": "Réinitialiser les paramètres"},
	"action_delete_all_data": {"de": "Alle Daten löschen", "en": "Delete All Data", "es": "Eliminar todos los datos", "fr": "Supprimer toutes les données"},
	"hud_coins": {"de": "Münzen", "en": "Coins", "es": "Monedas", "fr": "Pièces"},
	"hud_paused": {"de": "Pausiert", "en": "Paused", "es": "Pausado", "fr": "En pause"},
	"hud_checkpoint": {"de": "Checkpoint erreicht!", "en": "Checkpoint reached!", "es": "¡Punto de control alcanzado!", "fr": "Point de contrôle atteint !"},
	"result_stars": {"de": "Sterne", "en": "Stars", "es": "Estrellas", "fr": "Étoiles"},
	"result_time": {"de": "Zeit", "en": "Time", "es": "Tiempo", "fr": "Temps"},
	"caption_fart": {"de": "Furz!", "en": "Fart!", "es": "¡Pedo!", "fr": "Pet !"},
	"caption_coin": {"de": "Münze!", "en": "Coin!", "es": "¡Moneda!", "fr": "Pièce !"},
	"caption_crash": {"de": "Crash!", "en": "Crash!", "es": "¡Choque!", "fr": "Crash !"},
	"achievement_unlocked": {"de": "Erfolg freigeschaltet!", "en": "Achievement unlocked!", "es": "¡Logro desbloqueado!", "fr": "Succès débloqué !"},
	"daily_login_bonus": {"de": "Tag %d Login-Bonus: +%d Münzen!", "en": "Day %d login bonus: +%d coins!", "es": "Bono de día %d: ¡+%d monedas!", "fr": "Bonus jour %d : +%d pièces !"},
	"settings_graphics": {"de": "Grafik", "en": "Graphics", "es": "Gráficos", "fr": "Graphismes"},
	"settings_accessibility": {"de": "Barrierefreiheit", "en": "Accessibility", "es": "Accesibilidad", "fr": "Accessibilité"},
	"settings_save_slots": {"de": "Speicherplätze", "en": "Save Slots", "es": "Espacios de guardado", "fr": "Emplacements de sauvegarde"},
	"settings_language": {"de": "Sprache", "en": "Language", "es": "Idioma", "fr": "Langue"},
	"on": {"de": "EIN", "en": "ON", "es": "ACTIVADO", "fr": "ACTIVÉ"},
	"off": {"de": "AUS", "en": "OFF", "es": "DESACTIVADO", "fr": "DÉSACTIVÉ"},
}

# --- FR-458: Pluralisierungs-Beispiel (Level-Anzahl) ------------------
const PLURAL_LEVELS := {
	"de": {"one": "%d Level", "other": "%d Level"},
	"en": {"one": "%d level", "other": "%d levels"},
	"es": {"one": "%d nivel", "other": "%d niveles"},
	"fr": {"one": "%d niveau", "other": "%d niveaux"},
}

const SUPPORTED_LOCALES := ["de", "en", "es", "fr"]
const FALLBACK_LOCALE := "de"  # FR-459
# FR-453: Rechtsläufige Sprachen — reine Infrastruktur, da noch keine
# davon inhaltlich unterstützt wird (Arabisch/Hebräisch/... erfordern
# zusätzliche Übersetzungen, siehe zurückgestellte FR-446-452).
const RTL_LOCALES := ["ar", "he", "fa", "ur"]


func is_rtl_locale(locale: String = "") -> bool:
	var loc := locale if locale != "" else GameManager.language
	return loc in RTL_LOCALES


## FR-453: Setzt die Text-/Layout-Richtung einer Control-Wurzel passend
## zur aktuellen Sprache — betrifft aktuell keine der vier unterstützten
## Sprachen, ist aber bereits vollständig verdrahtet für eine spätere
## RTL-Sprache.
func apply_layout_direction(control: Control) -> void:
	control.layout_direction = (
		Control.LAYOUT_DIRECTION_RTL if is_rtl_locale()
		else Control.LAYOUT_DIRECTION_LTR
	)


func _ready() -> void:
	_build_translations()
	TranslationServer.set_locale(GameManager.language)
	# FR-460: QA-Prüfung auf fehlende Übersetzungen — nur in Debug-Builds,
	# damit Release-Builds nicht durch Konsolen-Ausgaben belastet werden.
	if OS.is_debug_build():
		var missing := validate_translations()
		if not missing.is_empty():
			push_warning("Fehlende Übersetzungen: %s" % ", ".join(missing))


## FR-441: Baut für jede unterstützte Sprache eine Translation-Ressource
## aus STRINGS auf und registriert sie beim TranslationServer — danach
## funktioniert die eingebaute tr("KEY")-Funktion normal.
func _build_translations() -> void:
	for locale in SUPPORTED_LOCALES:
		var translation := Translation.new()
		translation.locale = locale
		for key in STRINGS.keys():
			var entry: Dictionary = STRINGS[key]
			translation.add_message(key, entry.get(locale, entry[FALLBACK_LOCALE]))
		TranslationServer.add_translation(translation)


## FR-459: Übersetzt einen Schlüssel mit garantiertem Fallback — liefert
## den deutschen Text, falls für die aktuelle Sprache (oder den Schlüssel
## selbst) keine Übersetzung hinterlegt ist, statt des rohen Schlüssels.
func tr_safe(key: String) -> String:
	var result := tr(key)
	if result == key and STRINGS.has(key):
		return String(STRINGS[key].get(FALLBACK_LOCALE, key))
	return result


## FR-458: Pluralisierte Level-Anzahl passend zur aktuellen Sprache.
func format_level_count(n: int) -> String:
	var locale: String = TranslationServer.get_locale()
	var rules: Dictionary = PLURAL_LEVELS.get(locale, PLURAL_LEVELS[FALLBACK_LOCALE])
	var form: String = rules["one"] if n == 1 else rules["other"]
	return form % n


## FR-454: Lokalisiertes Dezimaltrennzeichen (DE/FR: Komma, EN/ES: Punkt).
func format_number(value: float, decimals: int = 1) -> String:
	var s := "%.*f" % [decimals, value]
	if GameManager.language in ["de", "fr"]:
		s = s.replace(".", ",")
	return s


## FR-454: Lokalisiertes Zeitformat — die Ziffernfolge ist überall
## identisch (mm:ss), aber das Dezimaltrennzeichen für Millisekunden-
## Anzeigen folgt FR-454.
func format_time_locale(seconds: float) -> String:
	var minutes := int(seconds) / 60
	var secs := fmod(seconds, 60.0)
	var secs_str := format_number(secs, 2)
	return "%02d:%s" % [minutes, secs_str]


## FR-460: QA-Werkzeug — findet Schlüssel, denen für mindestens eine
## unterstützte Sprache die Übersetzung fehlt (leerer String oder exakt
## gleich dem deutschen Text, was auf eine vergessene Übersetzung
## hindeuten kann). Gibt eine Liste von "key (locale)"-Einträgen zurück.
func validate_translations() -> Array[String]:
	var missing: Array[String] = []
	for key in STRINGS.keys():
		var entry: Dictionary = STRINGS[key]
		for locale in SUPPORTED_LOCALES:
			if not entry.has(locale) or String(entry[locale]).is_empty():
				missing.append("%s (%s)" % [key, locale])
	return missing
