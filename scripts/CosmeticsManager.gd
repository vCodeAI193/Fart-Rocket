extends Node
## CosmeticsManager (Autoload / Singleton)
## =====================================
## FR-161/163-180/224/334: Kosmetik-Katalog, Freischaltung, Ausrüstung
## (Mix&Match) und Skin-Farben. Ausgelagert aus GameManager.gd im Rahmen
## des "God Object"-Refactorings (siehe README.md), damit GameManager.gd
## sich auf Kern-Level-/Sitzungs-Zustand konzentrieren kann.
##
## Persistenz: CosmeticsManager besitzt hier keine eigene Speicher-Datei-
## Logik — SaveManager.gd ruft write_to_save()/read_from_save()/
## reset_to_default() auf, damit das Speicherformat (ConfigFile-Abschnitt
## "cosmetics") unverändert bleibt. Das dauerhafte Guthaben
## (persistent_coins) bleibt bewusst in GameManager.gd, da es kein
## Kosmetik-Konzept ist, sondern die allgemeine Menü-/Shop-Währung.

# --- FR-224: Shop / freischaltbare Skin-Farben -----------------------
var unlocked_skin_colors: Array[String] = ["default"]
var active_skin_color: String = "default"

# --- FR-180: Eigener Farb-Editor für den Standard-Skin -----------------
var custom_skin_color: Color = Color(0.95, 0.95, 0.95)


## FR-180: Setzt eine frei gewählte Skin-Farbe und rüstet sie sofort aus.
func set_custom_skin_color(color: Color) -> void:
	custom_skin_color = color
	active_skin_color = "custom"
	SaveManager.save_now()

# --- FR-161/163/166/167/175/176: Kosmetik-Ausrüstung (Mix&Match, FR-179) --
signal cosmetics_changed

var equipped_helmet: String = "helmet_none"
var equipped_outfit: String = "outfit_none"
var equipped_hat: String = "hat_none"
var equipped_face: String = "neutral"       # FR-167
var equipped_arrow_style: String = "arrow_classic"  # FR-175
var equipped_death_anim: String = "death_spin"      # FR-176
var equipped_victory_pose: String = "pose_wave"     # FR-177
var equipped_fart_color_style: String = "fart_classic"  # FR-164
var equipped_fart_sound: String = "fartsound_classic"    # FR-165

# FR-170: Seltenheitsstufen (beeinflussen Preis/Optik im Shop)
enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

