#!/usr/bin/env python3
"""Simulate different prefill strategies and measure first-line-clear turn."""
import random
from collections import Counter

ROWS, COLS = 8, 8
COLORS = 6
NUM_GAMES = 2000

# Piece templates (simplified subset)
PIECES = [
    [(0,0)],  # 1x1
    [(0,0),(1,0)],  # 1x2
    [(0,0),(0,1)],  # 2x1
    [(0,0),(1,0),(2,0)],  # 1x3
    [(0,0),(0,1),(0,2)],  # 3x1
    [(0,0),(1,0),(0,1)],  # L 2x2
    [(0,0),(1,0),(1,1)],  # L 2x2 variant
    [(0,0),(1,0),(2,0),(3,0)],  # 1x4
    [(0,0),(0,1),(0,2),(0,3)],  # 4x1
    [(0,0),(1,0),(0,1),(1,1)],  # 2x2 square
]

def make_board():
    return [[None for _ in range(COLS)] for _ in range(ROWS)]

def fill_ratio(board):
    count = sum(1 for r in board for c in r if c is not None)
    return count / (ROWS * COLS)

def is_row_complete(board, y):
    return all(board[y][x] is not None for x in range(COLS))

def is_col_complete(board, x):
    return all(board[y][x] is not None for y in range(ROWS))

def clear_lines(board):
    rows = [y for y in range(ROWS) if is_row_complete(board, y)]
    cols = [x for x in range(COLS) if is_col_complete(board, x)]
    for y in rows:
        for x in range(COLS):
            board[y][x] = None
    for x in cols:
        for y in range(ROWS):
            board[y][x] = None
    return len(rows) + len(cols)

def can_place(board, piece, gx, gy):
    for dx, dy in piece:
        nx, ny = gx + dx, gy + dy
        if nx < 0 or nx >= COLS or ny < 0 or ny >= ROWS:
            return False
        if board[ny][nx] is not None:
            return False
    return True

def place(board, piece, gx, gy, color):
    for dx, dy in piece:
        board[gy+dy][gx+dx] = color

def find_placements(board, piece):
    spots = []
    for gy in range(ROWS):
        for gx in range(COLS):
            if can_place(board, piece, gx, gy):
                spots.append((gx, gy))
    return spots

def prefill_strategy_bottom(board, rows=3, chance=0.65):
    """Current: fill bottom N rows with chance%."""
    for y in range(ROWS - rows, ROWS):
        filled = 0
        for x in range(COLS):
            if random.random() < chance:
                board[y][x] = random.randint(0, COLORS-1)
                filled += 1
        if filled >= COLS:
            rx = random.randint(0, COLS-1)
            board[y][rx] = None

