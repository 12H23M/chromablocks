class_name ScreenTransition
## Static utility class for smooth screen transition animations.
## Replaces jarring visible = true/false toggling with animated fades and slides.


## Fade in a Control node (sets visible, animates alpha 0→1).
static func fade_in(node: Control, duration: float = 0.25) -> Tween:
	node.modulate.a = 0.0
	node.visible = true
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUAD)
	return tween


## Fade out a Control node (animates alpha 1→0, then hides).
static func fade_out(node: Control, duration: float = 0.2) -> Tween:
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration) \
		.set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func() -> void:
		node.visible = false
		node.modulate.a = 1.0
	)
	return tween


## Slide up + fade in (for overlay screens like game over, pause).
## Content slides from +offset below its original position upward while fading in.
static func slide_up_in(node: Control, duration: float = 0.3, offset: float = 40.0) -> Tween:
	var original_y := node.position.y
	node.modulate.a = 0.0
	node.position.y = original_y + offset
	node.visible = true
	var tween := node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, duration) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(node, "position:y", original_y, duration) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BACK)
	return tween


## Slide down + fade out (reverse of slide_up_in).
## Content slides downward by offset while fading out, then hides.
static func slide_down_out(node: Control, duration: float = 0.2, offset: float = 40.0) -> Tween:
	var target_y := node.position.y + offset
	var original_y := node.position.y
	var tween := node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", 0.0, duration) \
		.set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(node, "position:y", target_y, duration) \
		.set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(func() -> void:
		node.visible = false
		node.modulate.a = 1.0
		node.position.y = original_y
	)
	return tween
