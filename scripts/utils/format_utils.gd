class_name FormatUtils

static func format_number(value: int) -> String:
	var abs_val: int = absi(value)
	if abs_val >= 1000:
		var s := str(abs_val)
		var result := ""
		var count := 0
		for i in range(s.length() - 1, -1, -1):
			if count > 0 and count % 3 == 0:
				result = "," + result
			result = s[i] + result
			count += 1
		if value < 0:
			return "-" + result
		return result
	return str(value)
