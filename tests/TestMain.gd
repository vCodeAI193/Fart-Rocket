extends Node
## TestMain – Test-Runner-Einstiegspunkt.
## ==========================================
## Wird headless über die CI ausgeführt:
##   godot --headless --path . res://tests/TestMain.tscn
## Findet alle tests/test_*.gd-Dateien, instanziiert sie (sie erben von
## TestCase), ruft jede Methode mit dem Präfix "test_" auf und beendet
## den Prozess mit Exit-Code 0 (alle bestanden) oder 1 (mindestens ein
## Fehlschlag) — genau der Exit-Code, den eine CI-Pipeline braucht.

const TEST_DIR := "res://tests/"


func _ready() -> void:
	var test_scripts := _discover_test_scripts()
	var total_assertions := 0
	var total_failures: Array[String] = []
	var suites_run := 0

	for script_path in test_scripts:
		var script: GDScript = load(script_path)
		var instance: TestCase = script.new()
		add_child(instance)

		var test_method_names := _find_test_methods(instance)
		for method_name in test_method_names:
			instance.callv(method_name, [])
			suites_run += 1

		total_assertions += instance.get_assertion_count()
		for failure in instance.get_failures():
			total_failures.append("[%s] %s" % [script_path.get_file(), failure])

		instance.queue_free()

	print("--- Testergebnis --------------------------------------")
	print("Test-Funktionen ausgeführt: %d" % suites_run)
	print("Assertions geprüft: %d" % total_assertions)
	if total_failures.is_empty():
		print("Alle Tests bestanden.")
		print("---------------------------------------------------------")
		get_tree().quit(0)
	else:
		print("%d Fehlschlag/Fehlschläge:" % total_failures.size())
		for f in total_failures:
			print("  - %s" % f)
		print("---------------------------------------------------------")
		get_tree().quit(1)


## Findet alle tests/test_*.gd-Dateien (TestCase.gd und TestMain.gd
## selbst ausgenommen).
func _discover_test_scripts() -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		push_error("Test-Verzeichnis nicht lesbar: %s" % TEST_DIR)
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with("test_") and file_name.ends_with(".gd"):
			result.append(TEST_DIR + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result


## Reflektiert über die Methoden eines Testskripts und liefert alle,
## die mit "test_" beginnen (Godots get_method_list() gibt auch geerbte
## Engine-Methoden zurück — die werden hier herausgefiltert, da sie
## nicht mit "test_" beginnen).
func _find_test_methods(instance: Object) -> Array[String]:
	var names: Array[String] = []
	for method_info in instance.get_method_list():
		var m_name: String = method_info["name"]
		if m_name.begins_with("test_"):
			names.append(m_name)
	names.sort()
	return names
