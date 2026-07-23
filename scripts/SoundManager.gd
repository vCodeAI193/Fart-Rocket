extends Node
## SoundManager (Autoload / Singleton)
## =====================================
## FR-241/242/246/249/251/253/254/255/256: Prozedural erzeugte Hintergrund-
## musik (Menü/Level/Boss), Sieg-Fanfare, Countdown- und Combo-Sounds sowie
## ein zweiter Audio-Bus ("Music") für eine von der Gesamtlautstärke
## (GameManager.master_volume) getrennt regelbare Musik-Lautstärke.
##
## Keine externen Audio-Assets — alle Klänge werden wie die übrigen Sounds
## in GameManager.gd (_generate_click_tone()/_generate_fart_tone()) per
## Sinus-/Rechteck-/Dreieck-Synthese zur Laufzeit als AudioStreamWAV erzeugt
## und gecacht.
##
## Bewusst nicht Teil dieses Batches: FR-252 (echtes Positions-/3D-Audio —
## bei diesem Kamera-/Level-Design von begrenztem Nutzen) und FR-260
## (freischaltbare Soundpakete — eigenes Content-System für einen späteren
## Batch).

const MUSIC_BUS_NAME := "Music"
const STINGER_POOL_SIZE := 4

var music_volume: float = 0.8  # FR-249
var sound_muted: bool = false  # FR-250

var _music_bus_idx: int = -1
var _music_player_calm: AudioStreamPlayer
var _music_player_intense: AudioStreamPlayer
var _stinger_players: Array[AudioStreamPlayer] = []

var _current_track_id: String = ""
var _intensity_active: bool = false
var _intensity_tween: Tween
var _duck_tween: Tween

var _loop_cache: Dictionary = {}  # "<track_id>:<intense>" -> AudioStreamWAV
var _tone_cache: Dictionary = {}  # Schlüssel -> AudioStreamWAV (Einzeltöne/Fanfare)

# --- FR-165: Prozedurale Furz-Sound-Pakete -------------------------------
var _fart_sound_cache: Dictionary = {}  # pack_id -> AudioStreamWAV
var _fart_sound_players: Array[AudioStreamPlayer] = []
const FART_SOUND_POOL_SIZE := 3


func _ready() -> void:
	_ensure_music_bus()

	_music_player_calm = AudioStreamPlayer.new()
	_music_player_calm.bus = MUSIC_BUS_NAME
	add_child(_music_player_calm)

	_music_player_intense = AudioStreamPlayer.new()
	_music_player_intense.bus = MUSIC_BUS_NAME
	_music_player_intense.volume_db = -80.0
	add_child(_music_player_intense)

	apply_music_volume()

	GameManager.combo_changed.connect(_on_combo_changed)      # FR-254
	GameManager.charges_changed.connect(_on_charges_changed)  # FR-242


## Legt bei Bedarf einen eigenen "Music"-Bus an, der zum Master-Bus
## sendet — dadurch bleibt GameManager.master_volume weiterhin die
## Gesamtlautstärke, während music_volume nur die Musik relativ dazu
## regelt. Das Stummschalten des Master-Busses (apply_mute() unten)
## schaltet die Musik automatisch mit stumm, da sie letztlich über
## Master ausgegeben wird.
func _ensure_music_bus() -> void:
	_music_bus_idx = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if _music_bus_idx == -1:
		AudioServer.add_bus()
		_music_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_music_bus_idx, MUSIC_BUS_NAME)
		AudioServer.set_bus_send(_music_bus_idx, "Master")


## FR-249: Setzt die Musik-Lautstärke getrennt von der SFX-/Gesamtlautstärke.
func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	apply_music_volume()
	SaveManager.save_settings()


func apply_music_volume() -> void:
	# Lazy-Initialisierung: kann bereits vor SoundManager._ready() aus
	# SaveManager._load_settings() heraus aufgerufen werden (Autoload-
	# Ladereihenfolge garantiert nur Node-Existenz, nicht _ready()-
	# Reihenfolge zwischen Autoloads).
	if _music_bus_idx == -1:
		_ensure_music_bus()
	AudioServer.set_bus_volume_db(_music_bus_idx, linear_to_db(maxf(music_volume, 0.0001)))


# --- FR-250: Stummschaltung (Master-Bus) --------------------------------

func set_muted(muted: bool) -> void:
	sound_muted = muted
	apply_mute()
	SaveManager.save_settings()


func toggle_muted() -> void:
	set_muted(not sound_muted)


func apply_mute() -> void:
	# Master-Bus stummschalten (Index 0)
	AudioServer.set_bus_mute(0, sound_muted)


