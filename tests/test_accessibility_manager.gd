extends TestCase
## Tests für AccessibilityManager (FR-421-440) — der Autoload wurde beim
## GameManager-Split herausgelöst und hatte bis dahin keine eigenen Tests.
## Schwerpunkt: Wertebereichs-Begrenzung der Setter und die
## Speicher-Rundreise über write_to_save()/read_from_save().


func test_menu_ui_scale_is_clamped() -> void:
	var original := AccessibilityManager.menu_ui_scale

	AccessibilityManager.set_menu_ui_scale(5.0)
	assert_eq(AccessibilityManager.menu_ui_scale, 1.3, "menu_ui_scale sollte bei 1.3 gedeckelt werden")

	AccessibilityManager.set_menu_ui_scale(0.1)
	assert_eq(AccessibilityManager.menu_ui_scale, 0.85, "menu_ui_scale sollte bei 0.85 begrenzt werden")

	AccessibilityManager.set_menu_ui_scale(original)


func test_screen_brightness_is_clamped() -> void:
	var original := AccessibilityManager.screen_brightness

	AccessibilityManager.set_screen_brightness(2.0)
	assert_eq(AccessibilityManager.screen_brightness, 1.0, "Helligkeit sollte bei 1.0 gedeckelt werden")

	AccessibilityManager.set_screen_brightness(0.0)
	assert_eq(AccessibilityManager.screen_brightness, 0.5, "Helligkeit sollte bei 0.5 begrenzt werden")

	AccessibilityManager.set_screen_brightness(original)


func test_set_language_rejects_unknown_codes() -> void:
	var original := AccessibilityManager.language

	AccessibilityManager.set_language("en")
	assert_eq(AccessibilityManager.language, "en", "Bekannte Sprache sollte übernommen werden")

	AccessibilityManager.set_language("klingonisch")
	assert_eq(AccessibilityManager.language, "en", "Unbekannte Sprache darf nichts ändern")

	AccessibilityManager.set_language(original)


func test_accessibility_changed_signal_fires_on_colorblind_change() -> void:
	var original := AccessibilityManager.colorblind_mode
	var fired := [false]
	var handler := func(): fired[0] = true
	AccessibilityManager.accessibility_changed.connect(handler)

	AccessibilityManager.set_colorblind_mode(AccessibilityManager.ColorblindMode.PROTANOPIA)
	assert_true(fired[0], "accessibility_changed sollte beim Moduswechsel ausgelöst werden")

	AccessibilityManager.accessibility_changed.disconnect(handler)
	AccessibilityManager.set_colorblind_mode(original)


func test_save_load_roundtrip_preserves_all_fields() -> void:
	var cfg := ConfigFile.new()
	var original_contrast := AccessibilityManager.high_contrast_enabled
	var original_fps := AccessibilityManager.fps_limit
	var original_lang := AccessibilityManager.language

	AccessibilityManager.high_contrast_enabled = true
	AccessibilityManager.fps_limit = 30
	AccessibilityManager.language = "fr"
	AccessibilityManager.write_to_save(cfg)

	# Werte verfälschen, dann aus der ConfigFile zurücklesen
	AccessibilityManager.high_contrast_enabled = false
	AccessibilityManager.fps_limit = 0
	AccessibilityManager.language = "de"
	AccessibilityManager.read_from_save(cfg)

	assert_true(AccessibilityManager.high_contrast_enabled, "high_contrast sollte erhalten bleiben")
	assert_eq(AccessibilityManager.fps_limit, 30, "fps_limit sollte erhalten bleiben")
	assert_eq(AccessibilityManager.language, "fr", "language sollte erhalten bleiben")

	AccessibilityManager.high_contrast_enabled = original_contrast
	AccessibilityManager.fps_limit = original_fps
	AccessibilityManager.language = original_lang


func test_reset_to_default_restores_factory_values() -> void:
	var original_lang := AccessibilityManager.language

	AccessibilityManager.high_contrast_enabled = true
	AccessibilityManager.menu_ui_scale = 1.3
	AccessibilityManager.language = "es"
	AccessibilityManager.reset_to_default()

	assert_false(AccessibilityManager.high_contrast_enabled, "high_contrast sollte zurückgesetzt sein")
	assert_eq(AccessibilityManager.menu_ui_scale, 1.0, "menu_ui_scale sollte auf 1.0 zurückgesetzt sein")
	assert_eq(AccessibilityManager.language, "de", "Sprache sollte auf 'de' zurückgesetzt sein")

	AccessibilityManager.language = original_lang
