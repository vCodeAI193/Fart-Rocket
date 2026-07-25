extends TestCase
## Tests für die gemeinsamen UI-Fabrikfunktionen (UIHelpers.gd). Sie
## erzeugen die UI von sechs Bildschirmen — ein Fehler dort schlägt
## überall gleichzeitig durch.


func test_make_label_sets_text_and_parents_node() -> void:
	var parent := Node2D.new()
	add_child(parent)

	var label := UIHelpers.make_label(parent, "Testtext", 30)

	assert_eq(label.text, "Testtext", "Der Text sollte gesetzt werden")
	assert_eq(label.get_parent(), parent, "Das Label sollte am Elternknoten hängen")
	assert_eq(label.get_theme_font_size("font_size"), 30, "Die Schriftgröße sollte gesetzt werden")

	parent.queue_free()


func test_make_label_applies_color_only_when_given() -> void:
	var parent := Node2D.new()
	add_child(parent)

	var plain := UIHelpers.make_label(parent, "Ohne Farbe", 24)
	var colored := UIHelpers.make_label(parent, "Mit Farbe", 24, Color(1, 0, 0))

	assert_false(plain.has_theme_color_override("font_color"),
		"Ohne Farbangabe sollte kein Farb-Override gesetzt werden")
	assert_true(colored.has_theme_color_override("font_color"),
		"Mit Farbangabe sollte ein Farb-Override gesetzt werden")

	parent.queue_free()


func test_make_title_label_is_centered() -> void:
	var parent := Node2D.new()
	add_child(parent)

	var title := UIHelpers.make_title_label(parent, "Überschrift")

	assert_eq(title.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER,
		"Überschriften sollten zentriert sein")
	assert_eq(title.text, "Überschrift", "Der Titeltext sollte gesetzt werden")

	parent.queue_free()


func test_make_button_wires_callback_and_size() -> void:
	var parent := Node2D.new()
	add_child(parent)
	var pressed := [false]

	var btn := UIHelpers.make_button(parent, func(): pressed[0] = true,
		Vector2(300, 50), 20, "Klick mich")

	assert_eq(btn.text, "Klick mich", "Der Buttontext sollte gesetzt werden")
	assert_eq(btn.custom_minimum_size, Vector2(300, 50), "Die Mindestgröße sollte gesetzt werden")
	assert_eq(btn.get_parent(), parent, "Der Button sollte am Elternknoten hängen")

	btn.pressed.emit()
	assert_true(pressed[0], "Der übergebene Callback sollte beim Drücken laufen")

	parent.queue_free()


func test_style_button_applies_size_without_reparenting() -> void:
	var btn := Button.new()

	UIHelpers.style_button(btn, Vector2(220, 64), 26)

	assert_eq(btn.custom_minimum_size, Vector2(220, 64), "Die Mindestgröße sollte gesetzt werden")
	assert_eq(btn.get_theme_font_size("font_size"), 26, "Die Schriftgröße sollte gesetzt werden")
	assert_eq(btn.get_parent(), null, "style_button() darf den Button nicht einhängen")

	btn.queue_free()


func test_make_close_button_invokes_callback() -> void:
	var parent := Node2D.new()
	add_child(parent)
	var closed := [false]

	var btn := UIHelpers.make_close_button(parent, func(): closed[0] = true)
	btn.pressed.emit()

	assert_true(closed[0], "Der Schließen-Callback sollte laufen")
	assert_eq(btn.get_parent(), parent, "Der Schließen-Button sollte am Elternknoten hängen")

	parent.queue_free()