## Setzt Stummschaltung und Musik-Lautstärke auf ihre Werkseinstellung
## zurück. Wird von GameManager.reset_settings_to_default() aufgerufen.
func reset_to_default() -> void:
	sound_muted = false
	music_volume = 0.8
	apply_mute()
	apply_music_volume()


# --- Musik-Wiedergabe -------------------------------------------------

## FR-256: Menü-Musik.
func play_menu_music() -> void:
	_play_track("menu")


## FR-241: Level-Themen — wechselt je nach Level-Index zwischen zwei
## Motiven, damit nicht jedes Level exakt gleich klingt.
func play_level_music(level_index: int) -> void:
	_play_track("level_a" if level_index % 2 == 1 else "level_b")


## FR-255: Boss-Kampf-Musik.
func play_boss_music() -> void:
	_play_track("boss")


func stop_music() -> void:
	_current_track_id = ""
	_intensity_active = false
	_music_player_calm.stop()
	_music_player_intense.stop()


func _play_track(track_id: String) -> void:
	if track_id == _current_track_id and _music_player_calm.playing:
		return  # Bereits aktiv (z.B. erneutes Laden desselben Levels nach Tod) — nicht neu starten
	_current_track_id = track_id
	_intensity_active = false
	_music_player_calm.stream = _get_or_generate_loop(track_id, false)
	_music_player_intense.stream = _get_or_generate_loop(track_id, true)
	_music_player_calm.volume_db = 0.0
	_music_player_intense.volume_db = -80.0
	_music_player_calm.play()
	_music_player_intense.play()


## FR-242: Blendet zwischen der ruhigen und einer schnelleren/dichteren
## Variante desselben Themas über — beide Layer laufen synchron mit,
## nur die Lautstärke wird übergeblendet (kein Neustart/Knacken).
func set_danger_intensity(active: bool) -> void:
	if active == _intensity_active or _current_track_id == "":
		return
	_intensity_active = active
	if _intensity_tween and _intensity_tween.is_valid():
		_intensity_tween.kill()
	var calm_db := -24.0 if _intensity_active else 0.0
	var intense_db := 0.0 if _intensity_active else -80.0
	_intensity_tween = create_tween().set_parallel(true)
	_intensity_tween.tween_property(_music_player_calm, "volume_db", calm_db, 0.6)
	_intensity_tween.tween_property(_music_player_intense, "volume_db", intense_db, 0.6)


func _on_charges_changed(remaining: int) -> void:
	if GameManager.max_charges <= 0:
		return
	var ratio := float(remaining) / float(GameManager.max_charges)
	set_danger_intensity(ratio <= 0.34)


func _get_or_generate_loop(track_id: String, intense: bool) -> AudioStreamWAV:
	var key := "%s:%s" % [track_id, intense]
	if not _loop_cache.has(key):
		_loop_cache[key] = _generate_track_loop(track_id, intense)
	return _loop_cache[key]


## FR-241/255/256: Definiert die Notenfolge/Klangfarbe je Titel und
## erzeugt daraus einen nahtlos schleifenden Loop.
func _generate_track_loop(track_id: String, intense: bool) -> AudioStreamWAV:
	match track_id:
		"menu":
			return _generate_music_loop(
				[392.0, 440.0, 523.25, 440.0, 392.0, 329.63, 392.0, 440.0],
				0.28, "triangle", 0.22)
		"level_a":
			return _generate_music_loop(
				[261.63, 329.63, 392.0, 329.63, 261.63, 196.0, 261.63, 329.63],
				0.22, "square", 0.18, 1.5 if intense else 1.0)
		"level_b":
			return _generate_music_loop(
				[293.66, 349.23, 440.0, 349.23, 293.66, 220.0, 293.66, 349.23],
				0.22, "square", 0.18, 1.5 if intense else 1.0)
		"boss":
			return _generate_music_loop(
				[130.81, 130.81, 155.56, 130.81, 174.61, 130.81, 155.56, 98.0],
				0.18, "square", 0.24, 1.35 if intense else 1.0)
		_:
			return _generate_music_loop([440.0, 440.0], 0.3, "sine", 0.2)


