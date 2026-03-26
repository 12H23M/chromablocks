# ChromaBlocks Performance Profile

**Date:** 2026-03-27  
**Device:** Samsung Galaxy (R3CX40SKG7Z) — 1080×2340, Vulkan (Skia pipeline)  
**Engine:** Godot 4.x  
**Build:** Release APK

---

## 1. Runtime Measurements (ADB Profiling)

### 1.1 Frame Rendering (gfxinfo)

| Metric | Value | Status |
|--------|-------|--------|
| Total frames rendered | 43 | — |
| Janky frames | 3 (6.98%) | ✅ Good (<16%) |
| Janky frames (legacy) | 5 (11.63%) | ⚠️ Acceptable |
| 50th percentile | 5ms | ✅ Excellent |
| 90th percentile | 10ms | ✅ Good |
| 95th percentile | 17ms | ✅ Within 16.67ms budget |
| 99th percentile | 32ms | ⚠️ Occasional spikes |
| Missed Vsync | 0 | ✅ Perfect |
| Slow UI thread | 1 | ✅ Negligible |
| Frame deadline missed | 3 | ⚠️ Minor |

**GPU Percentiles:**
- 50th: 1ms ✅
- 90th: 2ms ✅  
- 95th: 3ms ✅
- 99th: 8ms ✅

**Verdict:** GPU is not the bottleneck. Frame rendering is generally smooth at 60fps. The 99th percentile spike (32ms) suggests occasional CPU-side hitches, likely during line clear effects or tween-heavy sequences.

### 1.2 Memory Usage (meminfo)

| Category | PSS (KB) | Private Dirty (KB) | Notes |
|----------|----------|---------------------|-------|
| Native Heap | 265,432 | 265,420 | ⚠️ Godot engine + GDScript |
| Graphics (GL+EGL) | 345,661 | 345,661 | ❌ **Major concern** |
| Java Heap | 10,920 | — | ✅ Minimal |
| Code (.so/.jar) | 50,152 | — | ✅ Normal |
| Stack | 1,576 | — | ✅ Normal |
| **TOTAL PSS** | **704,585 KB (~688MB)** | | ❌ **Over target** |
| **TOTAL RSS** | **815,533 KB (~796MB)** | | ❌ **Significantly over** |

**Heap Analysis:**
- Native Heap Size: 450MB allocated, 259MB in use, 186MB free → Fragmentation concern
- GL mtrack: 305MB — Vulkan/GPU texture buffers
- EGL mtrack: 40MB — Display surface buffers (8× framebuffers at ~10MB each)

**Verdict:** Total memory at ~688MB PSS is well over the 200MB target. The Graphics category alone (346MB) accounts for half. This is primarily Vulkan framebuffer allocation (1080×2340 × 4 bytes × 8 buffers = ~81MB raw) plus GPU texture caches. The Native Heap at 265MB includes Godot engine runtime + all GDScript objects.

### 1.3 CPU Usage (top)

| Metric | Value | Status |
|--------|-------|--------|
| CPU Usage | 76.6% | ❌ **High for idle game** |
| Memory (VSS) | 19GB (virtual) | — |
| Memory (RSS) | 456MB | ⚠️ |

**Verdict:** 76.6% CPU during gameplay is too high for a puzzle game. Primary suspects: continuous `_process()` calls, tween-driven `queue_redraw()` on multiple cells simultaneously, and the GameOrb ambient animation running every frame.

---

## 2. Code Analysis — Bottleneck Identification

### 2.1 🔴 CRITICAL: `cell_view.gd` — _draw() × 64 cells × every redraw

**File:** `scripts/game/cell_view.gd`  
**Impact:** HIGH — Up to 64 cells can redraw per frame during animations

**Issues:**
1. **Excessive `queue_redraw()` calls in tweens:** Every tween step calls `queue_redraw()` on individual cells. During a line clear, 8+ cells simultaneously tween with `queue_redraw()` per step, causing 8×60 = 480 draw calls/sec per cleared line.

2. **_draw() is complex:** Each cell's `_draw()` calls:
   - `draw_set_transform()` (conditional)
   - `DrawUtils.draw_bubble_block()` → 7 sub-draws (shadow, base, gradient, specular×3, stripe, bottom, rim)
   - Optional overlays: line prediction, blast hint, near-line hint, cluster hint
   - Each rounded rect = polygon generation with trig functions (8 segments × 4 corners = 32 cos/sin calls)