# id -> {name, slot, cost, rarity, unlocked_by_default}
const COSMETIC_CATALOG := {
	"helmet_none": {"name": "Kein Helm", "slot": "helmet", "cost": 0, "rarity": Rarity.COMMON},
	"helmet_visor": {"name": "Visier-Helm", "slot": "helmet", "cost": 150, "rarity": Rarity.COMMON},
	"helmet_viking": {"name": "Wikinger-Hörner", "slot": "helmet", "cost": 350, "rarity": Rarity.RARE},
	"helmet_mohawk": {"name": "Iro-Helm", "slot": "helmet", "cost": 350, "rarity": Rarity.RARE},
	"helmet_crown": {"name": "Krone", "slot": "helmet", "cost": 900, "rarity": Rarity.LEGENDARY},

	"outfit_none": {"name": "Kein Anzug", "slot": "outfit", "cost": 0, "rarity": Rarity.COMMON},
	"outfit_astronaut": {"name": "Astronaut", "slot": "outfit", "cost": 400, "rarity": Rarity.RARE},
	"outfit_hero": {"name": "Superheld", "slot": "outfit", "cost": 400, "rarity": Rarity.RARE},
	"outfit_animal": {"name": "Tier-Kostüm", "slot": "outfit", "cost": 400, "rarity": Rarity.RARE},

	"hat_none": {"name": "Kein Hut", "slot": "hat", "cost": 0, "rarity": Rarity.COMMON},
	"hat_top": {"name": "Zylinder", "slot": "hat", "cost": 200, "rarity": Rarity.COMMON},
	"hat_cap": {"name": "Käppi", "slot": "hat", "cost": 150, "rarity": Rarity.COMMON},
	"hat_shades": {"name": "Sonnenbrille", "slot": "hat", "cost": 250, "rarity": Rarity.RARE},
	# FR-334: Nicht im Shop kaufbar — nur als Erfolgs-Belohnung für
	# "Sternensammler" per grant_cosmetic_free() (siehe "achievement_only").
	"hat_crown": {"name": "Krone", "slot": "hat", "cost": 0, "rarity": Rarity.LEGENDARY, "achievement_only": true},

	"arrow_classic": {"name": "Klassisch", "slot": "arrow", "cost": 0, "rarity": Rarity.COMMON},
	"arrow_neon": {"name": "Neon", "slot": "arrow", "cost": 200, "rarity": Rarity.COMMON},
	"arrow_rainbow": {"name": "Regenbogen", "slot": "arrow", "cost": 500, "rarity": Rarity.EPIC},

	"death_spin": {"name": "Taumeln", "slot": "death", "cost": 0, "rarity": Rarity.COMMON},
	"death_confetti": {"name": "Konfetti-Explosion", "slot": "death", "cost": 300, "rarity": Rarity.RARE},
	"death_ghost": {"name": "Geist-Verblassen", "slot": "death", "cost": 300, "rarity": Rarity.RARE},

	"pose_wave": {"name": "Winken", "slot": "pose", "cost": 0, "rarity": Rarity.COMMON},
	"pose_flex": {"name": "Muskeln zeigen", "slot": "pose", "cost": 250, "rarity": Rarity.RARE},
	"pose_dance": {"name": "Freuden-Tanz", "slot": "pose", "cost": 250, "rarity": Rarity.RARE},

	"fart_classic": {"name": "Klassisch", "slot": "fartcolor", "cost": 0, "rarity": Rarity.COMMON},
	"fart_toxic": {"name": "Toxisch-Grün", "slot": "fartcolor", "cost": 200, "rarity": Rarity.COMMON},
	"fart_rainbow": {"name": "Regenbogen", "slot": "fartcolor", "cost": 500, "rarity": Rarity.EPIC},

	"fartsound_classic": {"name": "Klassisch", "slot": "fartsound", "cost": 0, "rarity": Rarity.COMMON},
	"fartsound_deep": {"name": "Basslastig", "slot": "fartsound", "cost": 200, "rarity": Rarity.COMMON},
	"fartsound_squeaky": {"name": "Quietschig", "slot": "fartsound", "cost": 200, "rarity": Rarity.COMMON},
	"fartsound_robotic": {"name": "Robotisch", "slot": "fartsound", "cost": 400, "rarity": Rarity.RARE},
}

var unlocked_cosmetics: Array[String] = [
	"helmet_none", "outfit_none", "hat_none", "arrow_classic",
	"death_spin", "pose_wave", "fart_classic", "fartsound_classic",
]

# FR-172: Saisonale Skins — nur in bestimmten Monaten kaufbar
const SEASONAL_COSMETICS := {
	"helmet_viking": [12, 1],  # Winter (Dez/Jan)
	"hat_top": [10, 11],       # Herbst (Okt/Nov)
}

# FR-174: Skin-des-Tages — täglich rotierender Gratis-Skin
var daily_skin_claimed_date: String = ""


## FR-169/170: Schaltet ein Kosmetik-Item per Guthaben frei.
func unlock_cosmetic(id: String) -> bool:
	if id in unlocked_cosmetics:
		return true
	var info: Dictionary = COSMETIC_CATALOG.get(id, {})
	if info.is_empty():
		return false
	var cost: int = info["cost"]
	if GameManager.persistent_coins < cost:
		return false
	GameManager.persistent_coins -= cost
	GameManager.persistent_coins_changed.emit(GameManager.persistent_coins)
	unlocked_cosmetics.append(id)
	SaveManager.save_now()
	return true


