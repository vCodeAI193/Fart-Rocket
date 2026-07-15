extends TestCase
## Tests für SoundManager: Lautstärke-Regelung (FR-249) und den
## Musik-Bus, den SoundManager beim ersten Zugriff selbst anlegt.

func test_music_bus_exists_after_apply_music_volume() -> void:
	SoundManager.apply_music_volume()
	assert_true(AudioServer.get_bus_index("Music") != -1, "Music-Bus sollte angelegt worden sein")


func test_set_music_volume_clamps_to_valid_range() -> void:
	var original := SoundManager.music_volume

	SoundManager.set_music_volume(1.5)
	assert_eq(SoundManager.music_volume, 1.0, "music_volume sollte auf 1.0 begrenzt werden")

	SoundManager.set_music_volume(-0.5)
	assert_eq(SoundManager.music_volume, 0.0, "music_volume sollte auf 0.0 begrenzt werden")

	SoundManager.set_music_volume(original)


func test_set_music_volume_updates_bus_volume() -> void:
	var original := SoundManager.music_volume

	SoundManager.set_music_volume(0.5)
	var bus_idx := AudioServer.get_bus_index("Music")
	var expected_db := linear_to_db(0.5)
	assert_almost_eq(AudioServer.get_bus_volume_db(bus_idx), expected_db, 0.01, "Music-Bus-Lautstärke sollte music_volume widerspiegeln")

	SoundManager.set_music_volume(original)


func test_danger_intensity_is_noop_without_active_track() -> void:
	SoundManager.stop_music()
	# Sollte nicht abstürzen, auch wenn kein Titel aktiv ist (kein
	# Crossfade-Ziel vorhanden).
	SoundManager.set_danger_intensity(true)
	assert_true(true, "set_danger_intensity() ohne aktiven Titel darf nicht fehlschlagen")
