extends TestCase
## Konsistenz-Tests der Level-Konfiguration. Beim Hinzufügen von Leveln
## müssen mehrere über das Projekt verteilte Stellen synchron erweitert
## werden — genau dort ist in diesem Projekt schon einmal ein Fehler
## entstanden (Boss-Rush sprang nach dem Hinzufügen von Level4-7 in ein
## bossloses Level). Diese Tests fangen solche Lücken künftig ab.


func test_level_scenes_count_matches_total_levels() -> void:
	assert_eq(GameManager.LEVEL_SCENES.size(), GameManager.TOTAL_LEVELS,
		"LEVEL_SCENES muss genau TOTAL_LEVELS Einträge haben")


func test_all_level_scenes_exist() -> void:
	for path in GameManager.LEVEL_SCENES:
		assert_true(ResourceLoader.exists(path),
			"Level-Szene fehlt oder ist nicht ladbar: %s" % path)


func test_level_stars_has_an_entry_per_level() -> void:
	assert_eq(GameManager.level_stars.size(), GameManager.TOTAL_LEVELS,
		"level_stars muss je Level einen Eintrag haben")
	for lvl in range(1, GameManager.TOTAL_LEVELS + 1):
		assert_true(GameManager.level_stars.has(lvl),
			"level_stars fehlt der Eintrag für Level %d" % lvl)


func test_time_attack_best_times_has_an_entry_per_level() -> void:
	for lvl in range(1, GameManager.TOTAL_LEVELS + 1):
		assert_true(GameModeManager.time_attack_best_times.has(lvl),
			"time_attack_best_times fehlt der Eintrag für Level %d" % lvl)


func test_level_titles_cover_every_level() -> void:
	# F17: Die Start-Einblendung braucht je Level einen Beinamen.
	for lvl in range(1, GameManager.TOTAL_LEVELS + 1):
		assert_true(GameManager.get_level_title(lvl) != "",
			"Level %d hat keinen Titel in LEVEL_TITLES" % lvl)


func test_get_level_scene_path_clamps_out_of_range() -> void:
	# Defensives Verhalten: außerhalb liegende Indizes dürfen nicht
	# abstürzen, sondern liefern das erste bzw. letzte Level.
	assert_eq(GameManager.get_level_scene_path(0), GameManager.LEVEL_SCENES[0],
		"Index 0 sollte auf das erste Level begrenzt werden")
	assert_eq(GameManager.get_level_scene_path(999),
		GameManager.LEVEL_SCENES[GameManager.TOTAL_LEVELS - 1],
		"Zu große Indizes sollten auf das letzte Level begrenzt werden")


func test_has_next_level_is_false_on_last_level() -> void:
	var original := GameManager.current_level

	GameManager.current_level = GameManager.TOTAL_LEVELS
	assert_false(GameManager.has_next_level(), "Im letzten Level gibt es kein nächstes")

	GameManager.current_level = 1
	assert_true(GameManager.has_next_level(), "Nach Level 1 sollte es weitergehen")

	GameManager.current_level = original
