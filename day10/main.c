#include <stdint.h>
#include <sys/types.h>

#include "aoc.h"

static void
check(int cond, const char *expr, int line)
{
  if (!cond) {
    fprintf(stderr, "assertion failed: %s (line %d)\n", expr, line);
    exit(1);
  }
}

#define ASSERT(c) check((c), #c, __LINE__)

#define MAX_H 200u
#define MAX_W 200u
#define MAX_CELLS (MAX_H *MAX_W)

struct topo {
  int8_t grid[MAX_H][MAX_W];
  size_t h;
  size_t w;
};

struct pos {
  uint16_t y;
  uint16_t x;
};
    
// 4-way neighbors
static const int dy[4] = { -1, 1, 0, 0 };
static const int dx[4] = { 0, 0, -1, 1 };

static void
parse_topo(struct topo *t, const struct aoc_buf *b)
{
  size_t row = 0u;
  size_t col = 0u;
  size_t width = 0u;
  const char *s;

  ASSERT(t != NULL);
  ASSERT(b != NULL);
  ASSERT(b->p != NULL);

  s = b->p;

  for (size_t i = 0u; s[i] != '\0';i++) {
    char c = s[i];
    if (c == '\n') {
      ASSERT(col > 0u);
      if (row == 0u) {
        width = col;
      } else {
        ASSERT(col == width);
      }
      row++;
      ASSERT(row < MAX_H);
      col = 0u;
    } else {
      ASSERT(c >= '0' && c <= '9');
      ASSERT(col < MAX_W);
      t->grid[row][col] = (int8_t)(c - '0');
      col++;
    }
  }

  if (col > 0u) {
    if (row == 0u) {
      width = col;
    } else {
      ASSERT(col == width);
    }
    row++;
  }
  ASSERT(row > 0u);
  ASSERT(width > 0u);
  ASSERT(row <= MAX_H);
  ASSERT(width <= MAX_W);

  t->h = row;
  t->w = width;

  ASSERT(t->h <= MAX_H);
  ASSERT(t->w <= MAX_W);
}

// compute the score for a single trailhead (sy, sx)
static uint64_t
trailhead_score(const struct topo *t, size_t sy, size_t sx)
{
  struct pos queue[MAX_CELLS];
  uint8_t visited[MAX_H][MAX_W];
  uint8_t reached9[MAX_H][MAX_W];
  size_t head = 0u;
  size_t tail = 0u;
  uint64_t score = 0u;

  ASSERT(t != NULL);
  ASSERT(sy < t->h);
  ASSERT(sx < t->w);
  ASSERT(t->grid[sy][sx] == 0);

  for (size_t y = 0u; y < t->h; y++) {
    for (size_t x = 0u; x < t->w; x++) {
      visited[y][x] = 0u;
      reached9[y][x] = 0u;
    }
  }
  queue[tail].y = (uint16_t)sy;
  queue[tail].x = (uint16_t)sx;
  tail++;
  visited[sy][sx] = 1u;

  ASSERT(tail <= MAX_CELLS);

  while (head < tail) {
    struct pos p = queue[head];
    uint16_t y = p.y;
    uint16_t x = p.x;
    int8_t h = t->grid[y][x];

    head++;

    if (h == 9) {
      if (reached9[y][x] == 0u) {
        reached9[y][x] = 1u;
        score++;
      }
      continue;
    }

    for (size_t k = 0u; k < 4u; k++) {
      int ny = (int)y + dy[k];
      int nx = (int)x + dx[k];

      if (ny < 0 || nx < 0) {
        continue;
      }
      if ((size_t)ny >= t->h || (size_t)nx >= t->w) {
        continue;
      }
      if (visited[ny][nx] != 0u &&
          t->grid[ny][nx] == h + 1) {
        // we visited this cell; don't add it
        continue;
      }
      if (t->grid[ny][nx] == h + 1) {
        visited[ny][nx] = 1u;
        queue[tail].y = (uint16_t)ny;
        queue[tail].x = (uint16_t)nx;
        tail++;
        ASSERT(tail <= MAX_CELLS);
      }
    }
  }
  ASSERT(score <= (uint64_t)t->h * t->w);
  return score;
}

static uint64_t
solve_part1(const struct topo *t)
{
  uint64_t total = 0u;
  ASSERT(t != NULL);

  for (size_t y = 0u; y < t->h; y++) {
    for (size_t x = 0u; x < t->w; x++) {
      if (t->grid[y][x] == 0) {
        uint64_t sc = trailhead_score(t, y, x);
        total += sc;
      }
    }
  }
  ASSERT(total);
  return total;
}

static uint64_t
solve_part2(const struct topo *t)
{
  uint64_t ways[MAX_H][MAX_W];
  uint64_t total = 0u;
  for (size_t y = 0u; y < t->h; y++) {
    for (size_t x = 0u; x < t->w; x++) {
      ways[y][x] = 0u;
    }
  }

  for (int h = 9; h >= 0; h--) {
    for (size_t y = 0u; y < t->h; y++) {
      for (size_t x = 0u; x < t->w; x++) {
        if (t->grid[y][x] != h) {
          continue;
        }
        if (h == 9) {
          ways[y][x] = 1u;
        } else {
          uint64_t sum = 0u;
          for (size_t k = 0u; k < 4u; k++) {
            int ny = (int)y + dy[k];
            int nx = (int)x + dx[k];

            if (ny < 0 || nx < 0) {
              continue;
            }
            if ((size_t)ny >= t->h || (size_t)nx >= t->w) {
              continue;
            }
            if (t->grid[ny][nx] == h + 1) {
              sum += ways[ny][nx];
            }
          }
          ways[y][x] = sum;
        }
      }
    }
  }
  // sum the ratins
  for (size_t y = 0u; y < t->h; y++) {
    for (size_t x = 0u; x < t->w; x++) {
      if (t->grid[y][x] == 0) {
        total += ways[y][x];
      }
    }
  }
  ASSERT(total);
  return total;
}

int
main(void)
{
  struct aoc_buf buf;
  struct topo topo;
  uint64_t part1;
  uint64_t part2;

  int ok = read_file("input.txt", NULL, &buf);
  if (!ok) {
    fprintf(stderr, "read failed\n");
    return 1;
  }
  chomp(buf.p);
  parse_topo(&topo, &buf);

  part1 = solve_part1(&topo);
  part2 = solve_part2(&topo);

  printf("Part 1: %llu\n", (unsigned long long)part1);
  printf("Part 2: %llu\n", (unsigned long long)part2);

  free(buf.p);
  return 0;
}
