class_name DifficultySystem


static func calculate_level(total_lines_cleared: int) -> int:
	var level := 1
	var remaining := total_lines_cleared
	var needed := GameConstants.lines_for_next_level(level)
	while remaining >= needed:
		remaining -= needed
		level += 1
		needed = GameConstants.lines_for_next_level(level)
	return level
