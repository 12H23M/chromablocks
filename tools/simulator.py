#!/usr/bin/env python3
"""
ChromaBlocks Python Game Simulator
====================================
GDScript 게임 로직을 Python으로 포팅.
1000판 시뮬레이션 → JSON 리포트 + 밸런스 파라미터 분석.

Usage:
  python3 tools/simulator.py [--games 1000] [--verbose] [--profile <name>]
  python3 tools/simulator.py --compare   # 여러 파라미터 프로파일 비교
  python3 tools/simulator.py --balance   # 밸런스 최적화 탐색

Report saved to: tools/sim_report.json
"""

import random
import json
import argparse
import math
import sys
import time
from dataclasses import dataclass, field
from typing import Optional
from copy import deepcopy
from collections import defaultdict

# ─────────────────────────────────────────────────────────
# Constants (mirrors game_constants.gd)
# ─────────────────────────────────────────────────────────

BOARD_ROWS = 8
BOARD_COLS = 8
BLOCK_COLORS = 6
TRAY_SIZE = 3

PLACEMENT_POINTS_PER_CELL = 5
PERFECT_CLEAR_BONUS = 2000

LINE_CLEAR_POINTS = {1: 100, 2: 300, 3: 600, 4: 1000}
COMBO_MULTIPLIERS = [1.0, 1.2, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0]

COLOR_MATCH_ENABLED = False  # currently disabled
CHROMA_CHAIN_ENABLED = False
CHROMA_BLAST_ENABLED = False

EXPERT_COLOR_REDUCE_LEVEL = 25
EXPERT_TRAY_REDUCE_LEVEL = 30

BOMB_REWARD_COMBO_THRESHOLD = 10
BOMB_EXPLOSION_RADIUS = 1

# Level progression: lines needed for next level
def lines_for_next_level(level: int) -> int:
    return min(level * 5, 50)

def line_clear_score(lines: int) -> int:
    if lines <= 0:
        return 0
    if lines <= 4:
        return LINE_CLEAR_POINTS[lines]
    return 1000 + (lines - 4) * 500

def color_match_score(cells: int) -> int:
    if cells < 6:
        return 0
    bonuses = {6: 200, 7: 350, 8: 500}
    if cells <= 8:
        return bonuses[cells]
    return 500 + (cells - 8) * 150

# ─────────────────────────────────────────────────────────
# Piece definitions (mirrors piece_definitions.gd)
# ─────────────────────────────────────────────────────────

SHAPES = {
    "SINGLE":     [[1]],
    "DUO":        [[1, 1]],
    "DUO_V":      [[1], [1]],
    "TRI_LINE":   [[1, 1, 1]],
    "TRI_LINE_V": [[1], [1], [1]],
    "TRI_L":      [[1, 0], [1, 1]],
    "TRI_J":      [[0, 1], [1, 1]],
    "TET_SQUARE": [[1, 1], [1, 1]],
    "TET_LINE":   [[1, 1, 1, 1]],
    "TET_LINE_V": [[1], [1], [1], [1]],
    "TET_T":      [[1, 1, 1], [0, 1, 0]],
    "TET_T_UP":   [[0, 1, 0], [1, 1, 1]],
    "TET_T_R":    [[1, 0], [1, 1], [1, 0]],
    "TET_T_L":    [[0, 1], [1, 1], [0, 1]],
    "TET_Z":      [[1, 1, 0], [0, 1, 1]],
    "TET_S":      [[0, 1, 1], [1, 1, 0]],
    "TET_Z_V":    [[0, 1], [1, 1], [1, 0]],
    "TET_S_V":    [[1, 0], [1, 1], [0, 1]],
    "TET_L":      [[1, 0], [1, 0], [1, 1]],
    "TET_J":      [[0, 1], [0, 1], [1, 1]],
    "TET_L_H":    [[1, 1, 1], [1, 0, 0]],
    "TET_J_H":    [[1, 1, 1], [0, 0, 1]],
    "PENT_PLUS":  [[0, 1, 0], [1, 1, 1], [0, 1, 0]],
    "PENT_U":     [[1, 0, 1], [1, 1, 1]],
    "PENT_T":     [[1, 1, 1], [0, 1, 0], [0, 1, 0]],
    "PENT_LINE":  [[1, 1, 1, 1, 1]],
    "PENT_LINE_V":[[1], [1], [1], [1], [1]],
    "PENT_L3":    [[1, 1, 1], [0, 0, 1], [0, 0, 1]],
    "PENT_J3":    [[1, 1, 1], [1, 0, 0], [1, 0, 0]],
    "PENT_L3_R":  [[1, 0, 0], [1, 0, 0], [1, 1, 1]],
    "PENT_J3_R":  [[0, 0, 1], [0, 0, 1], [1, 1, 1]],
    "RECT_2x3":   [[1, 1], [1, 1], [1, 1]],
    "SQ_3x3":     [[1, 1, 1], [1, 1, 1], [1, 1, 1]],
    "RECT_3x2":   [[1, 1, 1], [1, 1, 1]],
    "PENT_N":     [[1, 0], [1, 1], [0, 1], [0, 1]],
    "PENT_N_R":   [[0, 1], [1, 1], [1, 0], [1, 0]],
    "PENT_N_V":   [[1, 1, 0], [0, 1, 1], [0, 0, 1]],
    "PENT_N_V2":  [[0, 0, 1], [0, 1, 1], [1, 1, 0]],
    "BOMB":       [[1]],
}