## FR-334: Schaltet ein Kosmetik-Item kostenlos frei (z.B. als
## Erfolgs-Belohnung) — im Gegensatz zu unlock_cosmetic() ohne Kaufpreis.
func grant_cosmetic_free(id: String) -> void:
	if id in unlocked_cosmetics:
		return
	unlocked_cosmetics.append(id)
	SaveManager.save_now()


## FR-179: Rüstet ein Kosmetik-Item in seinem Slot aus (Mix&Match).
func equip_cosmetic(id: String) -> void:
	if not id in unlocked_cosmetics:
		return
	var info: Dictionary = COSMETIC_CATALOG.get(id, {})
	if info.is_empty():
		return
	match info["slot"]:
		"helmet": equipped_helmet = id
		"outfit": equipped_outfit = id
		"hat": equipped_hat = id
		"arrow": equipped_arrow_style = id
		"death": equipped_death_anim = id
		"pose": equipped_victory_pose = id
		"fartcolor": equipped_fart_color_style = id
		"fartsound": equipped_fart_sound = id
	cosmetics_changed.emit()
	SaveManager.save_now()


## FR-172: Prüft, ob ein saisonales Kosmetik-Item aktuell verfügbar ist.
func is_cosmetic_seasonally_available(id: String) -> bool:
	if not SEASONAL_COSMETICS.has(id):
		return true
	var current_month := Time.get_date_dict_from_system()["month"]
	return current_month in SEASONAL_COSMETICS[id]


## FR-174: Skin-des-Tages — liefert eine deterministische, täglich
## wechselnde Auswahl aus dem Katalog und schaltet sie beim Abholen frei.
func get_daily_skin_id() -> String:
	var pool := COSMETIC_CATALOG.keys().filter(func(id): return COSMETIC_CATALOG[id]["cost"] > 0)
	if pool.is_empty():
		return ""
	var day_seed := int(Time.get_unix_time_from_system() / 86400.0)
	return pool[day_seed % pool.size()]


func is_daily_skin_available() -> bool:
	return daily_skin_claimed_date != Time.get_date_string_from_system()


## FR-174: Schaltet den heutigen Skin-des-Tages kostenlos frei.
func claim_daily_skin() -> bool:
	if not is_daily_skin_available():
		return false
	var id := get_daily_skin_id()
	if id == "" or id in unlocked_cosmetics:
		daily_skin_claimed_date = Time.get_date_string_from_system()
		SaveManager.save_now()
		return false
	unlocked_cosmetics.append(id)
	daily_skin_claimed_date = Time.get_date_string_from_system()
	SaveManager.save_now()
	return true


## FR-178: Fortschritt der Kosmetik-Sammlung (freigeschaltet / gesamt).
func get_cosmetics_collection_progress() -> Vector2i:
	return Vector2i(unlocked_cosmetics.size(), COSMETIC_CATALOG.size())


## FR-224: Schaltet eine Skin-Farbe per dauerhaftem Guthaben frei.
func unlock_skin_color(id: String, cost: int) -> bool:
	if id in unlocked_skin_colors:
		return true
	if GameManager.persistent_coins < cost:
		return false
	GameManager.persistent_coins -= cost
	GameManager.persistent_coins_changed.emit(GameManager.persistent_coins)
	unlocked_skin_colors.append(id)
	SaveManager.save_now()
	return true


# --- Persistenz-Schnittstelle für SaveManager.gd ------------------------

