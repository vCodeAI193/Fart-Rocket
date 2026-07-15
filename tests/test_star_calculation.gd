extends TestCase
## Tests für GameManager.calculate_stars() (Sternebewertung anhand
## übrig gebliebener Furz-Ladungen).

func test_three_stars_when_half_or_more_charges_remain() -> void:
	GameManager.charges_remaining = 5
	assert_eq(GameManager.calculate_stars(10), 3, "5/10 verbleibende Ladungen -> 3 Sterne")


func test_two_stars_when_some_but_less_than_half_remain() -> void:
	GameManager.charges_remaining = 1
	assert_eq(GameManager.calculate_stars(10), 2, "1/10 verbleibende Ladung -> 2 Sterne")


func test_one_star_when_no_charges_remain() -> void:
	GameManager.charges_remaining = 0
	assert_eq(GameManager.calculate_stars(10), 1, "0 verbleibende Ladungen -> 1 Stern")


func test_one_star_when_max_charges_is_zero() -> void:
	assert_eq(GameManager.calculate_stars(0), 1, "max_charges=0 -> defensiv 1 Stern")


func test_exactly_half_charges_counts_as_three_stars() -> void:
	GameManager.charges_remaining = 5
	assert_eq(GameManager.calculate_stars(10), 3, "Genau 50% verbleibend -> 3 Sterne (Grenzfall)")