# Size category classification (mirrors piece_generator.gd)
TINY  = ["SINGLE", "DUO", "DUO_V"]
SMALL = ["TRI_LINE", "TRI_LINE_V", "TRI_L", "TRI_J"]
MEDIUM = [
    "TET_SQUARE", "TET_LINE", "TET_LINE_V",
    "TET_T", "TET_T_UP", "TET_T_R", "TET_T_L",
    "TET_Z", "TET_S", "TET_Z_V", "TET_S_V",
    "TET_L", "TET_J", "TET_L_H", "TET_J_H",
]
LARGE = [
    "PENT_PLUS", "PENT_U", "PENT_T",
    "PENT_L3", "PENT_J3", "PENT_L3_R", "PENT_J3_R",
    "PENT_N", "PENT_N_R", "PENT_N_V", "PENT_N_V2",
]
HUGE = ["RECT_2x3", "SQ_3x3", "RECT_3x2"]

SIZE_CATS = {"TINY": TINY, "SMALL": SMALL, "MEDIUM": MEDIUM, "LARGE": LARGE, "HUGE": HUGE}

# Piece cell counts
PIECE_CELLS = {
    name: sum(cell for row in shape for cell in row)
    for name, shape in SHAPES.items()
}

# ─────────────────────────────────────────────────────────
# Tray templates (mirrors piece_generator.gd templates)
# ─────────────────────────────────────────────────────────

TEMPLATES_EASY = [
    {"t": ["SMALL", "MEDIUM", "MEDIUM"], "w": 0.22},
    {"t": ["MEDIUM", "MEDIUM", "MEDIUM"], "w": 0.15},
    {"t": ["TINY", "MEDIUM", "MEDIUM"], "w": 0.13},
    {"t": ["SMALL", "MEDIUM", "LARGE"], "w": 0.12},
    {"t": ["TINY", "MEDIUM", "LARGE"], "w": 0.10},
    {"t": ["TINY", "SMALL", "MEDIUM"], "w": 0.10},
    {"t": ["SMALL", "SMALL", "MEDIUM"], "w": 0.08},
    {"t": ["MEDIUM", "MEDIUM", "HUGE"], "w": 0.05},
    {"t": ["TINY", "SMALL", "LARGE"], "w": 0.05},
]

TEMPLATES_MEDIUM = [
    {"t": ["SMALL", "MEDIUM", "MEDIUM"], "w": 0.25},
    {"t": ["TINY", "MEDIUM", "LARGE"], "w": 0.20},
    {"t": ["SMALL", "SMALL", "LARGE"], "w": 0.15},
    {"t": ["MEDIUM", "MEDIUM", "MEDIUM"], "w": 0.15},
    {"t": ["SMALL", "MEDIUM", "LARGE"], "w": 0.10},
    {"t": ["SMALL", "LARGE", "LARGE"], "w": 0.10},
    {"t": ["TINY", "LARGE", "HUGE"], "w": 0.05},
]

TEMPLATES_HARD = [
    {"t": ["SMALL", "MEDIUM", "LARGE"], "w": 0.25},
    {"t": ["MEDIUM", "LARGE", "LARGE"], "w": 0.20},
    {"t": ["SMALL", "LARGE", "HUGE"], "w": 0.15},
    {"t": ["MEDIUM", "MEDIUM", "LARGE"], "w": 0.15},
    {"t": ["LARGE", "LARGE", "LARGE"], "w": 0.10},
    {"t": ["TINY", "LARGE", "HUGE"], "w": 0.10},
    {"t": ["LARGE", "HUGE", "HUGE"], "w": 0.05},
]