def prefill_strategy_spread(board, target_ratio=0.35, near_complete_lines=2):
    """Spread fill + ensure some lines are near-complete for quick clears."""
    # First, create near-complete lines (leave 1-2 gaps)
    used_rows = set()
    same_color_rows = []
    for _ in range(near_complete_lines):
        y = random.randint(ROWS//2, ROWS-1)  # bottom half
        if y in used_rows:
            continue
        used_rows.add(y)
        color = random.randint(0, COLORS-1)
        gaps = random.randint(1, 2)
        gap_positions = random.sample(range(COLS), gaps)
        for x in range(COLS):
            if x not in gap_positions:
                board[y][x] = color  # same color for blast potential
        same_color_rows.append(y)
    
    # Fill rest to reach target ratio
    current = fill_ratio(board)
    empty_cells = [(y, x) for y in range(ROWS) for x in range(COLS) if board[y][x] is None]
    random.shuffle(empty_cells)
    
    idx = 0
    while current < target_ratio and idx < len(empty_cells):
        y, x = empty_cells[idx]
        # Don't complete any row or column
        board[y][x] = random.randint(0, COLORS-1)
        if is_row_complete(board, y) or is_col_complete(board, x):
            board[y][x] = None
        else:
            current = fill_ratio(board)
        idx += 1

def prefill_strategy_spread_v2(board, target_ratio=0.35):
    """Spread across bottom 5 rows, cluster same colors for chain potential."""
    fill_rows = 5
    target_cells = int(ROWS * COLS * target_ratio)
    placed = 0
    
    # Place color clusters (2-4 adjacent same color)
    for _ in range(6):
        color = random.randint(0, COLORS-1)
        y = random.randint(ROWS - fill_rows, ROWS - 1)
        x = random.randint(0, COLS - 2)
        length = random.randint(2, 4)
        for dx in range(length):
            nx = x + dx
            if nx < COLS and board[y][nx] is None:
                board[y][nx] = color
                placed += 1
    
    # Fill remaining randomly in bottom rows
    empty = [(y, x) for y in range(ROWS - fill_rows, ROWS) for x in range(COLS) if board[y][x] is None]
    random.shuffle(empty)
    for y, x in empty:
        if placed >= target_cells:
            break
        board[y][x] = random.randint(0, COLORS-1)
        if is_row_complete(board, y) or is_col_complete(board, x):
            board[y][x] = None
        else:
            placed += 1

def simulate(prefill_fn, label, n=NUM_GAMES):
    first_clear_turns = []
    clears_in_5 = []  # line clears within first 5 turns
    game_overs_before_10 = 0
    fill_ratios = []
    
    for _ in range(n):
        board = make_board()
        prefill_fn(board)
        fill_ratios.append(fill_ratio(board))
        
        first_clear = None
        total_clears_5 = 0
        
        for turn in range(1, 101):
            # Pick random piece and try to place
            piece = random.choice(PIECES)
            color = random.randint(0, COLORS-1)
            spots = find_placements(board, piece)
            if not spots:
                if turn < 10:
                    game_overs_before_10 += 1
                break
            gx, gy = random.choice(spots)
            place(board, piece, gx, gy, color)
            lines = clear_lines(board)
            if lines > 0:
                if first_clear is None:
                    first_clear = turn
                if turn <= 5:
                    total_clears_5 += lines
        
        if first_clear is not None:
            first_clear_turns.append(first_clear)
        clears_in_5.append(total_clears_5)
    
    avg_fill = sum(fill_ratios) / len(fill_ratios) * 100
    avg_first = sum(first_clear_turns) / len(first_clear_turns) if first_clear_turns else -1
    pct_clear_by_3 = sum(1 for t in first_clear_turns if t <= 3) / n * 100
    pct_clear_by_5 = sum(1 for t in first_clear_turns if t <= 5) / n * 100
    avg_clears_5 = sum(clears_in_5) / len(clears_in_5)
    
    print(f"\n{'='*60}")
    print(f"  {label}")
    print(f"{'='*60}")
    print(f"  평균 초기 fill: {avg_fill:.1f}%")
    print(f"  첫 라인클리어 턴: 평균 {avg_first:.1f}")
    print(f"  3턴 이내 클리어: {pct_clear_by_3:.1f}%")
    print(f"  5턴 이내 클리어: {pct_clear_by_5:.1f}%")
    print(f"  5턴 내 평균 라인클리어 수: {avg_clears_5:.2f}")
    print(f"  10턴 전 게임오버: {game_overs_before_10} ({game_overs_before_10/n*100:.1f}%)")

print("ChromaBlocks Prefill Strategy Simulation")
print(f"Games per strategy: {NUM_GAMES}")

simulate(lambda b: prefill_strategy_bottom(b, 3, 0.65), "현재: 하단 3줄 65%")
simulate(lambda b: prefill_strategy_spread(b, 0.30, 1), "Spread 30% + 1 near-complete")
simulate(lambda b: prefill_strategy_spread(b, 0.35, 2), "Spread 35% + 2 near-complete")
simulate(lambda b: prefill_strategy_spread(b, 0.40, 2), "Spread 40% + 2 near-complete")
simulate(lambda b: prefill_strategy_spread_v2(b, 0.30), "Cluster 30% (하단5줄)")
simulate(lambda b: prefill_strategy_spread_v2(b, 0.35), "Cluster 35% (하단5줄)")
simulate(lambda b: prefill_strategy_spread_v2(b, 0.40), "Cluster 40% (하단5줄)")
simulate(lambda b: prefill_strategy_bottom(b, 4, 0.60), "하단 4줄 60%")
simulate(lambda b: prefill_strategy_bottom(b, 5, 0.50), "하단 5줄 50%")
