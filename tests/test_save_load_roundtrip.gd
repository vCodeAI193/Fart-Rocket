extends TestCase
## Tests für das Speichersystem: Speichern+Laden-Rundreise und
## automatische Wiederherstellung bei einer beschädigten Primärdatei.
##
## Nutzt bewusst den letzten Speicherplatz (GameManager.SAVE_SLOT_COUNT)
## als dedizierten Test-Slot und räumt ihn nach jedem Test wieder auf
## (delete_save_slot) — in der CI läuft das gegen einen frischen,
## leeren user://-Ordner, es gibt also keine echten Spielerdaten, die
## dabei überschrieben werden könnten.

var _original_slot: int
var _test_slot: int


func _before_each() -> void:
	_original_slot = GameManager.current_save_slot
	_test_slot = GameManager.SAVE_SLOT_COUNT


func _after_each() -> void:
	GameManager.delete_save_slot(_test_slot)
	GameManager.switch_save_slot(_original_slot)


func test_save_and_load_preserves_persistent_coins() -> void:
	_before_each()

	GameManager.switch_save_slot(_test_slot)
	GameManager.persistent_coins = 12345
	GameManager.save_now()

	# Weg vom Test-Slot und zurück -> erzwingt ein echtes Neuladen von der Disk
	GameManager.switch_save_slot(1)
	GameManager.switch_save_slot(_test_slot)

	assert_eq(GameManager.persistent_coins, 12345, "persistent_coins sollte nach Speichern+Laden erhalten bleiben")

	_after_each()


func test_save_and_load_preserves_level_stars() -> void:
	_before_each()

	GameManager.switch_save_slot(_test_slot)
	GameManager.level_stars[1] = 3
	GameManager.level_stars[2] = 2
	GameManager.save_now()

	GameManager.switch_save_slot(1)
	GameManager.switch_save_slot(_test_slot)

	assert_eq(GameManager.level_stars.get(1, 0), 3, "Sterne für Level 1 sollten erhalten bleiben")
	assert_eq(GameManager.level_stars.get(2, 0), 2, "Sterne für Level 2 sollten erhalten bleiben")

	_after_each()


func test_empty_new_slot_does_not_leak_previous_slot_data() -> void:
	_before_each()

	# Slot 1 (oder der aktuelle) bekommt einen unverwechselbaren Wert
	GameManager.switch_save_slot(1)
	GameManager.persistent_coins = 999999
	GameManager.save_now()

	# Sicherstellen, dass der Test-Slot vorher leer ist
	GameManager.delete_save_slot(_test_slot)
	GameManager.switch_save_slot(_test_slot)

	assert_false(GameManager.persistent_coins == 999999, "Ein leerer neuer Slot darf nicht die Daten des vorherigen Slots übernehmen")

	_after_each()


func test_corrupted_save_falls_back_to_backup() -> void:
	_before_each()

	GameManager.switch_save_slot(_test_slot)
	GameManager.persistent_coins = 777
	GameManager.save_now()  # legt dabei automatisch ein Backup an

	# Primärdatei absichtlich mit ungültigen Daten überschreiben (simulierte Korruption)
	var save_path := GameManager.get_save_path()
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	f.store_string("KORRUPTE TESTDATEN, KEIN GUELTIGES CONFIGFILE")
	f.close()

	GameManager.persistent_coins = 0
	GameManager.load_now()

	assert_eq(GameManager.persistent_coins, 777, "Bei korrupter Primärdatei sollte automatisch das letzte Backup geladen werden")

	_after_each()