TEMPLATES_EXPERT = [
    {"t": ["MEDIUM", "LARGE"], "w": 0.30},
    {"t": ["LARGE", "LARGE"], "w": 0.30},
    {"t": ["MEDIUM", "HUGE"], "w": 0.20},
    {"t": ["LARGE", "HUGE"], "w": 0.20},
]

def get_templates(fill_ratio: float, level: int) -> list:
    """Select tray template set based on fill_ratio (DDA)."""
    if level >= EXPERT_TRAY_REDUCE_LEVEL:
        return TEMPLATES_EXPERT
    if fill_ratio < 0.30:
        return TEMPLATES_EASY
    elif fill_ratio < 0.50:
        return TEMPLATES_MEDIUM
    elif fill_ratio < 0.70:
        return TEMPLATES_HARD
    else:
        # Very dense: mercy mode, pick from TINY+SMALL only
        return [
            {"t": ["TINY", "TINY", "SMALL"], "w": 0.40},
            {"t": ["TINY", "SMALL", "SMALL"], "w": 0.35},
            {"t": ["TINY", "TINY", "TINY"], "w": 0.25},
        ]

def pick_template(templates: list, rng: random.Random) -> list:
    total = sum(e["w"] for e in templates)
    roll = rng.random() * total
    for e in templates:
        roll -= e["w"]
        if roll <= 0:
            return e["t"]
    return templates[-1]["t"]

# ─────────────────────────────────────────────────────────
# Board State
# ─────────────────────────────────────────────────────────

@dataclass
class Board:
    grid: list = field(default_factory=lambda: [[None]*BOARD_COLS for _ in range(BOARD_ROWS)])

    def copy(self) -> 'Board':
        return Board([[self.grid[r][c] for c in range(BOARD_COLS)] for r in range(BOARD_ROWS)])

    def fill_ratio(self) -> float:
        count = sum(1 for r in range(BOARD_ROWS) for c in range(BOARD_COLS) if self.grid[r][c] is not None)
        return count / (BOARD_ROWS * BOARD_COLS)

    def occupied_cells(self) -> int:
        return sum(1 for r in range(BOARD_ROWS) for c in range(BOARD_COLS) if self.grid[r][c] is not None)

    def can_place(self, shape: list, gx: int, gy: int) -> bool:
        grid = self.grid
        for row_idx, row in enumerate(shape):
            rr = gy + row_idx
            if rr < 0 or rr >= BOARD_ROWS:
                for cell in row:
                    if cell == 1:
                        return False
                continue
            for col_idx, cell in enumerate(row):
                if cell == 1:
                    cc = gx + col_idx
                    if cc < 0 or cc >= BOARD_COLS or grid[rr][cc] is not None:
                        return False
        return True

    def can_place_cells(self, cells: list) -> bool:
        """Place using pre-computed cells list."""
        grid = self.grid
        for (r, c) in cells:
            if r < 0 or r >= BOARD_ROWS or c < 0 or c >= BOARD_COLS or grid[r][c] is not None:
                return False
        return True

    def place(self, shape: list, color: int, gx: int, gy: int) -> None:
        for row_idx, row in enumerate(shape):
            for col_idx, cell in enumerate(row):
                if cell == 1:
                    r, c = gy + row_idx, gx + col_idx
                    self.grid[r][c] = color

    def clear_lines(self) -> dict:
        """Clear complete rows and columns. Returns stats."""
        full_rows = [r for r in range(BOARD_ROWS) if all(self.grid[r][c] is not None for c in range(BOARD_COLS))]
        full_cols = [c for c in range(BOARD_COLS) if all(self.grid[r][c] is not None for r in range(BOARD_ROWS))]

        for r in full_rows:
            for c in range(BOARD_COLS):
                self.grid[r][c] = None
        for c in full_cols:
            for r in range(BOARD_ROWS):
                self.grid[r][c] = None

        lines = len(full_rows) + len(full_cols)
        is_perfect = all(self.grid[r][c] is None for r in range(BOARD_ROWS) for c in range(BOARD_COLS))
        return {"lines_cleared": lines, "rows": full_rows, "cols": full_cols, "is_perfect": is_perfect}

    def can_place_any(self, tray_pieces: list) -> bool:
        for (shape, _, *rest) in tray_pieces:
            h = len(shape)
            w = len(shape[0]) if h > 0 else 0
            for gy in range(BOARD_ROWS - h + 1):
                for gx in range(BOARD_COLS - w + 1):
                    if self.can_place(shape, gx, gy):
                        return True
        return False

    def count_holes(self) -> int:
        """Count isolated empty cells surrounded by filled cells or edges."""
        holes = 0
        for r in range(BOARD_ROWS):
            for c in range(BOARD_COLS):
                if self.grid[r][c] is None:
                    neighbors_filled = sum(
                        1 for dr, dc in [(-1,0),(1,0),(0,-1),(0,1)]
                        if 0 <= r+dr < BOARD_ROWS and 0 <= c+dc < BOARD_COLS
                        and self.grid[r+dr][c+dc] is not None
                    )
                    # Count edge as "filled"
                    edge_count = sum(
                        1 for dr, dc in [(-1,0),(1,0),(0,-1),(0,1)]
                        if not (0 <= r+dr < BOARD_ROWS and 0 <= c+dc < BOARD_COLS)
                    )
                    if (neighbors_filled + edge_count) == 4:
                        holes += 1
        return holes

    def row_completeness(self) -> list:
        """Return fill % per row (0=top, 7=bottom)."""
        return [sum(1 for c in range(BOARD_COLS) if self.grid[r][c] is not None) / BOARD_COLS
                for r in range(BOARD_ROWS)]

    def lines_near_complete(self, threshold: float = 0.75) -> int:
        """Count rows/cols that are >= threshold full (near-complete)."""
        near = 0
        for r in range(BOARD_ROWS):
            filled = sum(1 for c in range(BOARD_COLS) if self.grid[r][c] is not None)
            if filled / BOARD_COLS >= threshold:
                near += 1
        for c in range(BOARD_COLS):
            filled = sum(1 for r in range(BOARD_ROWS) if self.grid[r][c] is not None)
            if filled / BOARD_ROWS >= threshold:
                near += 1
        return near

