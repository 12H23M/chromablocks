#!/usr/bin/env python3
"""
ChromaBlocks Python Simulator — Issue #7
Ports core game logic to Python for fast balance simulation.
1000-game simulation → JSON report with balance parameter grid search.
"""

import json
import random
import sys
import time
from concurrent.futures import ProcessPoolExecutor
from dataclasses import dataclass, field
from enum import IntEnum
from pathlib import Path
from typing import Optional

# ═══════════════════════════════════════════
# Enums
# ═══════════════════════════════════════════

class BlockColor(IntEnum):
    CORAL = 0
    AMBER = 1
    LEMON = 2
    MINT = 3
    SKY = 4
    LAVENDER = 5

class PieceType(IntEnum):
    SINGLE = 0
    DUO = 1; DUO_V = 2
    TRI_LINE = 3; TRI_LINE_V = 4; TRI_L = 5; TRI_J = 6
    TET_SQUARE = 7; TET_LINE = 8; TET_LINE_V = 9
    TET_T = 10; TET_T_UP = 11; TET_T_R = 12; TET_T_L = 13
    TET_Z = 14; TET_S = 15; TET_Z_V = 16; TET_S_V = 17
    TET_L = 18; TET_J = 19; TET_L_H = 20; TET_J_H = 21
    PENT_PLUS = 22; PENT_U = 23; PENT_T = 24; PENT_LINE = 25; PENT_LINE_V = 26
    PENT_L3 = 27; PENT_J3 = 28; PENT_L3_R = 29; PENT_J3_R = 30
    RECT_2x3 = 31; SQ_3x3 = 32; RECT_3x2 = 33
    PENT_N = 34; PENT_N_R = 35; PENT_N_V = 36; PENT_N_V2 = 37

class SizeCat(IntEnum):
    TINY = 0; SMALL = 1; MEDIUM = 2; LARGE = 3; HUGE = 4

# ═══════════════════════════════════════════
# Piece Definitions
# ═══════════════════════════════════════════

SHAPES: dict[int, list[list[int]]] = {
    PieceType.SINGLE: [[1]],
    PieceType.DUO: [[1, 1]],
    PieceType.DUO_V: [[1], [1]],
    PieceType.TRI_LINE: [[1, 1, 1]],
    PieceType.TRI_LINE_V: [[1], [1], [1]],
    PieceType.TRI_L: [[1, 0], [1, 1]],
    PieceType.TRI_J: [[0, 1], [1, 1]],
    PieceType.TET_SQUARE: [[1, 1], [1, 1]],
    PieceType.TET_LINE: [[1, 1, 1, 1]],
    PieceType.TET_LINE_V: [[1], [1], [1], [1]],
    PieceType.TET_T: [[1, 1, 1], [0, 1, 0]],
    PieceType.TET_T_UP: [[0, 1, 0], [1, 1, 1]],
    PieceType.TET_T_R: [[1, 0], [1, 1], [1, 0]],
    PieceType.TET_T_L: [[0, 1], [1, 1], [0, 1]],
    PieceType.TET_Z: [[1, 1, 0], [0, 1, 1]],
    PieceType.TET_S: [[0, 1, 1], [1, 1, 0]],
    PieceType.TET_Z_V: [[0, 1], [1, 1], [1, 0]],
    PieceType.TET_S_V: [[1, 0], [1, 1], [0, 1]],
    PieceType.TET_L: [[1, 0], [1, 0], [1, 1]],
    PieceType.TET_J: [[0, 1], [0, 1], [1, 1]],
    PieceType.TET_L_H: [[1, 1, 1], [1, 0, 0]],
    PieceType.TET_J_H: [[1, 1, 1], [0, 0, 1]],
    PieceType.PENT_PLUS: [[0, 1, 0], [1, 1, 1], [0, 1, 0]],
    PieceType.PENT_U: [[1, 0, 1], [1, 1, 1]],
    PieceType.PENT_T: [[1, 1, 1], [0, 1, 0], [0, 1, 0]],
    PieceType.PENT_LINE: [[1, 1, 1, 1, 1]],
    PieceType.PENT_LINE_V: [[1], [1], [1], [1], [1]],
    PieceType.PENT_L3: [[1, 1, 1], [0, 0, 1], [0, 0, 1]],
    PieceType.PENT_J3: [[1, 1, 1], [1, 0, 0], [1, 0, 0]],
    PieceType.PENT_L3_R: [[1, 0, 0], [1, 0, 0], [1, 1, 1]],
    PieceType.PENT_J3_R: [[0, 0, 1], [0, 0, 1], [1, 1, 1]],
    PieceType.RECT_2x3: [[1, 1], [1, 1], [1, 1]],
    PieceType.SQ_3x3: [[1, 1, 1], [1, 1, 1], [1, 1, 1]],
    PieceType.RECT_3x2: [[1, 1, 1], [1, 1, 1]],
    PieceType.PENT_N: [[1, 0], [1, 1], [0, 1], [0, 1]],
    PieceType.PENT_N_R: [[0, 1], [1, 1], [1, 0], [1, 0]],
    PieceType.PENT_N_V: [[1, 1, 0], [0, 1, 1], [0, 0, 1]],
    PieceType.PENT_N_V2: [[0, 0, 1], [0, 1, 1], [1, 1, 0]],
}

