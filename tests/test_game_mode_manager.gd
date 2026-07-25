extends TestCase
## Tests für GameModeManager (FR-341-360) — beim GameManager-Split
## herausgelöst, bis dahin ohne eigene Tests. Deckt insbesondere die
## Boss-Rush-Level-Auswahl ab, die zuvor fälschlich auf TOTAL_LEVELS zeigte
## und dadurch im bosslosen Bonus-Level landete.


func test_boss_rush_starts_at_first_boss_level() -> void:
	var original_mode := GameModeManager.active_game_mode
	var original_level := GameManager.current_level

	GameModeManager.set_game_mode(GameModeManager.GameMode.BOSS_RUSH)

	assert_eq(GameManager.current_level, GameManager.BOSS_LEVEL_INDICES[0],
		"Boss-Rush sollte beim ersten Boss-Level starten")
	assert_eq(GameModeManager.boss_rush_index, 0, "Boss-Rush-Index sollte bei 0 beginnen")

	GameModeManager.set_game_mode(original_mode)
	GameManager.current_level = original_level


func test_boss_level_indices_all_point_at_real_levels() -> void:
	assert_gt(GameManager.BOSS_LEVEL_INDICES.size(), 0, "Es sollte mindestens ein Boss-Level geben")
	for idx in GameManager.BOSS_LEVEL_INDICES:
		assert_true(idx >= 1 and idx <= GameManager.TOTAL_LEVELS,
			"Boss-Level-Index %d muss innerhalb von 1..TOTAL_LEVELS liegen" % idx)


func test_advance_boss_rush_walks_through_all_boss_levels() -> void:
	var original_mode := GameModeManager.active_game_mode
	var original_level := GameManager.current_level

	GameModeManager.set_game_mode(GameModeManager.GameMode.BOSS_RUSH)
	# Von Index 0 aus so oft weiterschalten, wie es weitere Boss-Level gibt
	for i in range(1, GameManager.BOSS_LEVEL_INDICES.size()):
		assert_true(GameModeManager.advance_boss_rush(),
			"advance_boss_rush() sollte auf Boss-Level %d weiterschalten" % i)
		assert_eq(GameManager.current_level, GameManager.BOSS_LEVEL_INDICES[i],
			"Nach dem Weiterschalten sollte Boss-Level %d aktiv sein" % i)
	# Ein weiterer Aufruf muss das Modus-Ende signalisieren
	assert_false(GameModeManager.advance_boss_rush(),
		"Nach dem letzten Boss-Level sollte advance_boss_rush() false liefern")

	GameModeManager.set_game_mode(original_mode)
	GameManager.current_level = original_level


func test_time_attack_mode_flag_follows_active_mode() -> void:
	var original_mode := GameModeManager.active_game_mode

	GameModeManager.set_game_mode(GameModeManager.GameMode.TIME_ATTACK)
	assert_true(GameModeManager.time_attack_mode, "time_attack_mode sollte im Zeitrennen aktiv sein")

	GameModeManager.set_game_mode(GameModeManager.GameMode.NORMAL)
	assert_false(GameModeManager.time_attack_mode, "time_attack_mode sollte sonst inaktiv sein")

	GameModeManager.set_game_mode(original_mode)


func test_record_time_attack_only_accepts_improvements() -> void:
	var test_level := GameManager.TOTAL_LEVELS
	var original := GameModeManager.time_attack_best_times.get(test_level, INF)

	GameModeManager.time_attack_best_times[test_level] = INF
	assert_true(GameModeManager.record_time_attack(test_level, 10.0),
		"Erste Zeit sollte immer als Bestzeit gelten")
	assert_true(GameModeManager.record_time_attack(test_level, 8.0),
		"Schnellere Zeit sollte als neue Bestzeit gelten")
	assert_false(GameModeManager.record_time_attack(test_level, 12.0),
		"Langsamere Zeit darf die Bestzeit nicht überschreiben")
	assert_eq(GameModeManager.get_best_time(test_level), 8.0,
		"Die Bestzeit sollte die schnellste bleiben")

	GameModeManager.time_attack_best_times[test_level] = original


func test_ghost_path_roundtrip() -> void:
	var test_level := GameManager.TOTAL_LEVELS
	var path := PackedVector2Array([Vector2(0, 0), Vector2(10, 5), Vector2(20, 15)])

	GameModeManager.store_ghost_path(test_level, path)
	var loaded := GameModeManager.get_ghost_path(test_level)

	assert_eq(loaded.size(), 3, "Der gespeicherte Geister-Pfad sollte 3 Punkte haben")
	assert_eq(loaded[1], Vector2(10, 5), "Der mittlere Punkt sollte unverändert sein")

	GameModeManager.ghost_paths.erase(test_level)


func test_save_load_roundtrip_preserves_mode_bests() -> void:
	var cfg := ConfigFile.new()
	var original_loops := GameModeManager.endless_best_loops
	var original_survival := GameModeManager.survival_best_time

	GameModeManager.endless_best_loops = 7
	GameModeManager.survival_best_time = 42.5
	GameModeManager.write_to_save(cfg)

	GameModeManager.endless_best_loops = 0
	GameModeManager.survival_best_time = 0.0
	GameModeManager.read_from_save(cfg)

	assert_eq(GameModeManager.endless_best_loops, 7, "endless_best_loops sollte erhalten bleiben")
	assert_almost_eq(GameModeManager.survival_best_time, 42.5, 0.01,
		"survival_best_time sollte erhalten bleiben")

	GameModeManager.endless_best_loops = original_loops
	GameModeManager.survival_best_time = original_survival
