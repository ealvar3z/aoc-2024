#!/usr/bin/env python3
"""
Advent of Code 2024 - Day 15: Warehouse Woes

Part 1:
    Single-cell boxes 'O', robot '@', walls '#', empty '.'.
    Robot pushes chains of boxes horizontally/vertically until blocked by wall.
    After all moves, sum box GPS coordinates:
        GPS = 100 * row + col

Part 2:
    Map is scaled horizontally:
        '#' -> '##'
        '.' -> '..'
        'O' -> '[]'
        '@' -> '@.'
    Robot remains single-cell '@'.
    Boxes are now 2-wide: '[' is left half, ']' is right half.
    Horizontal pushes: same idea as Part 1, but '[]' pairs slide.
    Vertical pushes: pushing one box can require pushing a whole "cluster"
    of overlapping 2-wide boxes at once. We resolve this by a small BFS
    over boxes to see if the move is possible, then move the whole cluster.

    GPS for Part 2 is measured from the closest edge of the box, i.e. the
    left cell of each '[]' pair:
        GPS = 100 * row + col_of_left_bracket
"""

import sys

def read_input():
    """
    Read all lines from stdin and split into (map_lines, moves_string).

    Returns:
        grid_lines : list of strings (warehouse map, Part 1 form)
        moves      : string of movement characters (^ v < >), no newlines
    """
    lines = [line.rstrip("\n") for line in sys.stdin]

    separator_index = None
    for i, line in enumerate(lines):
        if line == "":
            separator_index = i
            break

    if separator_index is None:
        grid_lines = lines
        moves_lines = []
    else:
        grid_lines = lines[:separator_index]
        moves_lines = lines[separator_index + 1:]

    moves = "".join(moves_lines)
    return grid_lines, moves


def direction_delta(ch):
    """
    Convert move character to (dr, dc).

    '^' -> (-1, 0)
    'v' -> (1, 0)
    '<' -> (0, -1)
    '>' -> (0, 1)
    """
    if ch == "^":
        return -1, 0
    if ch == "v":
        return 1, 0
    if ch == "<":
        return 0, -1
    if ch == ">":
        return 0, 1
    raise ValueError("Unknown move character: %r" % ch)


# Part 1: Single-cell boxes 'O'
def build_grid_part1(grid_lines):
    """
    Build mutable grid for Part 1 and find robot position.

    Returns:
        grid       : list[list[str]]
        robot_row  : int
        robot_col  : int
    """
    grid = []
    robot_row = -1
    robot_col = -1

    for r, line in enumerate(grid_lines):
        row = list(line)
        grid.append(row)
        for c, ch in enumerate(row):
            if ch == "@":
                robot_row = r
                robot_col = c

    if robot_row < 0 or robot_col < 0:
        raise ValueError("Robot '@' not found in Part 1 grid")

    return grid, robot_row, robot_col


def attempt_move_part1(grid, rr, cc, dr, dc):
    """
    Attempt to move robot one step (dr, dc) in Part 1 (O-boxes).

    Rules:
        - '#' blocks.
        - '.' free.
        - 'O' chain of adjacent boxes in direction moves if next after chain is '.'.
    """
    rows = len(grid)
    cols = len(grid[0])

    nr = rr + dr
    nc = cc + dc

    if nr < 0 or nr >= rows or nc < 0 or nc >= cols:
        return rr, cc

    tile = grid[nr][nc]

    if tile == "#":
        return rr, cc

    if tile == ".":
        grid[rr][cc] = "."
        grid[nr][nc] = "@"
        return nr, nc

    if tile == "O":
        # Collect chain of boxes.
        boxes = []
        cr = nr
        cc2 = nc
        while 0 <= cr < rows and 0 <= cc2 < cols and grid[cr][cc2] == "O":
            boxes.append((cr, cc2))
            cr += dr
            cc2 += dc

        if not (0 <= cr < rows and 0 <= cc2 < cols):
            return rr, cc

        if grid[cr][cc2] != ".":
            # Wall or robot or something else: cannot push.
            return rr, cc

        # Push boxes from farthest to nearest.
        for br, bc in reversed(boxes):
            dr_dst = br + dr
            dc_dst = bc + dc
            grid[dr_dst][dc_dst] = "O"
            grid[br][bc] = "."

        grid[rr][cc] = "."
        grid[nr][nc] = "@"
        return nr, nc

    return rr, cc


