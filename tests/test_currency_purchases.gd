extends TestCase
## Tests für die Kosmetik-Kauf-/Freischalt-Logik in CosmeticsManager
## (unlock_cosmetic kostet Guthaben, grant_cosmetic_free ist kostenlos).
## Nutzt "hat_top" (200) / "hat_cap" (150) / "hat_crown" (achievement_only,
## cost 0) aus CosmeticsManager.COSMETIC_CATALOG.

func test_unlock_cosmetic_fails_with_insufficient_funds() -> void:
	var original_coins := GameManager.persistent_coins
	var was_unlocked := "hat_top" in CosmeticsManager.unlocked_cosmetics
	if was_unlocked:
		CosmeticsManager.unlocked_cosmetics.erase("hat_top")

	GameManager.persistent_coins = 0
	var result := CosmeticsManager.unlock_cosmetic("hat_top")

	assert_false(result, "Freischaltung sollte bei 0 Münzen fehlschlagen")
	assert_false("hat_top" in CosmeticsManager.unlocked_cosmetics, "hat_top sollte nicht freigeschaltet sein")

	GameManager.persistent_coins = original_coins
	if was_unlocked and not ("hat_top" in CosmeticsManager.unlocked_cosmetics):
		CosmeticsManager.unlocked_cosmetics.append("hat_top")


func test_unlock_cosmetic_succeeds_and_deducts_cost() -> void:
	var original_coins := GameManager.persistent_coins
	var was_unlocked := "hat_cap" in CosmeticsManager.unlocked_cosmetics
	if was_unlocked:
		CosmeticsManager.unlocked_cosmetics.erase("hat_cap")

	GameManager.persistent_coins = 1000
	var result := CosmeticsManager.unlock_cosmetic("hat_cap")  # Kosten: 150

	assert_true(result, "Freischaltung sollte mit genug Guthaben gelingen")
	assert_eq(GameManager.persistent_coins, 850, "Kosten (150) sollten vom Guthaben abgezogen werden")
	assert_true("hat_cap" in CosmeticsManager.unlocked_cosmetics, "hat_cap sollte jetzt freigeschaltet sein")

	GameManager.persistent_coins = original_coins
	if not was_unlocked:
		CosmeticsManager.unlocked_cosmetics.erase("hat_cap")


func test_grant_cosmetic_free_does_not_deduct_coins() -> void:
	var original_coins := GameManager.persistent_coins
	var was_unlocked := "hat_crown" in CosmeticsManager.unlocked_cosmetics
	if was_unlocked:
		CosmeticsManager.unlocked_cosmetics.erase("hat_crown")

	GameManager.persistent_coins = 0
	CosmeticsManager.grant_cosmetic_free("hat_crown")

	assert_eq(GameManager.persistent_coins, 0, "grant_cosmetic_free darf keine Münzen abziehen")
	assert_true("hat_crown" in CosmeticsManager.unlocked_cosmetics, "hat_crown sollte freigeschaltet sein")

	GameManager.persistent_coins = original_coins
	if not was_unlocked:
		CosmeticsManager.unlocked_cosmetics.erase("hat_crown")


func test_unlock_cosmetic_is_idempotent_when_already_owned() -> void:
	var original_coins := GameManager.persistent_coins
	var was_unlocked := "hat_shades" in CosmeticsManager.unlocked_cosmetics
	if not was_unlocked:
		CosmeticsManager.unlocked_cosmetics.append("hat_shades")

	GameManager.persistent_coins = 0  # zu wenig für einen echten Kauf
	var result := CosmeticsManager.unlock_cosmetic("hat_shades")

	assert_true(result, "Bereits besessene Items gelten als erfolgreich freigeschaltet")
	assert_eq(GameManager.persistent_coins, 0, "Bereits besessene Items dürfen kein Guthaben abziehen")

	GameManager.persistent_coins = original_coins
	if not was_unlocked:
		CosmeticsManager.unlocked_cosmetics.erase("hat_shades")