# ─────────────────────────────────────────────────────────
# Piece Generator (Python port of piece_generator.gd)
# ─────────────────────────────────────────────────────────

class PieceGenerator:
    def __init__(self, seed: Optional[int] = None):
        self.rng = random.Random(seed)
        self._prev_types: list = []

    def generate_tray(self, board: Board, level: int) -> list:
        """Generate a tray of (shape, color, piece_name) tuples."""
        fill = board.fill_ratio()
        templates = get_templates(fill, level)
        template = pick_template(templates, self.rng)

        tray = []
        used_types = []
        n_colors = BLOCK_COLORS  # (expert mode simplification)

        for cat_name in template:
            pool = [p for p in SIZE_CATS[cat_name]
                    if p not in used_types and p not in self._prev_types]
            if not pool:
                pool = [p for p in SIZE_CATS[cat_name] if p not in used_types]
            if not pool:
                pool = SIZE_CATS.get("TINY", ["SINGLE"])

            piece_name = self.rng.choice(pool)
            color = self.rng.randint(0, n_colors - 1)
            shape = SHAPES[piece_name]
            tray.append((shape, color, piece_name))
            used_types.append(piece_name)

        self._prev_types = used_types[:]

        # Rescue: if tray is unplayable, replace largest piece with TINY
        if not board.can_place_any(tray):
            tray = self._rescue_tray(tray, board, n_colors)

        return tray

    def _rescue_tray(self, tray: list, board: Board, n_colors: int) -> list:
        rescued = list(tray)
        # Try replacing pieces from largest to smallest
        for i in range(len(rescued) - 1, -1, -1):
            for p in ["SINGLE", "DUO", "DUO_V", "TRI_LINE", "TRI_LINE_V"]:
                color = self.rng.randint(0, n_colors - 1)
                candidate = (SHAPES[p], color, p)
                rescued[i] = candidate
                if board.can_place_any(rescued):
                    return rescued
        # Fallback: all singles
        return [(SHAPES["SINGLE"], self.rng.randint(0, n_colors-1), "SINGLE") for _ in tray]

# ─────────────────────────────────────────────────────────
# AI Player (greedy, mirrors auto_player.gd)
# ─────────────────────────────────────────────────────────

W_LINE_CLEAR = 100.0
W_ADJACENCY = 10.0
W_HOLE_PENALTY = -20.0
W_BOTTOM_PREFER = 5.0
W_ISOLATED_COL = -50.0
W_EDGE_BONUS = 3.0
W_FILL_ROW_PROGRESS = 8.0

def predict_completed_lines(board: Board, shape: list, gx: int, gy: int) -> dict:
    """Count how many rows/cols would complete if we place this piece."""
    test = board.copy()
    test.place(shape, 0, gx, gy)
    rows = [r for r in range(BOARD_ROWS) if all(test.grid[r][c] is not None for c in range(BOARD_COLS))]
    cols = [c for c in range(BOARD_COLS) if all(test.grid[r][c] is not None for r in range(BOARD_ROWS))]
    return {"rows": rows, "cols": cols}

