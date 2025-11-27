#!/usr/bin/env python3

import sys

GRID_WIDTH      = 101
GRID_HEIGHT     = 103
PART1_SECONDS   = 100

# Positions repeat due to motion being module width/height
# Period is lcm(width, height). 101 and 103 are prime, so:
PERIOD = GRID_WIDTH * GRID_HEIGHT # 10403

def compute_safety_factor(positions, width, height):
    quadrant_counts = [0, 0, 0, 0]
    for x, y in positions:
        quadrant = compute_quadrant_index(x, y, width, height)
        if quadrant is not None:
            quadrant_counts[quadrant] += 1

    safety_factor = (
        quadrant_counts[0]
        * quadrant_counts[1]
        * quadrant_counts[2]
        * quadrant_counts[3]
    )
    return safety_factor

def compute_quadrant_index(x, y, width, height):
    mid_x = width // 2
    mid_y = height // 2

    if x == mid_x or y == mid_y:
        return None

    if x < mid_x and y < mid_y:
        return 0  # top-left
    if x > mid_x and y < mid_y:
        return 1  # top-right
    if x < mid_x and y > mid_y:
        return 2  # bottom-left
    if x > mid_x and y > mid_y:
        return 3  # bottom-right

    return None  # this should not be reached

# Part 2: Find time of Xmas tree
def bounding_box_area(positions):
    xs = [p[0] for p in positions]
    ys = [p[1] for p in positions]

    min_x = min(xs)
    max_x = max(xs)
    min_y = min(ys)
    max_y = max(ys)

    width = max_x - min_x + 1
    height = max_y - min_y + 1

    return width * height

def find_tree_time(robots, width, height, period):
    num_robots = len(robots)

    for t in range(1, period + 1):
        positions = positions_at_time(robots, t, width, height)
        if len(set(positions)) == num_robots:
            return t

    raise RuntimeError("No unique-position time found w/in one period") # should not be reached

def future_pos(x, y, vx, vy, secs, width, height):
    # Correct kinematics: x + vx * t (with wrap)
    future_x = (x + vx * secs) % width
    future_y = (y + vy * secs) % height
    return future_x, future_y

def positions_at_time(robots, seconds, width, height):
    positions = []
    for x, y, vx, vy in robots:
        fx, fy = future_pos(x, y, vx, vy, seconds, width, height)
        positions.append((fx, fy))
    return positions

def read_robots():
    robots = []
    for line in sys.stdin:
        stripped = line.strip()
        if not stripped:
            continue
        robot = parse_robot(stripped)
        robots.append(robot)

    return robots

def parse_robot(line):
    line = line.strip()
    if not line:
        raise ValueError("Empty Line")

    parts = line.split()
    if len(parts) != 2:
        raise ValueError("Line does not have exactly two fields: %r" % line)

    pos_part, vel_part = parts

    if not pos_part.startswith("p=") or not vel_part.startswith("v="):
        raise ValueError("Line does not start with 'p=' and 'v=': %r" % line)

    pos_str = pos_part[2:]
    vel_str = vel_part[2:]

    try:
        x_str, y_str = pos_str.split(",")
        vx_str, vy_str = vel_str.split(",")
    except ValueError as exc:
        raise ValueError("Position/Velocity not in x,y format: %r" % line) from exc

    x = int(x_str)
    y = int(y_str)
    vx = int(vx_str)
    vy = int(vy_str)

    return x, y, vx, vy

def main():
    robots = read_robots()
    
    # Part 1
    positions_100 = positions_at_time(
        robots,
        PART1_SECONDS,
        GRID_WIDTH,
        GRID_HEIGHT,
    )
    part1_answer = compute_safety_factor(
        positions_100,
        GRID_WIDTH,
        GRID_HEIGHT,
    )

    # Part 2
    part2_answer = find_tree_time(
        robots,
        GRID_WIDTH,
        GRID_HEIGHT,
        PERIOD,
    )
    
    print("Part 1:", part1_answer)
    print("Part 2:", part2_answer)


if __name__ == "__main__":
    main()