CATEGORY_PIECES: dict[int, list[int]] = {
    SizeCat.TINY: [PieceType.SINGLE, PieceType.DUO, PieceType.DUO_V],
    SizeCat.SMALL: [PieceType.TRI_LINE, PieceType.TRI_LINE_V, PieceType.TRI_L, PieceType.TRI_J],
    SizeCat.MEDIUM: [
        PieceType.TET_SQUARE, PieceType.TET_LINE, PieceType.TET_LINE_V,
        PieceType.TET_T, PieceType.TET_T_UP, PieceType.TET_T_R, PieceType.TET_T_L,
        PieceType.TET_Z, PieceType.TET_S, PieceType.TET_Z_V, PieceType.TET_S_V,
        PieceType.TET_L, PieceType.TET_J, PieceType.TET_L_H, PieceType.TET_J_H,
    ],
    SizeCat.LARGE: [
        PieceType.PENT_PLUS, PieceType.PENT_U, PieceType.PENT_T,
        PieceType.PENT_L3, PieceType.PENT_J3, PieceType.PENT_L3_R, PieceType.PENT_J3_R,
        PieceType.PENT_N, PieceType.PENT_N_R, PieceType.PENT_N_V, PieceType.PENT_N_V2,
    ],
    SizeCat.HUGE: [PieceType.RECT_2x3, PieceType.SQ_3x3, PieceType.RECT_3x2],
}

# ═══════════════════════════════════════════
# Configuration (matches game_constants.gd defaults)
# ═══════════════════════════════════════════

@dataclass
class SimConfig:
    # Grid
    board_cols: int = 8
    board_rows: int = 8
    tray_size: int = 3

    # Scoring
    placement_pts_per_cell: int = 5
    perfect_clear_bonus: int = 2000
    line_clear_points: dict = field(default_factory=lambda: {1: 100, 2: 300, 3: 600, 4: 1000})
    combo_multipliers: list = field(default_factory=lambda: [1.0, 1.2, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0])

    # Chroma Chain
    chroma_chain_enabled: bool = True
    chroma_chain_threshold: int = 5
    chroma_chain_max_cascade: int = 2
    chroma_chain_pts_per_cell: list = field(default_factory=lambda: [30, 60, 90])

    # Chroma Blast
    chroma_blast_enabled: bool = True
    chroma_blast_threshold: int = 6
    chroma_blast_pts_per_cell: int = 50
    chroma_blast_trigger_bonus: int = 500
    chroma_blast_line_bonus: int = 200

    # DDA
    dda_rush_threshold: float = 0.20
    dda_rush_chance: float = 0.50
    dda_mercy_mild: float = 0.40
    dda_mercy_strong: float = 0.60
    dda_mercy_critical: float = 0.75
    dda_fit_check_chance: float = 0.70
    dda_fit_critical_chance: float = 0.90

    # Color mercy
    color_cluster_chance: float = 0.25
    color_mercy_threshold: float = 0.35
    color_mercy_chance: float = 0.40
    color_mercy_min_group: int = 4

    # Expert mode
    expert_color_reduce_level: int = 25
    expert_tray_reduce_level: int = 30
    expert_color_count: int = 6

    # Anti-frustration
    max_tight_streak: int = 2

    # Simulation cap (greedy AI plays too well; cap to keep sim fast)
    max_trays: int = 500

    def line_clear_score(self, lines: int) -> int:
        if lines <= 0:
            return 0
        if lines <= 4:
            return self.line_clear_points.get(lines, 0)
        return 1000 + (lines - 4) * 500

    def lines_for_next_level(self, level: int) -> int:
        return min(level * 5, 50)

    def get_color_count(self, level: int) -> int:
        return self.expert_color_count if level >= self.expert_color_reduce_level else 6


# ═══════════════════════════════════════════
# BlockPiece
# ═══════════════════════════════════════════

@dataclass
class BlockPiece:
    type: int
    color: int
    shape: list[list[int]]

    @property
    def width(self) -> int:
        return len(self.shape[0]) if self.shape else 0

    @property
    def height(self) -> int:
        return len(self.shape)

    @property
    def cell_count(self) -> int:
        return sum(c for row in self.shape for c in row)

    def occupied_cells_at(self, gx: int, gy: int) -> list[tuple[int, int]]:
        cells = []
        for ry, row in enumerate(self.shape):
            for rx, val in enumerate(row):
                if val == 1:
                    cells.append((gx + rx, gy + ry))
        return cells


# ═══════════════════════════════════════════
# BoardState
# ═══════════════════════════════════════════

EMPTY = -1  # sentinel for empty cell; colors are 0..5

# Pre-compute piece relative cells once (type → tuple of (rx, ry))
_PIECE_CELLS: dict[int, tuple[tuple[int, int], ...]] = {}
_PIECE_DIMS: dict[int, tuple[int, int]] = {}  # type → (width, height)
for _pt, _sh in SHAPES.items():
    _cells = []
    for _ry, _row in enumerate(_sh):
        for _rx, _val in enumerate(_row):
            if _val == 1:
                _cells.append((_rx, _ry))
    _PIECE_CELLS[_pt] = tuple(_cells)
    _PIECE_DIMS[_pt] = (len(_sh[0]) if _sh else 0, len(_sh))