3. **`_process()` for age shake:** When cells have age ≥ stage2, `_process()` runs every frame calling `randf_range()` + `queue_redraw()`. Currently disabled (`CELL_AGE_ENABLED = false`), so not active.

4. **Multiple simultaneous pulse tweens:** Special tiles, line prediction, blast hints, near-line hints, cluster hints — each creates looping tweens calling `queue_redraw()` every ~0.05s.

**Estimated per-cell _draw() cost:** ~0.3ms (7 rounded-rect polygons + transforms)  
**Worst case (all 64 cells redraw):** ~19ms → exceeds 16.67ms frame budget

### 2.2 🔴 CRITICAL: `board_renderer.gd` — _draw() allocates StyleBoxFlat every frame

**File:** `scripts/game/board_renderer.gd`  
**Impact:** HIGH — Object allocation in draw path

**Issues:**
1. **`_draw()` creates `StyleBoxFlat.new()` every call (line ~173):** The border style is recreated on every redraw instead of being cached. This allocates and immediately discards an object every frame.

2. **Shockwave rendering in `_process()`:** Active shockwaves cause `queue_redraw()` every frame. Each shockwave uses `draw_arc()` with 48 segments — expensive for multiple simultaneous shockwaves.

3. **Particle system (`clear_particles.gd`):** Each clear spawns up to 48+ particles as individual objects. `_draw()` iterates all particles, calling `draw_set_transform()` + shape draw per particle + afterglow trail = 2 draw calls per particle.

4. **No object pooling for effects:** `play_line_clear_effect()` creates new `Control.new()` + `set_script()` for particles every time. `_spawn_*_popup()` methods create new CanvasLayer + Control for each popup.

### 2.3 🟡 MODERATE: `chroma_blocks_game.gd` — Effect timer proliferation

**File:** `scripts/game/chroma_blocks_game.gd`  
**Impact:** MODERATE — Multiple `create_timer()` calls per turn

**Issues:**
1. **`_play_effects_sequence()`:** Creates 5-10 `get_tree().create_timer()` per placement turn for staggered effects. Each timer is a scene tree node.

2. **`_process()` for GameOrbs:** Runs every frame to animate 3 background orbs with trig calculations. Light but unnecessary during static screens.

3. **`_on_drag_moved()` creates virtual board:** `_state.board.place_piece()` called on every drag move for blast preview — allocates a new BoardState each time.

4. **CanvasLayer creation per popup:** Each popup (combo, chain, blast, milestone, score cascade) creates a new CanvasLayer, adding/removing from scene tree repeatedly.

### 2.4 🟡 MODERATE: `draw_utils.gd` — Polygon generation per call

**File:** `scripts/utils/draw_utils.gd`  
**Impact:** MODERATE — Trig-heavy polygon generation not cached

**Issues:**
1. **`draw_rounded_rect()` computes 36 vertex positions** (4 corners × 9 points each) with `cos()`/`sin()` on every call. `draw_bubble_block()` calls this 7 times per cell.
2. **No cached polygon shapes:** The same rounded rect shape is recomputed for identical cell sizes every frame.

### 2.5 🟢 LOW: `draggable_piece.gd` — Reasonable

The piece drawing code is clean. `_draw()` only runs on the 3 tray pieces and uses the same `DrawUtils.draw_bubble_block()`. No major concerns.

---

## 3. Optimization Recommendations

### Priority 1: Reduce draw calls (Expected: -30% CPU)

#### 3.1 Cache `StyleBoxFlat` in `board_renderer._draw()`
```gdscript
# BEFORE (allocates every frame):
var border_style := StyleBoxFlat.new()  # ❌

# AFTER (cache as member):
var _border_style: StyleBoxFlat  # set up in _setup_styles()
```

#### 3.2 Batch cell redraws with dirty flag
Instead of individual `queue_redraw()` per cell per tween step:
```gdscript
# Add to board_renderer:
var _needs_redraw := false

func mark_dirty() -> void:
    if not _needs_redraw:
        _needs_redraw = true
        call_deferred("_batch_redraw")

func _batch_redraw() -> void:
    _needs_redraw = false
    for row in _cells:
        for cell in row:
            if cell._dirty:
                cell.queue_redraw()
                cell._dirty = false
```

#### 3.3 Cache rounded rect polygons in DrawUtils
```gdscript
# Pre-compute polygon for each cell size and cache:
static var _poly_cache: Dictionary = {}  # {size_key: PackedVector2Array}
```

