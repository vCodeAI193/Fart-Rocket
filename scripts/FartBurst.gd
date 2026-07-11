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
@onready var _sparks: CPUParticles2D = $SparkParticles  # FR-267: Funken-Layer
@onready var _smoke: CPUParticles2D = $SmokeParticles    # FR-267: Rauch-Layer
@onready var _audio: AudioStreamPlayer = $FartSound


func _ready() -> void:
	# Falls im Editor ein Sound gesetzt wurde, diesen verwenden
	if fart_sound != null:
		_audio.stream = fart_sound
	# FR-293: Furz-Wolken-Verzerrungs-Shader für einen gasigen Wabber-Look
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/fart_distortion.gdshader")
	_particles.material = mat


## Startet die Partikel und den Sound. Räumt sich danach selbst auf.
## tint färbt die Wolke je nach Furz-Typ ein (FR-002).
## FR-267: Drei überlagerte Partikel-Layer (Kernwolke, Funken, Rauch-
## Nachzieher) statt einer einzelnen Partikelgruppe, für einen dichteren,
## dynamischeren Furz-Wolken-Look.
func erupt(tint: Color = Color.WHITE) -> void:
	modulate = tint
	_particles.emitting = true
	_sparks.emitting = true
	_smoke.emitting = true
	if _audio.stream != null:
		_audio.play()
	# Nach Ablauf der längsten Lebensdauer (Rauch-Layer) die Wolke entfernen
	var life := maxf(_particles.lifetime, maxf(_sparks.lifetime, _smoke.lifetime)) + 0.3
	await get_tree().create_timer(life).timeout
	queue_free()
