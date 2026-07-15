extends Node
class_name TestCase
## TestCase – Basisklasse für das leichtgewichtige, projekteigene
## Test-Framework (tests/TestMain.gd findet und führt alle Skripte, die
## davon erben, automatisch aus).
##
## Kein GUT/GdUnit: der Sandbox-Zugriff für dieses Projekt ist auf genau
## dieses GitHub-Repository beschränkt, daher lässt sich ein
## Drittanbieter-Addon (Dutzende Dateien) nicht zuverlässig herunterladen
## und ohne lokale Godot-Ausführung nicht verifizieren. Dieses schlanke,
## selbst geschriebene Framework deckt genau das ab, was für diese
## Testsuite gebraucht wird (Gleichheits-/Wahrheits-Assertions), bleibt
## dabei aber vollständig überprüfbar.

var _failures: Array[String] = []
var _assertion_count: int = 0


func get_failures() -> Array[String]:
	return _failures


func get_assertion_count() -> int:
	return _assertion_count


func assert_eq(actual, expected, message: String = "") -> void:
	_assertion_count += 1
	if actual != expected:
		_failures.append("assert_eq fehlgeschlagen%s: erwartet=%s, tatsächlich=%s" % [
			(" (%s)" % message) if message != "" else "", str(expected), str(actual)
		])


func assert_true(condition: bool, message: String = "") -> void:
	_assertion_count += 1
	if not condition:
		_failures.append("assert_true fehlgeschlagen%s" % ((" (%s)" % message) if message != "" else ""))


func assert_false(condition: bool, message: String = "") -> void:
	_assertion_count += 1
	if condition:
		_failures.append("assert_false fehlgeschlagen%s" % ((" (%s)" % message) if message != "" else ""))


func assert_almost_eq(actual: float, expected: float, tolerance: float, message: String = "") -> void:
	_assertion_count += 1
	if absf(actual - expected) > tolerance:
		_failures.append("assert_almost_eq fehlgeschlagen%s: erwartet≈%s, tatsächlich=%s" % [
			(" (%s)" % message) if message != "" else "", str(expected), str(actual)
		])


func assert_gt(actual, threshold, message: String = "") -> void:
	_assertion_count += 1
	if not (actual > threshold):
		_failures.append("assert_gt fehlgeschlagen%s: %s ist nicht > %s" % [
			(" (%s)" % message) if message != "" else "", str(actual), str(threshold)
		])
