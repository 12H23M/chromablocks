class_name FormatUtils

static func format_number(value: int) -> String:
	if value >= 1000:
		var s := str(value)
		var result := ""
		var count := 0
		for i in range(s.length() - 1, -1, -1):
			if count > 0 and count % 3 == 0:
				result = "," + result
			result = s[i] + result
			count += 1
		return result
	return str(value)