def run_simulation_part1(grid, rr, cc, moves):
    """
    Run all moves for Part 1.

    Returns:
        final_grid, final_rr, final_cc
    """
    r = rr
    c = cc
    for ch in moves:
        dr, dc = direction_delta(ch)
        r, c = attempt_move_part1(grid, r, c, dr, dc)
    return grid, r, c


def compute_gps_sum_part1(grid):
    """
    GPS sum for Part 1:
        For each 'O', add 100 * row + col.
    """
    total = 0
    for r, row in enumerate(grid):
        for c, ch in enumerate(row):
            if ch == "O":
                total += 100 * r + c
    return total


# Part 2: Scaled map, 2-wide boxes '[]'
def scale_grid_lines_for_part2(grid_lines):
    """
    Scale the original grid horizontally for Part 2.

    Mapping per cell:
        '#': '##'
        '.': '..'
        'O': '[]'
        '@': '@.'
    Returns:
        list of strings (scaled lines).
    """
    scaled_lines = []
    for line in grid_lines:
        out = []
        for ch in line:
            if ch == "#":
                out.append("##")
            elif ch == ".":
                out.append("..")
            elif ch == "O":
                out.append("[]")
            elif ch == "@":
                out.append("@.")
            else:
                raise ValueError("Unexpected character in original map: %r" % ch)
        scaled_lines.append("".join(out))
    return scaled_lines


def build_grid_part2(scaled_lines):
    """
    Build mutable grid for Part 2 and find robot position.

    Returns:
        grid       : list[list[str]]
        robot_row  : int
        robot_col  : int
    """
    grid = []
    robot_row = -1
    robot_col = -1

    for r, line in enumerate(scaled_lines):
        row = list(line)
        grid.append(row)
        for c, ch in enumerate(row):
            if ch == "@":
                robot_row = r
                robot_col = c

    if robot_row < 0 or robot_col < 0:
        raise ValueError("Robot '@' not found in Part 2 grid")

    return grid, robot_row, robot_col


