extends Node2D
class_name FartBurst
## FartBurst – die Furz-Wolke
## ==========================
## Eine kurzlebige grüne Partikelwolke samt Furz-Sound.
## Wird vom Player bei jedem Furz-Stoß instanziiert und entfernt
## sich nach Ablauf der Animation selbst.

# Platzhalter-Sound: hier kann im Editor ein eigener Furz-Sound
# als AudioStream eingehängt werden (export-Variable).
@export var fart_sound: AudioStream

@onready var _particles: CPUParticles2D = $Particles
@onready var _audio: AudioStreamPlayer = $FartSound


func _ready() -> void:
	# Falls im Editor ein Sound gesetzt wurde, diesen verwenden
	if fart_sound != null:
		_audio.stream = fart_sound


## Startet die Partikel und den Sound. Räumt sich danach selbst auf.
func erupt() -> void:
	_particles.emitting = true
	if _audio.stream != null:
		_audio.play()
	# Nach Ablauf der Lebensdauer die Wolke entfernen
	var life := _particles.lifetime + 0.3
	await get_tree().create_timer(life).timeout
	queue_free()
