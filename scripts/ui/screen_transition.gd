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


## Full-screen fade through black transition.
## Phase 1: fade to black. Phase 2: call on_mid callback. Phase 3: fade from black.
static func fade_through_black(tree: SceneTree, on_mid: Callable, duration: float = 0.8) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	tree.root.add_child(layer)

	var overlay := ColorRect.new()
	overlay.color = Color.BLACK
	overlay.modulate.a = 0.0
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(overlay)

	var fade_in_dur: float = duration * 0.4
	var hold_dur: float = duration * 0.1
	var fade_out_dur: float = duration * 0.5

	var tween := overlay.create_tween()
	tween.set_speed_scale(1.0 / maxf(Engine.time_scale, 0.001))
	# Phase 1: fade to black
	tween.tween_property(overlay, "modulate:a", 1.0, fade_in_dur) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# Phase 2: hold + callback
	tween.tween_interval(hold_dur)
	tween.tween_callback(on_mid)
	# Phase 3: fade from black
	tween.tween_property(overlay, "modulate:a", 0.0, fade_out_dur) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Cleanup
	tween.tween_callback(layer.queue_free)