def evaluate_placement(board: Board, shape: list, gx: int, gy: int,
                        row_fills: list, col_fills: list) -> float:
    """Fast evaluation using pre-computed row/col fill counts."""
    score = 0.0
    cells = [(gy + ri, gx + ci)
             for ri, row in enumerate(shape)
             for ci, cell in enumerate(row) if cell == 1]

    # 1. Line completion prediction (fast version)
    row_new = defaultdict(int)
    col_new = defaultdict(int)
    for (r, c) in cells:
        row_new[r] += 1
        col_new[c] += 1

    completed = 0
    for r, cnt in row_new.items():
        if row_fills[r] + cnt == BOARD_COLS:
            completed += 1
    for c, cnt in col_new.items():
        if col_fills[c] + cnt == BOARD_ROWS:
            completed += 1
    score += completed * W_LINE_CLEAR

    # 2. Adjacency bonus + edge bonus
    for (r, c) in cells:
        for dr, dc in ((-1,0),(1,0),(0,-1),(0,1)):
            nr, nc = r+dr, c+dc
            if 0 <= nr < BOARD_ROWS and 0 <= nc < BOARD_COLS:
                if board.grid[nr][nc] is not None:
                    score += W_ADJACENCY
            else:
                score += W_EDGE_BONUS

    # 3. Bottom preference
    score += max(r for (r, c) in cells) * W_BOTTOM_PREFER

    # 4. Fill row/col progress
    for r, cnt in row_new.items():
        score += (row_fills[r] + cnt) / BOARD_COLS * W_FILL_ROW_PROGRESS
    for c, cnt in col_new.items():
        score += (col_fills[c] + cnt) / BOARD_ROWS * W_FILL_ROW_PROGRESS

    # 5. Hole penalty (lightweight: penalize if we block the only empty space in a row)
    for r, cnt in row_new.items():
        remaining = BOARD_COLS - row_fills[r] - cnt
        if remaining == 1:
            # We left exactly 1 gap — near complete but hole risk
            score += W_HOLE_PENALTY * 0.3

    return score

def _shape_offsets(shape: list) -> list:
    """Pre-compute list of (row_offset, col_offset) for occupied cells."""
    return [(ri, ci) for ri, row in enumerate(shape) for ci, cell in enumerate(row) if cell == 1]

# Cache shape offsets
_SHAPE_OFFSETS_CACHE: dict = {}

def get_shape_offsets(shape_key, shape: list) -> list:
    if shape_key not in _SHAPE_OFFSETS_CACHE:
        _SHAPE_OFFSETS_CACHE[shape_key] = _shape_offsets(shape)
    return _SHAPE_OFFSETS_CACHE[shape_key]

def find_best_move(board: Board, tray: list) -> Optional[dict]:
    best_score = -float("inf")
    best_move = None
    grid = board.grid

    # Pre-compute fill counts once per tray evaluation
    row_fills = [sum(1 for c in range(BOARD_COLS) if grid[r][c] is not None)
                 for r in range(BOARD_ROWS)]
    col_fills = [sum(1 for r in range(BOARD_ROWS) if grid[r][c] is not None)
                 for c in range(BOARD_COLS)]

    for (shape, color, piece_name) in tray:
        h = len(shape)
        w = len(shape[0]) if h > 0 else 0
        offsets = get_shape_offsets(piece_name, shape)

        for gy in range(BOARD_ROWS - h + 1):
            for gx in range(BOARD_COLS - w + 1):
                # Fast can_place using offsets
                ok = True
                for (dri, dci) in offsets:
                    rr, cc = gy + dri, gx + dci
                    if grid[rr][cc] is not None:
                        ok = False
                        break
                if not ok:
                    continue

                s = evaluate_placement(board, shape, gx, gy, row_fills, col_fills)
                if s > best_score:
                    best_score = s
                    best_move = {"shape": shape, "color": color, "piece": piece_name,
                                 "gx": gx, "gy": gy, "eval": s}

    return best_move

# ─────────────────────────────────────────────────────────
# Prefill Strategies
# ─────────────────────────────────────────────────────────

def prefill_bottom(board: Board, rng: random.Random, rows: int = 3, chance: float = 0.65):
    """Current: fill bottom N rows with <chance>."""
    for r in range(BOARD_ROWS - rows, BOARD_ROWS):
        for c in range(BOARD_COLS):
            if rng.random() < chance:
                board.grid[r][c] = rng.randint(0, BLOCK_COLORS-1)
        # Never complete a row on start
        if all(board.grid[r][c] is not None for c in range(BOARD_COLS)):
            board.grid[r][rng.randint(0, BOARD_COLS-1)] = None