def attempt_move_part2(grid, rr, cc, dr, dc):
    """
    Attempt to move robot one step (dr, dc) in Part 2 (2-wide boxes '[]').

    Horizontal:
        Treat '[' and ']' as contiguous box cells;
        slide a run of them if the next cell is '.'.

    Vertical:
        Boxes move as 2-wide units. Pushing one box can trigger a vertical
        "cluster" of boxes that all must move. We:
            1) Collect all affected boxes via BFS on boxes.
            2) If any destination cell is '#', fail.
            3) Otherwise, clear all these boxes, then re-place them shifted.
    """
    rows = len(grid)
    cols = len(grid[0])

    # Horizontal moves are simpler; vertical moves need special logic.
    if dc != 0:
        nr = rr
        nc = cc + dc
        if nr < 0 or nr >= rows or nc < 0 or nc >= cols:
            return rr, cc

        tile = grid[nr][nc]
        if tile == "#":
            return rr, cc
        if tile == ".":
            grid[rr][cc] = "."
            grid[nr][nc] = "@"
            return nr, nc
        if tile in ("[", "]"):
            # Slide contiguous run of '['/']' cells.
            cells = []
            cr = nr
            cc2 = nc
            while 0 <= cr < rows and 0 <= cc2 < cols and grid[cr][cc2] in ("[", "]"):
                cells.append((cr, cc2))
                cr += dr
                cc2 += dc

            if not (0 <= cr < rows and 0 <= cc2 < cols):
                return rr, cc

            if grid[cr][cc2] != ".":
                return rr, cc

            # Push from farthest to nearest.
            for br, bc in reversed(cells):
                dr_dst = br + dr
                dc_dst = bc + dc
                grid[dr_dst][dc_dst] = grid[br][bc]
                grid[br][bc] = "."

            grid[rr][cc] = "."
            grid[nr][nc] = "@"
            return nr, nc

        return rr, cc

    # Vertical move (dc == 0): need box-cluster logic.
    nr = rr + dr
    nc = cc

    if nr < 0 or nr >= rows or nc < 0 or nc >= cols:
        return rr, cc

    tile = grid[nr][nc]
    if tile == "#":
        return rr, cc
    if tile == ".":
        grid[rr][cc] = "."
        grid[nr][nc] = "@"
        return nr, nc

    if tile not in ("[", "]"):
        # Unknown/robot/etc: ??? wtf.
        return rr, cc

    # BFS over 2-wide boxes.
    boxes_to_move = set()
    queue = []

    def add_box_at_cell(r, c):
        # the cell is known to be '[' or ']', add its entire box.
        if grid[r][c] == "[":
            left_c = c
        elif grid[r][c] == "]":
            left_c = c - 1
        else:
            return
        if (r, left_c) not in boxes_to_move:
            boxes_to_move.add((r, left_c))
            queue.append((r, left_c))

    add_box_at_cell(nr, nc)

    # Collect all boxes that need to move.
    while queue:
        br, bc_left = queue.pop()
        dest_r = br + dr

        # Two cells of this box: (br, bc_left) '[' and (br, bc_left+1) ']'
        for dest_c in (bc_left, bc_left + 1):
            if dest_r < 0 or dest_r >= rows or dest_c < 0 or dest_c >= cols:
                return rr, cc  # out of bounds, blocked

            cell = grid[dest_r][dest_c]

            if cell == "#":
                return rr, cc  # blocked by wall

            if cell == "." or cell == "@":
                # Empty or robot's current location; fine.
                continue

            if cell in ("[", "]"):
                # Another box that must also move.
                add_box_at_cell(dest_r, dest_c)
                continue

            # Any other tile type: treat as blocked.
            return rr, cc

    # If we reach here, movement is possible.
    for br, bc_left in boxes_to_move:
        grid[br][bc_left] = "."
        grid[br][bc_left + 1] = "."

    # Then place them at shifted positions.
    for br, bc_left in boxes_to_move:
        dest_r = br + dr
        dest_c = bc_left
        grid[dest_r][dest_c] = "["
        grid[dest_r][dest_c + 1] = "]"

    # Finally, move the robot.
    grid[rr][cc] = "."
    grid[nr][nc] = "@"
    return nr, nc


def run_simulation_part2(grid, rr, cc, moves):
    """
    Run all moves for Part 2.
    """
    r = rr
    c = cc
    for ch in moves:
        dr, dc = direction_delta(ch)
        r, c = attempt_move_part2(grid, r, c, dr, dc)
    return grid, r, c


def compute_gps_sum_part2(grid):
    """
    GPS sum for Part 2:
        For each box, add 100 * row + col_of_left_bracket.

    Boxes are represented as '[' at (r, c) and ']' at (r, c+1).
    """
    total = 0
    for r, row in enumerate(grid):
        for c, ch in enumerate(row):
            if ch == "[":
                total += 100 * r + c
    return total


def main():
    grid_lines, moves = read_input()

    # Part 1
    grid1, r1, c1 = build_grid_part1(grid_lines)
    grid1, r1, c1 = run_simulation_part1(grid1, r1, c1, moves)
    part1_answer = compute_gps_sum_part1(grid1)

    # Part 2: scale, then simulate on 2-wide boxes.
    scaled_lines = scale_grid_lines_for_part2(grid_lines)
    grid2, r2, c2 = build_grid_part2(scaled_lines)
    grid2, r2, c2 = run_simulation_part2(grid2, r2, c2, moves)
    part2_answer = compute_gps_sum_part2(grid2)

    print("Part 1:", part1_answer)
    print("Part 2:", part2_answer)


if __name__ == "__main__":
    main()

