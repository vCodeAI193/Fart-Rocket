extends TestCase
## Integritäts-Tests des Kosmetik-Katalogs. Der Katalog wird von
## ShopScreen, Player-Rendering und AchievementManager gleichzeitig
## gelesen — ein fehlendes Feld oder ein ungültiger Slot fällt sonst erst
## im laufenden Spiel auf.

const REQUIRED_FIELDS := ["name", "slot", "cost", "rarity"]
const VALID_SLOTS := ["helmet", "outfit", "hat", "arrow", "death", "pose",
	"fartcolor", "fartsound"]


func test_every_catalog_entry_has_required_fields() -> void:
	for id in CosmeticsManager.COSMETIC_CATALOG.keys():
		var info: Dictionary = CosmeticsManager.COSMETIC_CATALOG[id]
		for field in REQUIRED_FIELDS:
			assert_true(info.has(field),
				"Kosmetik '%s' fehlt das Feld '%s'" % [id, field])


func test_every_catalog_entry_uses_a_known_slot() -> void:
	for id in CosmeticsManager.COSMETIC_CATALOG.keys():
		var slot: String = CosmeticsManager.COSMETIC_CATALOG[id]["slot"]
		assert_true(slot in VALID_SLOTS,
			"Kosmetik '%s' nutzt den unbekannten Slot '%s'" % [id, slot])


func test_costs_are_never_negative() -> void:
	for id in CosmeticsManager.COSMETIC_CATALOG.keys():
		var cost: int = CosmeticsManager.COSMETIC_CATALOG[id]["cost"]
		assert_true(cost >= 0, "Kosmetik '%s' hat negative Kosten (%d)" % [id, cost])


func test_default_unlocked_items_exist_in_catalog() -> void:
	# reset_to_default() setzt eine feste Startausstattung — jedes dieser
	# Items muss es auch wirklich im Katalog geben.
	for id in CosmeticsManager.unlocked_cosmetics:
		assert_true(CosmeticsManager.COSMETIC_CATALOG.has(id),
			"Standard-freigeschaltetes '%s' fehlt im Katalog" % id)


func test_every_slot_has_a_free_default_option() -> void:
	# Jeder Slot braucht mindestens einen kostenlosen Eintrag, sonst wäre
	# er zu Spielbeginn nicht befüllbar.
	var free_slots := {}
	for id in CosmeticsManager.COSMETIC_CATALOG.keys():
		var info: Dictionary = CosmeticsManager.COSMETIC_CATALOG[id]
		if int(info["cost"]) == 0 and not info.get("achievement_only", false):
			free_slots[info["slot"]] = true
	for slot in VALID_SLOTS:
		assert_true(free_slots.has(slot),
			"Slot '%s' hat keine kostenlose Standard-Option" % slot)


func test_seasonal_entries_reference_real_cosmetics() -> void:
	for id in CosmeticsManager.SEASONAL_COSMETICS.keys():
		assert_true(CosmeticsManager.COSMETIC_CATALOG.has(id),
			"Saisonales '%s' fehlt im Katalog" % id)
		var months: Array = CosmeticsManager.SEASONAL_COSMETICS[id]
		for m in months:
			assert_true(int(m) >= 1 and int(m) <= 12,
				"Saisonales '%s' nennt den ungültigen Monat %s" % [id, str(m)])


func test_equip_cosmetic_ignores_unowned_items() -> void:
	var original := CosmeticsManager.equipped_hat
	var was_owned := "hat_crown" in CosmeticsManager.unlocked_cosmetics
	if was_owned:
		CosmeticsManager.unlocked_cosmetics.erase("hat_crown")

	CosmeticsManager.equip_cosmetic("hat_crown")
	assert_eq(CosmeticsManager.equipped_hat, original,
		"Ein nicht besessenes Item darf nicht ausgerüstet werden")

	if was_owned:
		CosmeticsManager.unlocked_cosmetics.append("hat_crown")
	CosmeticsManager.equipped_hat = original


func test_save_load_roundtrip_preserves_equipment() -> void:
	var cfg := ConfigFile.new()
	var original_hat := CosmeticsManager.equipped_hat
	var original_date := CosmeticsManager.daily_skin_claimed_date

	CosmeticsManager.equipped_hat = "hat_cap"
	CosmeticsManager.daily_skin_claimed_date = "2026-01-01"
	CosmeticsManager.write_to_save(cfg)

	CosmeticsManager.equipped_hat = "hat_none"
	CosmeticsManager.daily_skin_claimed_date = ""
	CosmeticsManager.read_from_save(cfg)

	assert_eq(CosmeticsManager.equipped_hat, "hat_cap", "Ausgerüsteter Hut sollte erhalten bleiben")
	assert_eq(CosmeticsManager.daily_skin_claimed_date, "2026-01-01",
		"Abhol-Datum des Tages-Skins sollte erhalten bleiben")

	CosmeticsManager.equipped_hat = original_hat
	CosmeticsManager.daily_skin_claimed_date = original_date