def prefill_spread(board: Board, rng: random.Random, target_ratio: float = 0.35, near_complete: int = 2):
    """Spread fill with near-complete lines for quick first clears."""
    used_rows = set()
    for _ in range(near_complete):
        r = rng.randint(BOARD_ROWS // 2, BOARD_ROWS - 1)
        if r in used_rows:
            continue
        used_rows.add(r)
        gaps = rng.randint(1, 2)
        gap_positions = set(rng.sample(range(BOARD_COLS), gaps))
        for c in range(BOARD_COLS):
            if c not in gap_positions:
                board.grid[r][c] = rng.randint(0, BLOCK_COLORS-1)

    empty = [(r, c) for r in range(BOARD_ROWS) for c in range(BOARD_COLS) if board.grid[r][c] is None]
    rng.shuffle(empty)
    for r, c in empty:
        if board.fill_ratio() >= target_ratio:
            break
        board.grid[r][c] = rng.randint(0, BLOCK_COLORS-1)
        # Don't complete lines on prefill
        if (all(board.grid[r][cc] is not None for cc in range(BOARD_COLS)) or
                all(board.grid[rr][c] is not None for rr in range(BOARD_ROWS))):
            board.grid[r][c] = None

# ─────────────────────────────────────────────────────────
# Game Simulation
# ─────────────────────────────────────────────────────────

@dataclass
class GameStats:
    score: int = 0
    turns: int = 0
    level: int = 1
    lines_cleared: int = 0
    max_combo: int = 0
    combo: int = 0
    perfect_clears: int = 0
    game_over_turn: Optional[int] = None

    # Detailed
    first_clear_turn: Optional[int] = None
    clears_per_turn: list = field(default_factory=list)  # (turn, n_lines)
    score_curve: list = field(default_factory=list)       # score snapshot every 10 turns
    tray_history: list = field(default_factory=list)      # piece names per tray
    fill_history: list = field(default_factory=list)      # fill_ratio per turn

    # Near-miss
    near_miss_count: int = 0   # turns where ≥1 line was 75%+ full when game ended

def simulate_game(seed: int, prefill_fn=None, max_turns: int = 300, verbose: bool = False) -> GameStats:
    rng = random.Random(seed)
    board = Board()

    if prefill_fn:
        prefill_fn(board, rng)

    gen = PieceGenerator(seed + 1)
    stats = GameStats()

    level = 1
    score = 0
    combo = 0
    lines_for_level = lines_for_next_level(level)
    lines_accumulated = 0
    tray = gen.generate_tray(board, level)

    for turn in range(1, max_turns + 1):
        stats.fill_history.append(board.fill_ratio())

        if not board.can_place_any(tray):
            stats.game_over_turn = turn
            stats.near_miss_count = board.lines_near_complete(0.75)
            break

        move = find_best_move(board, tray)
        if move is None:
            stats.game_over_turn = turn
            break

        shape = move["shape"]
        color = move["color"]
        piece_name = move["piece"]
        gx, gy = move["gx"], move["gy"]

        cell_count = sum(cell for row in shape for cell in row)

        # Place
        board.place(shape, color, gx, gy)

        # Clear lines
        clear = board.clear_lines()
        did_clear = clear["lines_cleared"] > 0

        if did_clear:
            combo += 1
            stats.lines_cleared += clear["lines_cleared"]
            lines_accumulated += clear["lines_cleared"]
            if stats.first_clear_turn is None:
                stats.first_clear_turn = turn
            stats.clears_per_turn.append((turn, clear["lines_cleared"]))
            if clear["is_perfect"]:
                stats.perfect_clears += 1
        else:
            combo = 0

        stats.combo = combo
        if combo > stats.max_combo:
            stats.max_combo = combo

        # Scoring
        placement_pts = cell_count * PLACEMENT_POINTS_PER_CELL
        line_pts = line_clear_score(clear["lines_cleared"])
        perfect_pts = PERFECT_CLEAR_BONUS if clear["is_perfect"] else 0
        combo_idx = min(combo, len(COMBO_MULTIPLIERS) - 1)
        multiplier = COMBO_MULTIPLIERS[combo_idx]
        bonus = round((line_pts + perfect_pts) * multiplier)
        score += placement_pts + bonus
        stats.score = score

        # Level up
        if lines_accumulated >= lines_for_level:
            lines_accumulated -= lines_for_level
            level += 1
            lines_for_level = lines_for_next_level(level)
        stats.level = level

        # Score curve snapshot
        if turn % 10 == 0:
            stats.score_curve.append({"turn": turn, "score": score, "level": level, "fill": board.fill_ratio()})

        stats.turns = turn

        # Generate next tray (tray refreshes after each turn)
        # In actual game, tray refreshes when empty. Here: remove used piece, refill if needed.
        tray = [p for p in tray if p[2] != piece_name]
        if not tray:
            tray = gen.generate_tray(board, level)
        else:
            # If remaining pieces can't be placed, regenerate
            if not board.can_place_any(tray):
                tray = gen.generate_tray(board, level)

        if verbose and turn % 50 == 0:
            print(f"  Turn {turn}: score={score}, level={level}, fill={board.fill_ratio():.2f}, combo={combo}")

    return stats

# ─────────────────────────────────────────────────────────
# Run batch simulation
# ─────────────────────────────────────────────────────────

def run_simulation(n_games: int = 1000, prefill_fn=None, label: str = "default",
                   verbose: bool = False) -> dict:
    scores = []
    turns_list = []
    first_clears = []
    max_combos = []
    lines_cleared = []
    game_overs_early = 0  # < 20 turns
    near_misses = []
    perfect_clears = []
    all_score_curves = []
    fill_at_death = []

    start = time.time()
    for i in range(n_games):
        stats = simulate_game(seed=i * 31337 + 7, prefill_fn=prefill_fn,
                              verbose=(verbose and i == 0))
        scores.append(stats.score)
        turns_list.append(stats.turns)
        if stats.first_clear_turn:
            first_clears.append(stats.first_clear_turn)
        max_combos.append(stats.max_combo)
        lines_cleared.append(stats.lines_cleared)
        if stats.turns < 20:
            game_overs_early += 1
        near_misses.append(stats.near_miss_count)
        perfect_clears.append(stats.perfect_clears)
        if stats.score_curve:
            all_score_curves.append(stats.score_curve)
        if stats.fill_history:
            fill_at_death.append(stats.fill_history[-1])

    elapsed = time.time() - start

    def pct(lst, p):
        s = sorted(lst)
        return s[int(len(s) * p / 100)] if s else 0

    report = {
        "label": label,
        "n_games": n_games,
        "elapsed_sec": round(elapsed, 2),
        "score": {
            "min": min(scores), "max": max(scores),
            "avg": round(sum(scores)/len(scores)),
            "p25": pct(scores, 25), "p50": pct(scores, 50),
            "p75": pct(scores, 75), "p95": pct(scores, 95),
        },
        "turns": {
            "min": min(turns_list), "max": max(turns_list),
            "avg": round(sum(turns_list)/len(turns_list)),
            "p25": pct(turns_list, 25), "p50": pct(turns_list, 50),
            "p75": pct(turns_list, 75),
        },
        "first_clear_turn": {
            "avg": round(sum(first_clears)/len(first_clears), 1) if first_clears else None,
            "never_cleared_pct": round((n_games - len(first_clears)) / n_games * 100, 1),
            "within_3_turns_pct": round(sum(1 for t in first_clears if t <= 3) / n_games * 100, 1),
            "within_5_turns_pct": round(sum(1 for t in first_clears if t <= 5) / n_games * 100, 1),
        },
        "max_combo": {
            "avg": round(sum(max_combos)/len(max_combos), 2),
            "p50": pct(max_combos, 50), "p90": pct(max_combos, 90),
            "reached_5plus_pct": round(sum(1 for c in max_combos if c >= 5) / n_games * 100, 1),
        },
        "lines_cleared_avg": round(sum(lines_cleared)/len(lines_cleared), 1),
        "perfect_clears_avg": round(sum(perfect_clears)/len(perfect_clears), 3),
        "early_game_over_pct": round(game_overs_early / n_games * 100, 1),
        "near_miss_at_game_over": {
            "avg_lines": round(sum(near_misses)/len(near_misses), 2),
            "has_near_miss_pct": round(sum(1 for n in near_misses if n > 0) / n_games * 100, 1),
        },
        "fill_at_death_avg": round(sum(fill_at_death)/len(fill_at_death), 3) if fill_at_death else None,
    }
    return report

# ─────────────────────────────────────────────────────────
# Balance Profiles
# ─────────────────────────────────────────────────────────

PROFILES = {
    "default": {
        "prefill": lambda b, r: prefill_bottom(b, r, rows=3, chance=0.65),
        "label": "현재: 하단 3줄 65%"
    },
    "spread_30": {
        "prefill": lambda b, r: prefill_spread(b, r, target_ratio=0.30, near_complete=1),
        "label": "Spread 30% + 1 near-complete"
    },
    "spread_35": {
        "prefill": lambda b, r: prefill_spread(b, r, target_ratio=0.35, near_complete=2),
        "label": "Spread 35% + 2 near-complete"
    },
    "spread_40": {
        "prefill": lambda b, r: prefill_spread(b, r, target_ratio=0.40, near_complete=2),
        "label": "Spread 40% + 2 near-complete"
    },
    "no_prefill": {
        "prefill": None,
        "label": "프리필 없음 (빈 보드)"
    },
}

# ─────────────────────────────────────────────────────────
# Printing helpers
# ─────────────────────────────────────────────────────────

def print_report(r: dict):
    print(f"\n{'='*60}")
    print(f"  {r['label']}  ({r['n_games']}판, {r['elapsed_sec']}s)")
    print(f"{'='*60}")
    s = r["score"]
    print(f"  📊 점수   avg={s['avg']:,}  p50={s['p50']:,}  p95={s['p95']:,}  max={s['max']:,}")
    t = r["turns"]
    print(f"  ⏱  턴수   avg={t['avg']}  p50={t['p50']}  p75={t['p75']}  max={t['max']}")
    fc = r["first_clear_turn"]
    avg_fc = f"{fc['avg']}" if fc["avg"] else "N/A"
    print(f"  🎯 첫 클리어  avg={avg_fc}턴  3턴이내={fc['within_3_turns_pct']}%  5턴이내={fc['within_5_turns_pct']}%  미클리어={fc['never_cleared_pct']}%")
    c = r["max_combo"]
    print(f"  🔥 콤보   avg={c['avg']}  p90={c['p90']}  5+콤보={c['reached_5plus_pct']}%")
    nm = r["near_miss_at_game_over"]
    print(f"  💔 게임오버   near-miss있음={nm['has_near_miss_pct']}%  조기종료={r['early_game_over_pct']}%")
    print(f"  🧹 라인클리어 avg={r['lines_cleared_avg']}  퍼펙트={r['perfect_clears_avg']}")

# ─────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="ChromaBlocks Simulator")
    parser.add_argument("--games", type=int, default=1000, help="시뮬레이션 게임 수")
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--profile", default="default", choices=list(PROFILES.keys()))
    parser.add_argument("--compare", action="store_true", help="모든 프로파일 비교")
    parser.add_argument("--output", default="tools/sim_report.json")
    args = parser.parse_args()

    all_reports = []

    if args.compare:
        print(f"\nChrоmaBlocks Simulator — {args.games}판 × {len(PROFILES)} 프로파일")
        for key, prof in PROFILES.items():
            print(f"\n▶ {prof['label']} 실행 중...", end="", flush=True)
            report = run_simulation(
                n_games=args.games,
                prefill_fn=prof["prefill"],
                label=prof["label"],
                verbose=args.verbose,
            )
            print_report(report)
            all_reports.append(report)
    else:
        prof = PROFILES[args.profile]
        print(f"\nChrоmaBlocks Simulator — {args.games}판 ({prof['label']})")
        report = run_simulation(
            n_games=args.games,
            prefill_fn=prof["prefill"],
            label=prof["label"],
            verbose=args.verbose,
        )
        print_report(report)
        all_reports.append(report)

    # Save report
    output_path = args.output
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump({"reports": all_reports, "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S")}, f, indent=2, ensure_ascii=False)
    print(f"\n✅ 리포트 저장: {output_path}")

    # Print balance verdict
    if args.compare and all_reports:
        print("\n\n📋 밸런스 분석 요약")
        print("="*60)
        best_score = max(all_reports, key=lambda r: r["score"]["avg"])
        best_first_clear = min(
            (r for r in all_reports if r["first_clear_turn"]["avg"] is not None),
            key=lambda r: r["first_clear_turn"]["avg"],
            default=None
        )
        best_combo = max(all_reports, key=lambda r: r["max_combo"]["avg"])
        best_retention = max(all_reports, key=lambda r: r["turns"]["avg"])

        print(f"  최고 점수:        {best_score['label']} ({best_score['score']['avg']:,})")
        if best_first_clear:
            print(f"  첫 클리어 빠름:   {best_first_clear['label']} (avg {best_first_clear['first_clear_turn']['avg']}턴)")
        print(f"  최고 콤보:        {best_combo['label']} (avg {best_combo['max_combo']['avg']})")
        print(f"  장수 (리텐션):    {best_retention['label']} (avg {best_retention['turns']['avg']}턴)")

if __name__ == "__main__":
    main()