class BoardState:
    """Optimised board using flat list[int]. EMPTY=-1, otherwise color index."""
    __slots__ = ('cols', 'rows', '_cells', '_occupied_count')

    def __init__(self, cols: int = 8, rows: int = 8, cells: Optional[list] = None, occ: int = 0):
        self.cols = cols
        self.rows = rows
        if cells is None:
            self._cells = [EMPTY] * (cols * rows)
            self._occupied_count = 0
        else:
            self._cells = cells
            self._occupied_count = occ

    def copy(self) -> 'BoardState':
        return BoardState(self.cols, self.rows, self._cells[:], self._occupied_count)

    @property
    def is_empty(self) -> bool:
        return self._occupied_count == 0

    def fill_ratio(self) -> float:
        return self._occupied_count / (self.cols * self.rows)

    def _idx(self, x: int, y: int) -> int:
        return y * self.cols + x

    def get_cell(self, x: int, y: int) -> int:
        return self._cells[y * self.cols + x]

    def can_place_piece_at(self, piece: BlockPiece, gx: int, gy: int) -> bool:
        cells = self._cells
        cols = self.cols
        rows = self.rows
        for rx, ry in _PIECE_CELLS[piece.type]:
            x, y = gx + rx, gy + ry
            if x < 0 or x >= cols or y < 0 or y >= rows:
                return False
            if cells[y * cols + x] != EMPTY:
                return False
        return True

    def place_piece_inplace(self, piece: BlockPiece, gx: int, gy: int):
        """Mutate board in-place (use on copies)."""
        cells = self._cells
        cols = self.cols
        color = piece.color
        for rx, ry in _PIECE_CELLS[piece.type]:
            cells[(gy + ry) * cols + (gx + rx)] = color
            self._occupied_count += 1

    def place_piece(self, piece: BlockPiece, gx: int, gy: int) -> 'BoardState':
        b = self.copy()
        b.place_piece_inplace(piece, gx, gy)
        return b

    def get_completed_rows(self) -> list[int]:
        cells = self._cells
        cols = self.cols
        result = []
        for y in range(self.rows):
            base = y * cols
            full = True
            for x in range(cols):
                if cells[base + x] == EMPTY:
                    full = False
                    break
            if full:
                result.append(y)
        return result

    def get_completed_cols(self) -> list[int]:
        cells = self._cells
        cols = self.cols
        rows = self.rows
        result = []
        for x in range(cols):
            full = True
            for y in range(rows):
                if cells[y * cols + x] == EMPTY:
                    full = False
                    break
            if full:
                result.append(x)
        return result

    def clear_completed_lines(self) -> dict:
        c_rows = self.get_completed_rows()
        c_cols = self.get_completed_cols()
        if not c_rows and not c_cols:
            return {"board": self, "lines_cleared": 0, "rows": [], "cols": []}
        b = self.copy()
        cells = b._cells
        cols = b.cols
        cleared = 0
        for y in c_rows:
            base = y * cols
            for x in range(cols):
                if cells[base + x] != EMPTY:
                    cells[base + x] = EMPTY
                    cleared += 1
        for x in c_cols:
            for y in range(b.rows):
                idx = y * cols + x
                if cells[idx] != EMPTY:
                    cells[idx] = EMPTY
                    cleared += 1
        b._occupied_count -= cleared
        return {"board": b, "lines_cleared": len(c_rows) + len(c_cols), "rows": c_rows, "cols": c_cols}

    def find_color_groups(self, threshold: int) -> list[list[tuple[int, int]]]:
        cells = self._cells
        cols = self.cols
        rows = self.rows
        size = cols * rows
        visited = bytearray(size)
        matches = []
        for idx in range(size):
            if visited[idx] or cells[idx] == EMPTY:
                continue
            color = cells[idx]
            y0, x0 = divmod(idx, cols) if False else (idx // cols, idx % cols)
            group = []
            stack = [idx]
            while stack:
                ci = stack.pop()
                if visited[ci]:
                    continue
                if cells[ci] == EMPTY or cells[ci] != color:
                    continue
                visited[ci] = 1
                cy, cx = ci // cols, ci % cols
                group.append((cx, cy))
                if cx + 1 < cols: stack.append(ci + 1)
                if cx > 0: stack.append(ci - 1)
                if cy + 1 < rows: stack.append(ci + cols)
                if cy > 0: stack.append(ci - cols)
            if len(group) >= threshold:
                matches.append(group)
        return matches

    def remove_cells(self, cells_list: list[tuple[int, int]]) -> 'BoardState':
        b = self.copy()
        cells = b._cells
        cols = b.cols
        removed = 0
        for x, y in cells_list:
            idx = y * cols + x
            if cells[idx] != EMPTY:
                cells[idx] = EMPTY
                removed += 1
        b._occupied_count -= removed
        return b

    def can_place_any_piece(self, pieces: list[BlockPiece]) -> bool:
        cells = self._cells
        cols = self.cols
        rows = self.rows
        for piece in pieces:
            w, h = _PIECE_DIMS[piece.type]
            rel = _PIECE_CELLS[piece.type]
            for gy in range(rows - h + 1):
                for gx in range(cols - w + 1):
                    ok = True
                    for rx, ry in rel:
                        if cells[(gy + ry) * cols + (gx + rx)] != EMPTY:
                            ok = False
                            break
                    if ok:
                        return True
        return False

    def has_any_empty(self) -> bool:
        return self._occupied_count < self.cols * self.rows

    def can_place_type(self, piece_type: int) -> bool:
        cells = self._cells
        cols = self.cols
        rows = self.rows
        w, h = _PIECE_DIMS[piece_type]
        rel = _PIECE_CELLS[piece_type]
        for gy in range(rows - h + 1):
            for gx in range(cols - w + 1):
                ok = True
                for rx, ry in rel:
                    if cells[(gy + ry) * cols + (gx + rx)] != EMPTY:
                        ok = False
                        break
                if ok:
                    return True
        return False


# ═══════════════════════════════════════════
# Piece Generator (mirrors GDScript logic)
# ═══════════════════════════════════════════

TEMPLATES_EASY = [
    ([SizeCat.SMALL, SizeCat.MEDIUM, SizeCat.MEDIUM], 0.22),
    ([SizeCat.MEDIUM, SizeCat.MEDIUM, SizeCat.MEDIUM], 0.15),
    ([SizeCat.TINY, SizeCat.MEDIUM, SizeCat.MEDIUM], 0.13),
    ([SizeCat.SMALL, SizeCat.MEDIUM, SizeCat.LARGE], 0.12),
    ([SizeCat.TINY, SizeCat.MEDIUM, SizeCat.LARGE], 0.10),
    ([SizeCat.TINY, SizeCat.SMALL, SizeCat.MEDIUM], 0.10),
    ([SizeCat.SMALL, SizeCat.SMALL, SizeCat.MEDIUM], 0.08),
    ([SizeCat.MEDIUM, SizeCat.MEDIUM, SizeCat.HUGE], 0.05),
    ([SizeCat.TINY, SizeCat.SMALL, SizeCat.LARGE], 0.05),
]

TEMPLATES_MEDIUM = [
    ([SizeCat.SMALL, SizeCat.MEDIUM, SizeCat.MEDIUM], 0.25),
    ([SizeCat.TINY, SizeCat.MEDIUM, SizeCat.LARGE], 0.20),
    ([SizeCat.SMALL, SizeCat.SMALL, SizeCat.LARGE], 0.15),
    ([SizeCat.MEDIUM, SizeCat.MEDIUM, SizeCat.MEDIUM], 0.15),
    ([SizeCat.SMALL, SizeCat.MEDIUM, SizeCat.LARGE], 0.10),
    ([SizeCat.SMALL, SizeCat.LARGE, SizeCat.LARGE], 0.10),
    ([SizeCat.TINY, SizeCat.LARGE, SizeCat.HUGE], 0.05),
]

TEMPLATES_HARD = [
    ([SizeCat.SMALL, SizeCat.MEDIUM, SizeCat.LARGE], 0.25),
    ([SizeCat.MEDIUM, SizeCat.LARGE, SizeCat.LARGE], 0.20),
    ([SizeCat.SMALL, SizeCat.LARGE, SizeCat.HUGE], 0.15),
    ([SizeCat.MEDIUM, SizeCat.MEDIUM, SizeCat.LARGE], 0.15),
    ([SizeCat.LARGE, SizeCat.LARGE, SizeCat.LARGE], 0.10),
    ([SizeCat.TINY, SizeCat.LARGE, SizeCat.HUGE], 0.10),
    ([SizeCat.LARGE, SizeCat.HUGE, SizeCat.HUGE], 0.05),
]

TEMPLATES_EXPERT = [
    ([SizeCat.MEDIUM, SizeCat.LARGE], 0.30),
    ([SizeCat.SMALL, SizeCat.LARGE], 0.25),
    ([SizeCat.LARGE, SizeCat.LARGE], 0.20),
    ([SizeCat.MEDIUM, SizeCat.HUGE], 0.15),
    ([SizeCat.SMALL, SizeCat.HUGE], 0.10),
]

TEMPLATES_RUSH = [
    ([SizeCat.MEDIUM, SizeCat.LARGE, SizeCat.LARGE], 0.30),
    ([SizeCat.MEDIUM, SizeCat.MEDIUM, SizeCat.LARGE], 0.25),
    ([SizeCat.SMALL, SizeCat.LARGE, SizeCat.LARGE], 0.20),
    ([SizeCat.MEDIUM, SizeCat.LARGE, SizeCat.HUGE], 0.15),
    ([SizeCat.LARGE, SizeCat.LARGE, SizeCat.LARGE], 0.10),
]

EXCLUDED_LV1 = {PieceType.PENT_PLUS, PieceType.PENT_U, PieceType.PENT_N, PieceType.PENT_N_R, PieceType.PENT_N_V, PieceType.PENT_N_V2}
EXCLUDED_LV3 = {PieceType.PENT_PLUS, PieceType.PENT_U}
EXCLUDED_LV5 = {PieceType.PENT_PLUS}


class PieceGenerator:
    def __init__(self, cfg: SimConfig, rng: random.Random):
        self.cfg = cfg
        self.rng = rng
        self.prev_tray_types: list[int] = []
        self.tight_streak: int = 0

    def reset(self):
        self.prev_tray_types = []
        self.tight_streak = 0

    def _excluded(self, level: int) -> set:
        if level <= 2: return EXCLUDED_LV1
        if level <= 4: return EXCLUDED_LV3
        if level <= 7: return EXCLUDED_LV5
        return set()

    def _templates_for_level(self, level: int):
        if level <= 5: return [list(t) for t, w in TEMPLATES_EASY], [w for _, w in TEMPLATES_EASY]
        if level <= 15: return [list(t) for t, w in TEMPLATES_MEDIUM], [w for _, w in TEMPLATES_MEDIUM]
        if level >= self.cfg.expert_tray_reduce_level:
            return [list(t) for t, w in TEMPLATES_EXPERT], [w for _, w in TEMPLATES_EXPERT]
        return [list(t) for t, w in TEMPLATES_HARD], [w for _, w in TEMPLATES_HARD]

    def _apply_mercy(self, templates, weights, fill):
        if fill < self.cfg.dda_mercy_mild:
            return weights[:]
        new_w = weights[:]
        for i, t in enumerate(templates):
            has_small = any(c in (SizeCat.TINY, SizeCat.SMALL) for c in t)
            if fill >= self.cfg.dda_mercy_strong:
                new_w[i] *= 3.0 if has_small else 0.3
            else:
                new_w[i] *= 1.8 if has_small else 0.6
        return new_w

    def _pick_template(self, templates, weights) -> list[int]:
        return self.rng.choices(templates, weights=weights, k=1)[0]

    def _find_near_chain_color(self, board: BoardState) -> int:
        groups = board.find_color_groups(self.cfg.color_mercy_min_group)
        if not groups:
            return -1
        best = max(groups, key=len)
        x, y = best[0]
        return board.get_cell(x, y)

    def _pick_piece(self, cat: int, excluded: set, used: list, cluster_color: int,
                    level: int, board: BoardState, fill: float, mercy_color: int) -> BlockPiece:
        pool = [p for p in CATEGORY_PIECES[cat] if p not in excluded and p not in used]
        if not pool:
            pool = [p for p in CATEGORY_PIECES[cat] if p not in excluded]
        if not pool:
            pool = list(CATEGORY_PIECES[cat])

        # DDA fit check
        fit_chance = 0.0
        if fill >= self.cfg.dda_mercy_critical:
            fit_chance = self.cfg.dda_fit_critical_chance
        elif fill >= self.cfg.dda_mercy_mild:
            fit_chance = self.cfg.dda_fit_check_chance

        if fit_chance > 0 and self.rng.random() < fit_chance:
            placeable = [p for p in pool if board.can_place_type(p)]
            if placeable:
                pool = placeable

        # Weighted pick with anti-repetition
        weights = [0.4 if p in self.prev_tray_types else 1.0 for p in pool]
        chosen = self.rng.choices(pool, weights=weights, k=1)[0]

        # Color
        color_count = self.cfg.get_color_count(level)
        if mercy_color >= 0 and self.rng.random() < 0.50:
            color = mercy_color
        elif cluster_color >= 0 and self.rng.random() < self.cfg.color_cluster_chance:
            color = cluster_color
        else:
            color = self.rng.randint(0, color_count - 1)

        return BlockPiece(chosen, color, SHAPES[chosen])

    def _relief_tray(self, board: BoardState, level: int) -> list[BlockPiece]:
        tray = []
        cc = self.cfg.get_color_count(level)
        for cat in [SizeCat.TINY, SizeCat.SMALL, SizeCat.SMALL]:
            pool = list(CATEGORY_PIECES[cat])
            self.rng.shuffle(pool)
            placed = False
            for pt in pool:
                if board.can_place_type(pt):
                    tray.append(BlockPiece(pt, self.rng.randint(0, cc - 1), SHAPES[pt]))
                    placed = True
                    break
            if not placed:
                pt = pool[0]
                tray.append(BlockPiece(pt, self.rng.randint(0, cc - 1), SHAPES[pt]))
        self.prev_tray_types = [p.type for p in tray]
        return tray

    def _rescue_tray(self, tray: list[BlockPiece], board: BoardState, level: int) -> list[BlockPiece]:
        downsize = {SizeCat.HUGE: SizeCat.LARGE, SizeCat.LARGE: SizeCat.MEDIUM,
                    SizeCat.MEDIUM: SizeCat.SMALL, SizeCat.SMALL: SizeCat.TINY}
        cc = self.cfg.get_color_count(level)

        def _get_cat(pt):
            for c, types in CATEGORY_PIECES.items():
                if pt in types:
                    return c
            return SizeCat.MEDIUM

        # Level 1: downsize
        for i, piece in enumerate(tray):
            cat = _get_cat(piece.type)
            if cat in downsize:
                smaller = downsize[cat]
                pool = list(CATEGORY_PIECES[smaller])
                self.rng.shuffle(pool)
                for pt in pool:
                    if board.can_place_type(pt):
                        tray[i] = BlockPiece(pt, self.rng.randint(0, cc - 1), SHAPES[pt])
                        return tray

        # Level 2: any small piece
        for cat in [SizeCat.TINY, SizeCat.SMALL, SizeCat.MEDIUM]:
            pool = list(CATEGORY_PIECES[cat])
            self.rng.shuffle(pool)
            for pt in pool:
                if board.can_place_type(pt):
                    tray[0] = BlockPiece(pt, self.rng.randint(0, cc - 1), SHAPES[pt])
                    return tray

        # Level 3: single
        if board.has_any_empty():
            tray[0] = BlockPiece(PieceType.SINGLE, self.rng.randint(0, cc - 1), SHAPES[PieceType.SINGLE])

        return tray

    def generate_tray(self, level: int, board: BoardState) -> list[BlockPiece]:
        excluded = self._excluded(level)
        fill = board.fill_ratio()

        if self.tight_streak >= self.cfg.max_tight_streak and fill > 0.5:
            self.tight_streak = 0
            return self._relief_tray(board, level)

        if fill < self.cfg.dda_rush_threshold and self.rng.random() < self.cfg.dda_rush_chance:
            templates = [list(t) for t, w in TEMPLATES_RUSH]
            weights = [w for _, w in TEMPLATES_RUSH]
        else:
            templates, weights = self._templates_for_level(level)
            weights = self._apply_mercy(templates, weights, fill)

        template = self._pick_template(templates, weights)

        # Critical mercy: guarantee small piece
        if fill >= self.cfg.dda_mercy_critical:
            if not any(c in (SizeCat.TINY, SizeCat.SMALL) for c in template):
                template[0] = SizeCat.SMALL

        # Color mercy
        mercy_color = -1
        if fill > self.cfg.color_mercy_threshold and self.rng.random() < self.cfg.color_mercy_chance:
            mercy_color = self._find_near_chain_color(board)

        tray = []
        used = []
        first_color = -1
        for i, cat in enumerate(template):
            piece = self._pick_piece(cat, excluded, used, first_color if i > 0 else -1,
                                     level, board, fill, mercy_color)
            tray.append(piece)
            used.append(piece.type)
            if i == 0:
                first_color = piece.color

        self.prev_tray_types = [p.type for p in tray]

        if not board.can_place_any_piece(tray):
            tray = self._rescue_tray(tray, board, level)

        placeable = sum(1 for p in tray if board.can_place_type(p.type))
        if placeable <= 1:
            self.tight_streak += 1
        else:
            self.tight_streak = max(0, self.tight_streak - 1)

        return tray


# ═══════════════════════════════════════════
# Systems
# ═══════════════════════════════════════════

def check_blast(board: BoardState, rows: list[int], cols: list[int], cfg: SimConfig) -> dict:
    if not cfg.chroma_blast_enabled:
        return {"blast_colors": [], "trigger_lines": []}
    blast_colors = []
    trigger_lines = []
    th = cfg.chroma_blast_threshold
    bcells = board._cells
    bcols = board.cols
    for y in rows:
        counts: dict[int, int] = {}
        base = y * bcols
        for x in range(bcols):
            c = bcells[base + x]
            if c != EMPTY:
                counts[c] = counts.get(c, 0) + 1
        for c, cnt in counts.items():
            if cnt >= th and c not in blast_colors:
                blast_colors.append(c)
                trigger_lines.append({"type": "row", "index": y, "color": c})
    for x in cols:
        counts = {}
        for y in range(board.rows):
            c = bcells[y * bcols + x]
            if c != EMPTY:
                counts[c] = counts.get(c, 0) + 1
        for c, cnt in counts.items():
            if cnt >= th and c not in blast_colors:
                blast_colors.append(c)
                trigger_lines.append({"type": "col", "index": x, "color": c})
    return {"blast_colors": blast_colors, "trigger_lines": trigger_lines}


def execute_blast(board: BoardState, blast_colors: list[int]) -> dict:
    b = board.copy()
    cells = b._cells
    blast_set = set(blast_colors)
    removed = 0
    for i in range(len(cells)):
        if cells[i] in blast_set:
            cells[i] = EMPTY
            removed += 1
    b._occupied_count -= removed
    return {"board": b, "cells_removed": removed}


def process_chains(board: BoardState, cfg: SimConfig) -> dict:
    result = {"board": board, "cascades": 0, "total_cells_cleared": 0, "extra_lines_cleared": 0}
    if not cfg.chroma_chain_enabled:
        return result
    for _ in range(cfg.chroma_chain_max_cascade):
        groups = board.find_color_groups(cfg.chroma_chain_threshold)
        if not groups:
            break
        result["cascades"] += 1
        all_cells = []
        for g in groups:
            all_cells.extend(g)
            result["total_cells_cleared"] += len(g)
        board = board.remove_cells(all_cells)
        lr = board.clear_completed_lines()
        board = lr["board"]
        result["extra_lines_cleared"] += lr["lines_cleared"]
    result["board"] = board
    return result


def calculate_level(total_lines: int, cfg: SimConfig) -> int:
    level = 1
    remaining = total_lines
    needed = cfg.lines_for_next_level(level)
    while remaining >= needed:
        remaining -= needed
        level += 1
        needed = cfg.lines_for_next_level(level)
    return level


# ═══════════════════════════════════════════
# AI Player (greedy heuristic)
# ═══════════════════════════════════════════

class GreedyPlayer:
    """Greedy AI: evaluates placements using fast flat-array heuristic."""

    def __init__(self, cfg: SimConfig, rng: random.Random):
        self.cfg = cfg
        self.rng = rng

    def choose_move(self, board: BoardState, tray: list[BlockPiece]) -> Optional[tuple[int, int, int]]:
        """Returns (piece_index, gx, gy) or None if no move possible."""
        best_score = -999999.0
        best_move = None
        cells = board._cells
        cols = board.cols
        rows = board.rows

        for pi, piece in enumerate(tray):
            w, h = _PIECE_DIMS[piece.type]
            rel_cells = _PIECE_CELLS[piece.type]
            n_cells = len(rel_cells)
            max_gy = rows - h
            max_gx = cols - w

            for gy in range(max_gy + 1):
                for gx in range(max_gx + 1):
                    # Inline can_place check
                    ok = True
                    for rx, ry in rel_cells:
                        if cells[(gy + ry) * cols + (gx + rx)] != EMPTY:
                            ok = False
                            break
                    if not ok:
                        continue

                    # Fast inline eval
                    score = self._fast_eval_inline(cells, cols, rows, piece, gx, gy, rel_cells, n_cells)
                    if score > best_score:
                        best_score = score
                        best_move = (pi, gx, gy)
        return best_move

    @staticmethod
    def _fast_eval_inline(cells, cols, rows, piece, gx, gy, rel_cells, n_cells) -> float:
        """Fast heuristic on flat array."""
        # Build set of absolute indices for piece
        piece_indices = set()
        rows_touched = set()
        cols_touched = set()
        for rx, ry in rel_cells:
            ax, ay = gx + rx, gy + ry
            piece_indices.add(ay * cols + ax)
            rows_touched.add(ay)
            cols_touched.add(ax)

        lines = 0
        for row_y in rows_touched:
            base = row_y * cols
            full = True
            for x in range(cols):
                idx = base + x
                if cells[idx] == EMPTY and idx not in piece_indices:
                    full = False
                    break
            if full:
                lines += 1

        for col_x in cols_touched:
            full = True
            for y in range(rows):
                idx = y * cols + col_x
                if cells[idx] == EMPTY and idx not in piece_indices:
                    full = False
                    break
            if full:
                lines += 1

        score = lines * 1000.0
        score += gy * 5.0
        w = _PIECE_DIMS[piece.type][0]
        center_x = cols * 0.5
        score -= abs(gx + w * 0.5 - center_x) * 2.0
        score += n_cells * 3.0
        # Adjacency bonus
        adj = 0
        for pi_idx in piece_indices:
            py, px = divmod(pi_idx, cols)
            if px + 1 < cols and cells[pi_idx + 1] != EMPTY: adj += 1
            if px > 0 and cells[pi_idx - 1] != EMPTY: adj += 1
            if py + 1 < rows and cells[pi_idx + cols] != EMPTY: adj += 1
            if py > 0 and cells[pi_idx - cols] != EMPTY: adj += 1
        score += adj * 2.0
        return score


# ═══════════════════════════════════════════
# Game Simulation
# ═══════════════════════════════════════════

@dataclass
class GameResult:
    score: int = 0
    level: int = 1
    lines_cleared: int = 0
    pieces_placed: int = 0
    trays_generated: int = 0
    max_combo: int = 0
    chain_triggers: int = 0
    blast_triggers: int = 0
    perfect_clears: int = 0
    game_over_fill: float = 0.0


def simulate_game(cfg: SimConfig, seed: Optional[int] = None) -> GameResult:
    rng = random.Random(seed)
    gen = PieceGenerator(cfg, rng)
    player = GreedyPlayer(cfg, rng)
    board = BoardState(cfg.board_cols, cfg.board_rows)

    result = GameResult()
    combo = 0
    total_lines = 0

    max_trays = cfg.max_trays if hasattr(cfg, 'max_trays') else 500
    for _ in range(max_trays):  # cap to keep sim fast
        level = calculate_level(total_lines, cfg)
        result.level = level

        tray = gen.generate_tray(level, board)
        result.trays_generated += 1

        # Place pieces from tray one by one
        pieces_left = list(range(len(tray)))
        any_placed_this_tray = False

        while pieces_left:
            remaining = [tray[i] for i in pieces_left]
            move = player.choose_move(board, remaining)
            if move is None:
                break

            rem_idx, gx, gy = move
            actual_idx = pieces_left[rem_idx]
            piece = tray[actual_idx]
            pieces_left.remove(actual_idx)
            any_placed_this_tray = True
            result.pieces_placed += 1

            # Place
            board = board.place_piece(piece, gx, gy)
            placement_pts = piece.cell_count * cfg.placement_pts_per_cell

            # Check line clears
            cr = board.clear_completed_lines()
            lines = cr["lines_cleared"]

            # Blast check (before clearing)
            blast_pts = 0
            if lines > 0 and cfg.chroma_blast_enabled:
                blast_result = check_blast(board, cr["rows"], cr["cols"], cfg)
                if blast_result["blast_colors"]:
                    result.blast_triggers += 1
                    board_after_clear = cr["board"]
                    blast_exec = execute_blast(board_after_clear, blast_result["blast_colors"])
                    cr["board"] = blast_exec["board"]
                    blast_pts = (cfg.chroma_blast_trigger_bonus +
                                 blast_exec["cells_removed"] * cfg.chroma_blast_pts_per_cell +
                                 len(blast_result["trigger_lines"]) * cfg.chroma_blast_line_bonus)

            board = cr["board"]
            total_lines += lines

            # Chroma chain
            chain_pts = 0
            if lines > 0 and cfg.chroma_chain_enabled:
                chain_result = process_chains(board, cfg)
                board = chain_result["board"]
                if chain_result["cascades"] > 0:
                    result.chain_triggers += 1
                    total_lines += chain_result["extra_lines_cleared"]
                    for cascade_level in range(chain_result["cascades"]):
                        pts_idx = min(cascade_level, len(cfg.chroma_chain_pts_per_cell) - 1)
                        chain_pts += chain_result["total_cells_cleared"] * cfg.chroma_chain_pts_per_cell[pts_idx]

            # Perfect clear
            perfect_pts = 0
            if lines > 0 and board.is_empty:
                perfect_pts = cfg.perfect_clear_bonus
                result.perfect_clears += 1

            # Combo
            if lines > 0:
                combo += 1
                result.max_combo = max(result.max_combo, combo)
            else:
                combo = 0

            combo_idx = min(combo, len(cfg.combo_multipliers) - 1)
            multiplier = cfg.combo_multipliers[combo_idx]

            line_pts = cfg.line_clear_score(lines)
            bonus = round((line_pts + perfect_pts) * multiplier)
            result.score += placement_pts + bonus + blast_pts + chain_pts

        if not any_placed_this_tray:
            # Game over
            result.game_over_fill = board.fill_ratio()
            break

        # Check if remaining pieces can be placed
        remaining_pieces = [tray[i] for i in pieces_left]
        if remaining_pieces and not board.can_place_any_piece(remaining_pieces):
            # Skip unplaceable remaining pieces, not game over yet
            pass

    result.lines_cleared = total_lines
    return result


# ═══════════════════════════════════════════
# Batch Simulation + Grid Search
# ═══════════════════════════════════════════

def _sim_one(args):
    """Pickleable wrapper for multiprocessing."""
    cfg, seed = args
    return simulate_game(cfg, seed=seed)


def run_batch(cfg: SimConfig, n_games: int = 1000, base_seed: int = 42) -> dict:
    args = [(cfg, base_seed + i) for i in range(n_games)]
    # Use multiprocessing for larger batches
    if n_games >= 20:
        import os
        workers = min(os.cpu_count() or 4, n_games, 8)
        with ProcessPoolExecutor(max_workers=workers) as pool:
            results = list(pool.map(_sim_one, args, chunksize=max(1, n_games // workers)))
    else:
        results = [simulate_game(cfg, seed=base_seed + i) for i in range(n_games)]

    scores = [r.score for r in results]
    levels = [r.level for r in results]
    lines = [r.lines_cleared for r in results]
    pieces = [r.pieces_placed for r in results]
    combos = [r.max_combo for r in results]
    fills = [r.game_over_fill for r in results]

    def stats(data):
        n = len(data)
        s = sorted(data)
        return {
            "mean": sum(data) / n,
            "median": s[n // 2],
            "min": s[0],
            "max": s[-1],
            "p25": s[n // 4],
            "p75": s[3 * n // 4],
            "p90": s[int(n * 0.9)],
            "p95": s[int(n * 0.95)],
        }

    return {
        "n_games": n_games,
        "score": stats(scores),
        "level": stats(levels),
        "lines_cleared": stats(lines),
        "pieces_placed": stats(pieces),
        "max_combo": stats(combos),
        "game_over_fill": stats(fills),
        "chain_triggers": sum(r.chain_triggers for r in results),
        "blast_triggers": sum(r.blast_triggers for r in results),
        "perfect_clears": sum(r.perfect_clears for r in results),
    }


def grid_search(base_cfg: SimConfig, n_games: int = 200) -> list[dict]:
    """Run parameter grid search over key balance knobs."""
    variations = [
        ("baseline", {}),
        # DDA tuning
        ("dda_mercy_mild=0.35", {"dda_mercy_mild": 0.35}),
        ("dda_mercy_mild=0.45", {"dda_mercy_mild": 0.45}),
        ("dda_mercy_strong=0.55", {"dda_mercy_strong": 0.55}),
        ("dda_mercy_strong=0.65", {"dda_mercy_strong": 0.65}),
        ("dda_mercy_critical=0.70", {"dda_mercy_critical": 0.70}),
        ("dda_mercy_critical=0.80", {"dda_mercy_critical": 0.80}),
        # Rush mode
        ("dda_rush_threshold=0.15", {"dda_rush_threshold": 0.15}),
        ("dda_rush_threshold=0.25", {"dda_rush_threshold": 0.25}),
        ("dda_rush_chance=0.30", {"dda_rush_chance": 0.30}),
        ("dda_rush_chance=0.70", {"dda_rush_chance": 0.70}),
        # Chain threshold
        ("chain_threshold=4", {"chroma_chain_threshold": 4}),
        ("chain_threshold=6", {"chroma_chain_threshold": 6}),
        # Blast threshold
        ("blast_threshold=5", {"chroma_blast_threshold": 5}),
        ("blast_threshold=7", {"chroma_blast_threshold": 7}),
        # Combo multipliers
        ("combo_aggressive", {"combo_multipliers": [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0]}),
        ("combo_conservative", {"combo_multipliers": [1.0, 1.1, 1.2, 1.3, 1.5, 1.8, 2.0, 2.5]}),
        # Tight streak
        ("max_tight_streak=1", {"max_tight_streak": 1}),
        ("max_tight_streak=3", {"max_tight_streak": 3}),
        # Fit check
        ("dda_fit_check=0.50", {"dda_fit_check_chance": 0.50}),
        ("dda_fit_check=0.90", {"dda_fit_check_chance": 0.90}),
    ]

    results = []
    for name, overrides in variations:
        cfg = SimConfig()
        for k, v in overrides.items():
            setattr(cfg, k, v)
        t0 = time.time()
        batch = run_batch(cfg, n_games=n_games, base_seed=42)
        elapsed = time.time() - t0
        results.append({
            "name": name,
            "overrides": overrides,
            "elapsed_sec": round(elapsed, 2),
            "score_mean": round(batch["score"]["mean"]),
            "score_median": batch["score"]["median"],
            "score_p90": batch["score"]["p90"],
            "level_mean": round(batch["level"]["mean"], 1),
            "lines_mean": round(batch["lines_cleared"]["mean"], 1),
            "pieces_mean": round(batch["pieces_placed"]["mean"], 1),
            "combo_mean": round(batch["max_combo"]["mean"], 1),
            "fill_mean": round(batch["game_over_fill"]["mean"], 3),
            "chains_total": batch["chain_triggers"],
            "blasts_total": batch["blast_triggers"],
            "perfects_total": batch["perfect_clears"],
        })
        print(f"  [{name}] score={results[-1]['score_mean']:,} level={results[-1]['level_mean']} "
              f"lines={results[-1]['lines_mean']} ({elapsed:.1f}s)")

    return results


def main():
    config_path = Path(__file__).parent / "sim_config.json"
    if config_path.exists():
        with open(config_path) as f:
            user_cfg = json.load(f)
    else:
        user_cfg = {}

    n_games = user_cfg.get("n_games", 1000)
    do_grid = user_cfg.get("grid_search", True)
    grid_n = user_cfg.get("grid_n_games", 200)

    cfg = SimConfig()
    # Apply any config overrides
    for k, v in user_cfg.get("overrides", {}).items():
        if hasattr(cfg, k):
            setattr(cfg, k, v)

    print(f"═══ ChromaBlocks Simulator ═══")
    print(f"Running {n_games} games with default params...")
    t0 = time.time()
    baseline = run_batch(cfg, n_games=n_games)
    elapsed = time.time() - t0
    print(f"  Completed in {elapsed:.1f}s")
    print(f"  Score: mean={baseline['score']['mean']:,.0f} median={baseline['score']['median']:,} "
          f"p90={baseline['score']['p90']:,} p95={baseline['score']['p95']:,}")
    print(f"  Level: mean={baseline['level']['mean']:.1f} max={baseline['level']['max']}")
    print(f"  Lines: mean={baseline['lines_cleared']['mean']:.1f} max={baseline['lines_cleared']['max']}")
    print(f"  Pieces: mean={baseline['pieces_placed']['mean']:.1f}")
    print(f"  Combo: mean={baseline['max_combo']['mean']:.1f} max={baseline['max_combo']['max']}")
    print(f"  Fill@GameOver: mean={baseline['game_over_fill']['mean']:.3f}")
    print(f"  Chains: {baseline['chain_triggers']} | Blasts: {baseline['blast_triggers']} | Perfects: {baseline['perfect_clears']}")

    report = {"baseline": baseline, "config": {k: v for k, v in cfg.__dict__.items() if not k.startswith('_')}}

    if do_grid:
        print(f"\n═══ Grid Search ({grid_n} games each) ═══")
        grid_results = grid_search(cfg, n_games=grid_n)
        report["grid_search"] = grid_results

    # Write report
    report_path = Path(__file__).parent / "sim_report.json"
    # Convert non-serializable types
    def _serialize(obj):
        if isinstance(obj, (IntEnum, int)):
            return int(obj)
        if isinstance(obj, float):
            return round(obj, 4)
        raise TypeError(f"Not serializable: {type(obj)}")

    with open(report_path, "w") as f:
        json.dump(report, f, indent=2, default=_serialize)
    print(f"\n✅ Report saved to {report_path}")


if __name__ == "__main__":
    main()
