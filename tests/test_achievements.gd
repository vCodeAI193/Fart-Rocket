extends TestCase
## Tests für AchievementManager.report_level_complete() — die
## Bedingungen für die Herausforderungs-Erfolge (Pazifist, Speedrun,
## Sparfuchs, Perfekt-Lauf).

func _reset(id: String) -> void:
	if id in AchievementManager.unlocked:
		AchievementManager.unlocked.erase(id)


func test_pacifist_run_unlocks_with_zero_coins() -> void:
	_reset("pacifist_run")
	AchievementManager.report_level_complete(1, 0, 5, 90.0, false)
	assert_true(AchievementManager.is_unlocked("pacifist_run"), "0 gesammelte Münzen sollten den Pazifist-Erfolg freischalten")


func test_pacifist_run_does_not_unlock_with_coins_collected() -> void:
	_reset("pacifist_run")
	AchievementManager.report_level_complete(1, 3, 5, 90.0, false)
	assert_false(AchievementManager.is_unlocked("pacifist_run"), "Gesammelte Münzen sollten den Pazifist-Erfolg verhindern")


func test_speedrun_unlocks_under_30_seconds() -> void:
	_reset("speedrun_30")
	AchievementManager.report_level_complete(1, 5, 5, 25.0, false)
	assert_true(AchievementManager.is_unlocked("speedrun_30"), "Unter 30s sollte den Speedrun-Erfolg freischalten")


func test_speedrun_does_not_unlock_at_31_seconds() -> void:
	_reset("speedrun_30")
	AchievementManager.report_level_complete(1, 5, 5, 31.0, false)
	assert_false(AchievementManager.is_unlocked("speedrun_30"), "31s sollte den Speedrun-Erfolg NICHT freischalten")


func test_frugal_farts_unlocks_with_three_or_fewer() -> void:
	_reset("frugal_farts")
	AchievementManager.report_level_complete(1, 5, 3, 90.0, false)
	assert_true(AchievementManager.is_unlocked("frugal_farts"), "3 Furz-Stöße sollten den Sparfuchs-Erfolg freischalten")


func test_frugal_farts_does_not_unlock_with_four() -> void:
	_reset("frugal_farts")
	AchievementManager.report_level_complete(1, 5, 4, 90.0, false)
	assert_false(AchievementManager.is_unlocked("frugal_farts"), "4 Furz-Stöße sollten den Sparfuchs-Erfolg NICHT freischalten")


func test_perfect_run_requires_three_stars_and_no_hit() -> void:
	_reset("perfect_run")
	AchievementManager.report_level_complete(3, 5, 5, 90.0, false)
	assert_true(AchievementManager.is_unlocked("perfect_run"), "3 Sterne ohne Schild-Verlust sollten den Perfekt-Lauf-Erfolg freischalten")


func test_perfect_run_fails_when_hit_taken() -> void:
	_reset("perfect_run")
	AchievementManager.report_level_complete(3, 5, 5, 90.0, true)
	assert_false(AchievementManager.is_unlocked("perfect_run"), "Bei Schild-Verlust sollte kein Perfekt-Lauf-Erfolg vergeben werden")


func test_perfect_run_fails_with_fewer_than_three_stars() -> void:
	_reset("perfect_run")
	AchievementManager.report_level_complete(2, 5, 5, 90.0, false)
	assert_false(AchievementManager.is_unlocked("perfect_run"), "Weniger als 3 Sterne sollten keinen Perfekt-Lauf-Erfolg vergeben")