## Schreibt alle Kosmetik-Felder in die übergebene ConfigFile — Abschnitte/
## Schlüssel exakt wie zuvor in GameManager._save_progress(), damit
## bestehende Spielstände kompatibel bleiben. Wird von
## SaveManager._save_progress() aufgerufen.
func write_to_save(cfg: ConfigFile) -> void:
	cfg.set_value("shop", "unlocked_skins", unlocked_skin_colors)  # FR-224
	cfg.set_value("shop", "active_skin", active_skin_color)  # FR-224
	cfg.set_value("shop", "custom_skin_color", custom_skin_color)  # FR-180
	cfg.set_value("cosmetics", "unlocked", unlocked_cosmetics)
	cfg.set_value("cosmetics", "helmet", equipped_helmet)
	cfg.set_value("cosmetics", "outfit", equipped_outfit)
	cfg.set_value("cosmetics", "hat", equipped_hat)
	cfg.set_value("cosmetics", "arrow", equipped_arrow_style)
	cfg.set_value("cosmetics", "death", equipped_death_anim)
	cfg.set_value("cosmetics", "pose", equipped_victory_pose)
	cfg.set_value("cosmetics", "fartcolor", equipped_fart_color_style)
	cfg.set_value("cosmetics", "fartsound", equipped_fart_sound)
	cfg.set_value("cosmetics", "daily_claimed_date", daily_skin_claimed_date)


## Liest alle Kosmetik-Felder aus der ConfigFile — Abschnitte/Schlüssel
## exakt wie zuvor in GameManager._load_progress(). Wird von
## SaveManager._load_progress() aufgerufen.
func read_from_save(cfg: ConfigFile) -> void:
	var saved_skins: Array = cfg.get_value("shop", "unlocked_skins", ["default"])  # FR-224
	unlocked_skin_colors.assign(saved_skins)
	active_skin_color = cfg.get_value("shop", "active_skin", "default")  # FR-224
	custom_skin_color = cfg.get_value("shop", "custom_skin_color", Color(0.95, 0.95, 0.95))  # FR-180
	var saved_cosmetics: Array = cfg.get_value("cosmetics", "unlocked", unlocked_cosmetics)
	unlocked_cosmetics.assign(saved_cosmetics)
	equipped_helmet = cfg.get_value("cosmetics", "helmet", "helmet_none")
	equipped_outfit = cfg.get_value("cosmetics", "outfit", "outfit_none")
	equipped_hat = cfg.get_value("cosmetics", "hat", "hat_none")
	equipped_arrow_style = cfg.get_value("cosmetics", "arrow", "arrow_classic")
	equipped_death_anim = cfg.get_value("cosmetics", "death", "death_spin")
	equipped_victory_pose = cfg.get_value("cosmetics", "pose", "pose_wave")
	equipped_fart_color_style = cfg.get_value("cosmetics", "fartcolor", "fart_classic")
	equipped_fart_sound = cfg.get_value("cosmetics", "fartsound", "fartsound_classic")
	daily_skin_claimed_date = cfg.get_value("cosmetics", "daily_claimed_date", "")


## Setzt alle Kosmetik-Felder auf ihre Werkseinstellung zurück. Wird von
## SaveManager._reset_progress_vars_to_default() aufgerufen (z.B. beim
## Wechsel auf einen leeren Speicherplatz oder "Fortschritt löschen").
func reset_to_default() -> void:
	unlocked_skin_colors = ["default"]
	active_skin_color = "default"
	custom_skin_color = Color(0.95, 0.95, 0.95)
	equipped_helmet = "helmet_none"
	equipped_outfit = "outfit_none"
	equipped_hat = "hat_none"
	equipped_face = "neutral"
	equipped_arrow_style = "arrow_classic"
	equipped_death_anim = "death_spin"
	equipped_victory_pose = "pose_wave"
	equipped_fart_color_style = "fart_classic"
	equipped_fart_sound = "fartsound_classic"
	unlocked_cosmetics = [
		"helmet_none", "outfit_none", "hat_none", "arrow_classic",
		"death_spin", "pose_wave", "fart_classic", "fartsound_classic",
	]
	daily_skin_claimed_date = ""
