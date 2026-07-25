extends TestCase
## Tests für LocalizationManager (FR-441-460) — bislang ohne eigene Tests,
## obwohl es die einzige Stelle ist, an der sprachabhängige Formatierung
## und der Übersetzungs-Fallback zusammenlaufen.


func test_all_strings_are_translated_for_every_supported_locale() -> void:
	# FR-460: Das mitgelieferte QA-Werkzeug meldet fehlende Übersetzungen.
	# Wenn es etwas findet, ist das ein echter Lokalisierungs-Fehler.
	var missing := LocalizationManager.validate_translations()
	assert_eq(missing.size(), 0,
		"Fehlende Übersetzungen: %s" % ", ".join(missing))


func test_supported_locales_match_selectable_languages() -> void:
	# Die im Einstellungsmenü wählbaren Sprachen (AccessibilityManager)
	# müssen deckungsgleich mit den übersetzten Sprachen sein — sonst
	# könnte man eine Sprache wählen, für die es keine Texte gibt.
	for lang in AccessibilityManager.LANGUAGES:
		assert_true(lang in LocalizationManager.SUPPORTED_LOCALES,
			"Wählbare Sprache '%s' fehlt in SUPPORTED_LOCALES" % lang)
	for locale in LocalizationManager.SUPPORTED_LOCALES:
		assert_true(locale in AccessibilityManager.LANGUAGES,
			"Übersetzte Sprache '%s' ist im Menü nicht wählbar" % locale)


func test_tr_safe_falls_back_to_german_for_unknown_locale() -> void:
	var original := TranslationServer.get_locale()
	# Eine Sprache setzen, für die es keine Übersetzungen gibt
	TranslationServer.set_locale("it")

	# Ein beliebiger bekannter Schlüssel muss trotzdem einen echten Text
	# liefern (deutschen Fallback), nicht den rohen Schlüssel.
	var any_key: String = LocalizationManager.STRINGS.keys()[0]
	var result := LocalizationManager.tr_safe(any_key)
	assert_true(result != any_key,
		"tr_safe() sollte bei unbekannter Sprache den Fallback liefern, nicht '%s'" % any_key)

	TranslationServer.set_locale(original)


func test_tr_safe_returns_key_for_completely_unknown_key() -> void:
	var result := LocalizationManager.tr_safe("__diesen_schluessel_gibt_es_nicht__")
	assert_eq(result, "__diesen_schluessel_gibt_es_nicht__",
		"Ein unbekannter Schlüssel sollte unverändert zurückkommen")


func test_format_number_uses_locale_decimal_separator() -> void:
	var original := AccessibilityManager.language

	AccessibilityManager.language = "de"
	assert_eq(LocalizationManager.format_number(1.5, 1), "1,5", "Deutsch nutzt ein Komma")

	AccessibilityManager.language = "en"
	assert_eq(LocalizationManager.format_number(1.5, 1), "1.5", "Englisch nutzt einen Punkt")

	AccessibilityManager.language = original


func test_format_level_count_pluralizes() -> void:
	var original := TranslationServer.get_locale()
	TranslationServer.set_locale("de")

	var one := LocalizationManager.format_level_count(1)
	var many := LocalizationManager.format_level_count(5)
	assert_true(one != many, "Einzahl und Mehrzahl sollten sich unterscheiden")
	assert_true(one.contains("1"), "Die Einzahl-Form sollte die Zahl enthalten")
	assert_true(many.contains("5"), "Die Mehrzahl-Form sollte die Zahl enthalten")

	TranslationServer.set_locale(original)


func test_format_time_locale_pads_minutes() -> void:
	var original := AccessibilityManager.language
	AccessibilityManager.language = "en"

	var result := LocalizationManager.format_time_locale(65.0)
	assert_true(result.begins_with("01:"), "65s sollten als 01:05.00 formatiert werden, war: %s" % result)

	AccessibilityManager.language = original


func test_rtl_detection() -> void:
	assert_false(LocalizationManager.is_rtl_locale("de"), "Deutsch ist nicht RTL")
	assert_true(LocalizationManager.is_rtl_locale("ar"), "Arabisch ist RTL")
