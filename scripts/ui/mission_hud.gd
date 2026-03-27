extends VBoxContainer
## In-game mission progress HUD — shows 3 small progress bars during mission run.

var _fredoka_bold: Font = null
var _rows: Array = []  # Array of {label: Label, bar: Control, progress_label: Label, mission: Mission}
var _missions: Array = []


func _ready() -> void:
	_fredoka_bold = load("res://assets/fonts/Fredoka-Bold.ttf") as Font
	set("theme_override_constants/separation", 4)
	visible = false


func setup(missions: Array) -> void:
	_missions = missions
	_clear()
	for m in missions:
		var mission: MissionSystem.Mission = m
		var row := _build_row(mission)
		_rows.append(row)
	visible = true
	_refresh()


func refresh() -> void:
	_refresh()


func _refresh() -> void:
	for i in range(_rows.size()):
		if i >= _missions.size():
			break
		var mission: MissionSystem.Mission = _missions[i]
		var row: Dictionary = _rows[i]
		var bar: MissionProgressBar = row["bar"]
		var prog_label: Label = row["progress_label"]
		var icon_label: Label = row["icon"]

		var frac: float = 0.0
		if mission.target > 0:
			frac = clampf(float(mission.progress) / float(mission.target), 0.0, 1.0)
		bar.set_progress(frac, mission.completed)
		prog_label.text = "%d/%d" % [mission.progress, mission.target]

		if mission.completed:
			icon_label.text = "✓"
			icon_label.add_theme_color_override("font_color", Color("#4CAF50"))
			prog_label.add_theme_color_override("font_color", Color("#4CAF50"))
		else:
			icon_label.text = "●"
			icon_label.add_theme_color_override("font_color", Color("#2196F3"))


## Flash a single mission row when it completes (green pulse).
func flash_row(index: int) -> void:
	if index < 0 or index >= _rows.size():
		return
	var row: Dictionary = _rows[index]
	var hbox: HBoxContainer = row["hbox"]
	var tw := hbox.create_tween()
	tw.set_loops(2)
	tw.tween_property(hbox, "modulate", Color(0.5, 1.0, 0.6, 1.0), 0.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(hbox, "modulate", Color(1, 1, 1, 1), 0.15).set_ease(Tween.EASE_IN)


func hide_hud() -> void:
	visible = false
	_clear()


func _clear() -> void:
	for child in get_children():
		child.queue_free()
	_rows.clear()


func _build_row(mission: MissionSystem.Mission) -> Dictionary:
	var hbox := HBoxContainer.new()
	hbox.set("theme_override_constants/separation", 6)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(hbox)

	# Icon
	var icon := Label.new()
	icon.text = "●"
	icon.add_theme_font_size_override("font_size", 10)
	icon.add_theme_color_override("font_color", Color("#2196F3"))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon)

	# Description
	var desc := Label.new()
	desc.text = mission.description
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color("#C8C0E0"))
	if _fredoka_bold:
		desc.add_theme_font_override("font", _fredoka_bold)
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(desc)

	# Progress bar
	var bar := MissionProgressBar.new()
	bar.custom_minimum_size = Vector2(60, 8)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(bar)

	# Progress text
	var prog := Label.new()
	prog.text = "%d/%d" % [mission.progress, mission.target]
	prog.add_theme_font_size_override("font_size", 11)
	prog.add_theme_color_override("font_color", Color("#A0A0C0"))
	prog.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prog.custom_minimum_size = Vector2(36, 0)
	hbox.add_child(prog)

	return {"hbox": hbox, "icon": icon, "desc": desc, "bar": bar, "progress_label": prog}


## Small progress bar for mission tracking
class MissionProgressBar extends Control:
	var _progress: float = 0.0
	var _completed: bool = false

	func set_progress(value: float, completed: bool = false) -> void:
		_progress = clampf(value, 0.0, 1.0)
		_completed = completed
		queue_redraw()

	func _draw() -> void:
		var bar_h: float = size.y
		var r: float = bar_h / 2.0

		# Background track
		var bg_col := Color(1, 1, 1, 0.08)
		_draw_rounded_rect(0.0, 0.0, size.x, bar_h, r, bg_col)

		# Fill
		if _progress > 0.01:
			var fill_w: float = size.x * _progress
			var fill_col: Color
			if _completed:
				fill_col = Color("#4CAF50")
			else:
				fill_col = Color("#2196F3")
			_draw_rounded_rect(0.0, 0.0, fill_w, bar_h, r, fill_col)

	func _draw_rounded_rect(x: float, y: float, w: float, h: float, r: float, c: Color) -> void:
		if w < 0.5:
			return
		var cr: float = minf(r, w / 2.0)
		draw_rect(Rect2(x + cr, y, w - cr * 2.0, h), c)
		draw_rect(Rect2(x, y + cr, w, h - cr * 2.0), c)
		draw_circle(Vector2(x + cr, y + cr), cr, c)
		draw_circle(Vector2(x + w - cr, y + cr), cr, c)
		draw_circle(Vector2(x + cr, y + h - cr), cr, c)
		draw_circle(Vector2(x + w - cr, y + h - cr), cr, c)
