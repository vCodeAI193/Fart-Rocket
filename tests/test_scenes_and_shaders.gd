extends TestCase
## Lade-Tests für Szenen und Shader.
##
## Hintergrund: Die bisherige Testsuite prüfte ausschließlich Autoload-Logik.
## Dabei blieb unbemerkt, dass mehrere Objekt-Skripte gar nicht mehr
## kompilierten und zwei Shader wegen eines "return" im fragment()-Prozessor
## überhaupt nicht liefen — das Spiel selbst startete also nicht, obwohl alle
## Tests grün waren. Diese Tests schließen genau diese Lücke: sie laden jede
## Szene des Projekts (und damit transitiv jedes daran hängende Skript) und
## prüfen jeden Shader auf die Konstrukte, die Godot im Fragment-Prozessor
## verbietet.

const SHADER_DIR := "res://shaders"
## Prozessor-Funktionen, in denen Godot kein "return" erlaubt.
const SHADER_PROCESSORS := ["vertex", "fragment", "light"]


func test_all_scenes_load_and_instantiate() -> void:
	var scenes := _collect("res://", ".tscn")
	assert_gt(scenes.size(), 0, "Es sollten Szenen gefunden werden")
	for path in scenes:
		var packed: PackedScene = load(path)
		assert_true(packed != null, "Szene lässt sich nicht laden: %s" % path)
		if packed == null:
			continue
		var instance := packed.instantiate()
		assert_true(instance != null, "Szene lässt sich nicht instanziieren: %s" % path)
		if instance != null:
			instance.free()


func test_all_level_scenes_from_game_manager_exist() -> void:
	assert_eq(GameManager.LEVEL_SCENES.size(), GameManager.TOTAL_LEVELS,
		"LEVEL_SCENES sollte genau TOTAL_LEVELS Einträge haben")
	for level_index in range(1, GameManager.TOTAL_LEVELS + 1):
		var path := GameManager.get_level_scene_path(level_index)
		assert_true(ResourceLoader.exists(path),
			"Level-Szene %d fehlt: %s" % [level_index, path])


func test_all_shaders_load() -> void:
	var shaders := _collect(SHADER_DIR, ".gdshader")
	assert_gt(shaders.size(), 0, "Es sollten Shader gefunden werden")
	for path in shaders:
		var shader: Shader = load(path)
		assert_true(shader != null, "Shader lässt sich nicht laden: %s" % path)


## Ein "return" im vertex()/fragment()/light()-Prozessor ist in Godot-Shadern
## verboten und lässt den kompletten Shader fehlschlagen — sichtbar nur als
## Laufzeit-Meldung, nicht beim Laden. Deshalb hier statisch geprüft.
func test_no_return_in_shader_processor_functions() -> void:
	var shaders := _collect(SHADER_DIR, ".gdshader")
	for path in shaders:
		var source := FileAccess.get_file_as_string(path)
		assert_true(source != "", "Shader-Quelltext ist leer: %s" % path)
		for processor in SHADER_PROCESSORS:
			var offending := _find_return_in_processor(source, processor)
			assert_eq(offending, -1,
				"'return' in %s() von %s (Zeile %d) — in Godot-Shadern verboten"
					% [processor, path.get_file(), offending + 1])


## Liefert den 0-basierten Zeilenindex eines "return" im angegebenen
## Prozessor-Block oder -1, wenn keiner vorkommt. Die Prozessor-Funktionen
## stehen in diesen Shadern immer auf oberster Ebene, ihr Rumpf endet also
## bei der ersten schließenden Klammer in Spalte 0.
func _find_return_in_processor(source: String, processor: String) -> int:
	var lines := source.split("\n")
	var inside := false
	for i in range(lines.size()):
		var line: String = lines[i]
		if not inside:
			if line.begins_with("void %s(" % processor):
				inside = true
			continue
		if line.begins_with("}"):
			return -1
		if line.strip_edges().begins_with("return"):
			return i
	return -1


## Sammelt rekursiv alle Dateien mit der angegebenen Endung. Versteckte
## Verzeichnisse (insbesondere ".godot") werden übersprungen.
func _collect(dir_path: String, extension: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var full_path := dir_path.path_join(entry)
		if dir.current_is_dir():
			result.append_array(_collect(full_path, extension))
		elif entry.ends_with(extension):
			result.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result