### Priority 2: Eliminate unnecessary `queue_redraw()` (Expected: -20% CPU)

#### 3.4 Throttle tween-driven redraws
For pulse animations (special tile, line prediction, blast hint, near-line, cluster):
- Use `set_process(true)` with a timer interval instead of tween → `queue_redraw()` every step
- Or use shader-based alpha animation instead of CPU-driven redraws

#### 3.5 Skip redundant redraws
Add change detection to `cell_view.gd`:
```gdscript
var _last_bg_color: Color
var _last_scale: float

func queue_redraw_if_changed() -> void:
    if _bg_color != _last_bg_color or _scale_factor != _last_scale:
        _last_bg_color = _bg_color
        _last_scale = _scale_factor
        queue_redraw()
```

### Priority 3: Object pooling (Expected: -10% memory churn)

#### 3.6 Pool particle systems
```gdscript
# In board_renderer:
var _particle_pool: Array = []
const PARTICLE_POOL_SIZE := 3

func _get_particle_system() -> Control:
    if _particle_pool.size() > 0:
        return _particle_pool.pop_back()
    var p := Control.new()
    p.set_script(_get_clear_particles_script())
    return p
```

#### 3.7 Pool popup CanvasLayers
Reuse a single overlay CanvasLayer for popups instead of creating/destroying per event.

### Priority 4: Reduce frame-by-frame computation

#### 3.8 Optimize GameOrb `_process()`
```gdscript
# Only process when visible (skip during game over, home screen, etc.)
func _process(delta: float) -> void:
    if _game_orbs.is_empty() or not _state.status == Enums.GameStatus.PLAYING:
        return
```

#### 3.9 Avoid virtual board creation during drag
Cache the placement validation result and only recompute when grid position changes (already partially done with `_last_grid_pos` check, but `place_piece()` still allocates).

### Priority 5: Memory reduction

#### 3.10 Reduce Vulkan framebuffer count
In Godot project settings, check if triple-buffering can be reduced to double-buffering. Current 8 framebuffers at 10MB each = 80MB.

#### 3.11 Review Godot rendering settings
- Disable unused rendering features (3D, advanced lighting)
- Set `rendering/renderer/rendering_method` to `mobile` if not already
- Reduce texture cache sizes

---

## 4. Performance Targets

| Metric | Current | Target | Gap |
|--------|---------|--------|-----|
| FPS (50th pctl) | 200fps (5ms) | 60fps stable | ✅ Met |
| FPS (99th pctl) | ~31fps (32ms) | 60fps (16.67ms) | ❌ Need 2× improvement |
| CPU Usage (gameplay) | 76.6% | <40% | ❌ Need ~50% reduction |
| Memory (PSS) | 688MB | <200MB | ❌ Need ~70% reduction* |
| Memory (Native Heap) | 265MB | <100MB | ❌ Requires engine-level changes |
| Janky frames | 6.98% | <5% | ⚠️ Close |

\* Note: The 200MB target may not be achievable with Godot 4.x Vulkan on this resolution without engine-level changes. A more realistic target is **<400MB** with the optimizations above. The 346MB Graphics allocation is largely Vulkan driver overhead for the 1080×2340 display.

---

## 5. Quick Wins (Implement First)

1. **Cache `StyleBoxFlat` in `board_renderer._draw()`** — 5 min fix, eliminates GC pressure
2. **Cache rounded rect polygons** — 30 min, reduces trig computation by ~85%
3. **Disable GameOrb `_process()` when not playing** — 2 min fix
4. **Throttle pulse tween redraws to 30fps** — 15 min, halves redraw calls for idle animations
5. **Pool the particle system** — 20 min, reduces allocation churn during clears

---

## 6. Architecture Notes

The game uses Godot's custom drawing (`_draw()`) extensively instead of sprites/textures. This gives visual flexibility but means every visual change requires CPU polygon generation. For long-term performance, consider:

- **Pre-rendered cell textures:** Render bubble blocks to textures at startup, then use `draw_texture()` instead of polygon-based `draw_bubble_block()`. This would eliminate ~90% of per-cell draw cost.
- **Shader-based effects:** Move pulse/glow animations to fragment shaders instead of CPU-driven `queue_redraw()` + color interpolation.
- **VisualServer direct calls:** For the 64-cell grid, batch draw calls through Godot's RenderingServer API.

---

*Profile generated by automated analysis. Re-run ADB profiling after optimizations to validate improvements.*