## Erzeugt einen nahtlos schleifenden Arpeggio-Loop aus einer Notenfolge
## (Frequenzen in Hz). `tempo_scale` beschleunigt die Notendauer (>1.0 =
## schneller/dichter, für die "intense"-Variante bei Gefahr, FR-242).
## Kurze Ein-/Ausblendrampen an jeder Notengrenze vermeiden Knack-Artefakte.
func _generate_music_loop(notes: Array, note_duration: float, wave: String,
		volume: float, tempo_scale: float = 1.0, sample_rate: int = 22050) -> AudioStreamWAV:
	var actual_duration: float = note_duration / tempo_scale
	var samples_per_note := maxi(1, int(sample_rate * actual_duration))
	var total_samples := samples_per_note * notes.size()
	var data := PackedByteArray()
	data.resize(total_samples * 2)
	var fade_samples := mini(int(sample_rate * 0.008), samples_per_note / 4)
	for i in range(total_samples):
		var note_idx := mini(int(i / samples_per_note), notes.size() - 1)
		var freq: float = notes[note_idx]
		var local_i := i - note_idx * samples_per_note
		var t := float(i) / sample_rate
		var raw := _wave_sample(wave, freq, t)
		var envelope := 1.0
		if fade_samples > 0:
			if local_i < fade_samples:
				envelope = float(local_i) / fade_samples
			elif local_i > samples_per_note - fade_samples:
				envelope = float(samples_per_note - local_i) / fade_samples
		var sample := raw * envelope * volume
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_samples
	return stream


func _wave_sample(wave: String, freq: float, t: float) -> float:
	match wave:
		"square":
			return sign(sin(TAU * freq * t))
		"triangle":
			return asin(sin(TAU * freq * t)) * (2.0 / PI)
		_:
			return sin(TAU * freq * t)


# --- Kurze Effekt-Sounds (Fanfare/Countdown/Combo) --------------------

func _play_stinger(stream: AudioStreamWAV, pitch: float = 1.0) -> void:
	var player := _get_free_stinger_player()
	player.stream = stream
	player.pitch_scale = pitch
	player.play()


func _get_free_stinger_player() -> AudioStreamPlayer:
	for p in _stinger_players:
		if not p.playing:
			return p
	if _stinger_players.size() < STINGER_POOL_SIZE:
		var new_player := AudioStreamPlayer.new()
		new_player.bus = MUSIC_BUS_NAME
		add_child(new_player)
		_stinger_players.append(new_player)
		return new_player
	return _stinger_players[0]  # Pool voll: ältesten wiederverwenden


## FR-246: Sieg-Fanfare beim Levelabschluss (aufsteigender Dur-Dreiklang).
func play_victory_fanfare() -> void:
	_play_stinger(_get_or_generate_fanfare())


func _get_or_generate_fanfare() -> AudioStreamWAV:
	if not _tone_cache.has("fanfare"):
		_tone_cache["fanfare"] = _generate_fanfare()
	return _tone_cache["fanfare"]


func _generate_fanfare(sample_rate: int = 22050) -> AudioStreamWAV:
	var notes := [523.25, 659.25, 783.99, 1046.5]  # C-E-G-C, aufsteigend
	var note_duration := 0.14
	var samples_per_note := int(sample_rate * note_duration)
	var total_samples := samples_per_note * notes.size()
	var data := PackedByteArray()
	data.resize(total_samples * 2)
	var fade_samples := int(sample_rate * 0.01)
	for i in range(total_samples):
		var note_idx: int = mini(int(i / samples_per_note), notes.size() - 1)
		var freq: float = notes[note_idx]
		var local_i := i - note_idx * samples_per_note
		var t := float(i) / sample_rate
		var raw := sign(sin(TAU * freq * t))
		var envelope := 1.0
		if local_i < fade_samples:
			envelope = float(local_i) / fade_samples
		elif local_i > samples_per_note - fade_samples:
			envelope = float(samples_per_note - local_i) / fade_samples
		if note_idx == notes.size() - 1:
			envelope *= 1.0 - (float(local_i) / samples_per_note) * 0.3  # letzter Ton klingt aus
		var sample := raw * envelope * 0.35
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	return stream


## FR-253: Kurze, aufsteigende Zwei-Ton-Countdown-Sequenz beim Levelstart
## (rein akustisches "Bereit machen"-Signal, blockiert die Steuerung nicht).
func play_countdown() -> void:
	var low := _get_or_generate_tone("countdown_low", 440.0, 0.12)
	var high := _get_or_generate_tone("countdown_high", 660.0, 0.18)
	_play_stinger(low)
	if is_inside_tree():
		get_tree().create_timer(0.35).timeout.connect(func(): _play_stinger(low))
		get_tree().create_timer(0.70).timeout.connect(func(): _play_stinger(high))


