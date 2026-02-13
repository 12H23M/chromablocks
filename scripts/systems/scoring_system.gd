class_name ScoringSystem

## Returns: {placement, line_clear, color_match, perfect_clear, combo_multiplier, dual_clear_multiplier, total}
static func calculate(cell_count: int, clear_result: Dictionary,
		color_result: Dictionary, combo: int, _level: int) -> Dictionary:
	# 1. Placement
	var placement := cell_count * GameConstants.PLACEMENT_POINTS_PER_CELL

	# 2. Line clear
	var line_clear := GameConstants.line_clear_score(clear_result.get("lines_cleared", 0))

	# 3. Color match
	var color_match := 0
	for group in color_result.get("groups", []):
		color_match += GameConstants.color_match_score(group.size())

	# 4. Perfect clear
	var perfect_clear: int = GameConstants.PERFECT_CLEAR_BONUS if clear_result.get("is_perfect", false) else 0

	# 5. Combo multiplier
	var combo_idx := clampi(combo, 0, GameConstants.COMBO_MULTIPLIERS.size() - 1)
	var multiplier: float = GameConstants.COMBO_MULTIPLIERS[combo_idx]

	# 6. Dual clear bonus: x1.25 when BOTH line clear and color match occur
	var dual_clear_multiplier := 1.25 if (line_clear > 0 and color_match > 0) else 1.0

	# 7. Total (placement is not affected by combo or dual clear)
	var bonus := roundi((line_clear + color_match + perfect_clear) * multiplier * dual_clear_multiplier)
	var total := placement + bonus

	return {
		"placement": placement,
		"line_clear": line_clear,
		"color_match": color_match,
		"perfect_clear": perfect_clear,
		"combo_multiplier": multiplier,
		"dual_clear_multiplier": dual_clear_multiplier,
		"total": total,
	}