## FR-254: Ton mit steigender Tonhöhe je Combo-Stufe (bis Stufe 10 gedeckelt).
func _on_combo_changed(count: int, multiplier: int) -> void:
	if count <= 0:
		return
	var step := mini(count, 10)
	var freq := 440.0 + float(step) * 40.0
	var tone := _get_or_generate_tone("combo_%d" % step, freq, 0.1)
	_play_stinger(tone, 1.0 + float(multiplier - 1) * 0.05)


func _get_or_generate_tone(key: String, frequency: float, duration: float) -> AudioStreamWAV:
	if not _tone_cache.has(key):
		_tone_cache[key] = _generate_tone(frequency, duration)
	return _tone_cache[key]


## Kurzer, ausklingender Sinuston — analog zu GameManager._generate_click_tone(),
## aber mit frei wählbarer Frequenz/Dauer für Countdown- und Combo-Sounds.
func _generate_tone(frequency: float, duration: float, sample_rate: int = 22050) -> AudioStreamWAV:
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / sample_rate
		var envelope := 1.0 - (float(i) / sample_count)
		var sample := sin(TAU * frequency * t) * envelope * 0.5
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	return stream


## FR-239: Spielt einen kurzen, prozedural erzeugten Klick-Ton für
## Menü-Interaktionen ab (Button-Hover/-Press, Tab-Wechsel etc.). Nutzt
## dieselbe Ton-/Stinger-Infrastruktur wie Countdown/Combo (kein separater
## Cache/Pool nötig).
func play_ui_click(pitch: float = 1.0) -> void:
	if sound_muted:
		return
	_play_stinger(_get_or_generate_tone("ui_click", 880.0, 0.08), pitch)


# --- FR-165: Prozedurale Furz-Sound-Pakete -------------------------------

## FR-165/257: Spielt einen prozedural erzeugten Furz-Sound passend zum
## ausgerüsteten Sound-Paket ab, moduliert durch die Stoßstärke.
func play_fart_sound(strength: float = 1.0) -> void:
	if sound_muted:
		return
	duck_for_sfx()  # FR-251: Musik kurz leiser für den Stoß
	var pack := CosmeticsManager.equipped_fart_sound
	if not _fart_sound_cache.has(pack):
		_fart_sound_cache[pack] = _generate_fart_tone(pack)
	var player := _get_free_fart_player()
	player.stream = _fart_sound_cache[pack]
	player.pitch_scale = clampf(0.8 + strength * 0.4, 0.6, 1.8)
	player.play()


func _get_free_fart_player() -> AudioStreamPlayer:
	for p in _fart_sound_players:
		if not p.playing:
			return p
	if _fart_sound_players.size() < FART_SOUND_POOL_SIZE:
		var new_player := AudioStreamPlayer.new()
		add_child(new_player)
		_fart_sound_players.append(new_player)
		return new_player
	return _fart_sound_players[0]


## FR-165: Erzeugt einen kurzen, "brummenden" Ton mit paket-abhängiger
## Grundfrequenz und Modulation — vollständig prozedural, kein Asset.
func _generate_fart_tone(pack: String) -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.35
	var base_freq := 110.0
	var wobble := 18.0
	match pack:
		"fartsound_deep":
			base_freq = 65.0
			wobble = 8.0
		"fartsound_squeaky":
			base_freq = 320.0
			wobble = 60.0
		"fartsound_robotic":
			base_freq = 150.0
			wobble = 0.0  # wird durch Bitcrush-Stufen ersetzt

	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / sample_rate
		var envelope := 1.0 - (float(i) / sample_count)
		var freq := base_freq + sin(t * 40.0) * wobble
		var raw := sin(TAU * freq * t)
		if pack == "fartsound_robotic":
			raw = sign(raw) * 0.6 + raw * 0.4  # grobe Rechteck-Beimischung
		var sample := raw * envelope * 0.6
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)

	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	return stream


## FR-251: Duckt die Musik kurz ab (z.B. wenn eine pointierte SFX wie ein
## Furz-Stoß spielt) und blendet danach sanft wieder auf die reguläre
## music_volume-Lautstärke zurück.
func duck_for_sfx(duration: float = 0.18, amount_db: float = -6.0) -> void:
	if _music_bus_idx == -1:
		return
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	var base_db := linear_to_db(maxf(music_volume, 0.0001))
	AudioServer.set_bus_volume_db(_music_bus_idx, base_db + amount_db)
	_duck_tween = create_tween()
	_duck_tween.tween_interval(duration)
	_duck_tween.tween_method(
		func(db: float): AudioServer.set_bus_volume_db(_music_bus_idx, db),
		base_db + amount_db, base_db, 0.25)
