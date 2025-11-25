#include <limits.h>
#include <stdint.h>
#include <sys/types.h>

#include "aoc.h"

#define MAX_INPUT_LEN 10000u
#define MAX_STATES    1000000u
#define PART1_STEPS   25u
#define PART2_STEPS   75u

struct state {
  uint64_t val;
  uint64_t count;
  uint64_t used;
};

struct map {
  struct state st[MAX_STATES];
  size_t size;
};

// pre-compute powers of 10 to split digits
static uint64_t pow10_table[20];

// basic hash function for uint64_t
static size_t
hash_u64(uint64_t x)
{
  // mix 64-bit, then modulo table size
  x ^= x >> 33;
  x *= 0xff51afd7ed558ccdULL;
  x ^= x >> 33;
  x *= 0xc4ceb9fe1a85ec53ULL;
  x ^= x >> 33;
  size_t hashed = (size_t)(x % (uint64_t)MAX_STATES);

  return hashed;
}

static void
map_clear(struct map *m)
{
  ASSERT(m != NULL);

  for (size_t i = 0u; i < MAX_STATES; i++) {
    m->st[i].val = 0u;
    m->st[i].count = 0u;
    m->st[i].used = 0u;
  }
  m->size = 0u;
  ASSERT(m->size == 0u);
}

static void
map_add(struct map *m, uint64_t val, uint64_t delta)
{
  size_t idx;
  size_t start;

  ASSERT(m != NULL);
  ASSERT(delta > 0);

  idx = hash_u64(val);
  start = idx;

  for (size_t probe = 0u; probe < MAX_STATES; probe++) {
    struct state *s = &m->st[idx];

    if (!s->used) {
      s->used = 1u;
      s->val = val;
      s->count = delta;
      m->size++;
      ASSERT(m->size <= MAX_STATES);
      return;
    }
    if (s->val == val) {
      s->count += delta;
      return;
    }
    idx++;
    if (idx == MAX_STATES) {
      idx = 0u;
    }
    ASSERT(idx != start || probe + 1u < MAX_STATES);
  }
  ASSERT(0); // should never happen UNLESS MAX_STATES is not large enough
}

// count decimal digits of v (1..19), 0 has 1 digit
static int
count_digits(uint64_t v)
{
  if (v == 0u) {
    return 1;
  }
  int d = 1;
  while (d < 20 && v >= pow10_table[d]) {
    d++;
  }
  return d; 
}

// split an even-digit num v into left & right halves
static void
split_even_digits(uint64_t v, int digits,
                  uint64_t *left, uint64_t *right)
{
  int half;
  uint64_t p10;

  ASSERT(digits > 0);
  ASSERT((digits & 1) == 0);
  ASSERT(left != NULL);
  ASSERT(right != NULL);

  half = digits / 2;
  p10 = pow10_table[half];

  *right = v % p10;
  *left = v / p10;
  // leading zeroes automatically dropped by integer arithmetic
}

// apply one blink: src -> dst according to stone rules
static void
step(const struct map *src, struct map *dst)
{
  ASSERT(src != NULL);
  ASSERT(dst != NULL);

  map_clear(dst);

  for (size_t i = 0u; i < MAX_STATES; i++) {
    if (!src->st[i].used) {
      continue;
    }
    uint64_t v = src->st[i].val;
    uint64_t c = src->st[i].count;

    if (v == 0u) {
      // Rule 1: 0 -> 1
      map_add(dst, 1u, c);
    } else {
      int d = count_digits(v);
      if ((d &1) == 0) {
        // Rule 2: even digits -> split
        uint64_t left;
        uint64_t right;
        split_even_digits(v, d, &left, &right);
        map_add(dst, left, c);
        map_add(dst, right, c);
      } else {
        // Rule 3: mult by 2024
        __uint128_t tmp = (__uint128_t)v * 2024;
        ASSERT(tmp <= ( (__uint128_t)UINT64_MAX));
        uint64_t nv = (uint64_t)tmp;
        map_add(dst, nv, c); // we're assuming no overflow here from the puzzle input
      }
    }
  }
}

static void
parse_initial(struct map *m, const struct aoc_buf *b)
{
  uint64_t v = 0u;
  int in_num = 0;
  const char *s;

  ASSERT(m != NULL);
  ASSERT(b != NULL);
  ASSERT(b->p != NULL);
  ASSERT(b->n < MAX_INPUT_LEN);
  s = b->p;

  for (size_t i = 0u; i < b->n; i++) {
    char c = s[i];
    if (c >= '0' && c <= '9') {
      v = v * 10u + (uint64_t)(c - '0');
      in_num = 1;
    } else {
      if (in_num) {
        map_add(m, v, 1u);
        v = 0u;
        in_num = 0;
      }
    }
  }
  if (in_num) {
    map_add(m, v, 1u);
  }
  ASSERT(m->size > 0u);
}

static uint64_t
sum_counts(const struct map *m)
{
  uint64_t total = 0u;
  ASSERT(m != NULL);

  for (size_t i = 0u; i < MAX_STATES; i++) {
    if (m->st[i].used) {
      total += m->st[i].count;
    }
  }
  ASSERT(total);
  return total;
}

static void
map_copy(const struct map *src, struct map *dst)
{
  ASSERT(src != NULL);
  ASSERT(dst != NULL);
  for (size_t i = 0u; i < MAX_STATES; i++) {
    dst->st[i] = src->st[i];
  }
  dst->size = src->size;
}


static struct map g_init_map;
static struct map g_work0;
static struct map g_work1;

int
main(void)
{
  struct aoc_buf buf;
  struct map *cur;
  struct map *next;

  // init pow10_table
  pow10_table[0] = 1u;
  for (int i = 1; i < 20; i++) {
    pow10_table[i] = pow10_table[i - 1] * 10u;
  }
  int ok = read_file("input.txt", NULL, &buf);
  if (!ok) {
    fprintf(stderr, "read failed\n");
    return 1;
  }
  chomp(buf.p);
  map_clear(&g_init_map);
  parse_initial(&g_init_map, &buf);

  // Part 1
  map_clear(&g_work0);
  map_clear(&g_work1);
  map_copy(&g_init_map, &g_work0);

  cur = &g_work0;
  next = &g_work1;

  for (size_t step_idx = 0u; step_idx < PART1_STEPS; step_idx++) {
    step(cur, next);
    // swap
    {
      struct map *tmp = cur;
      cur = next;
      next = tmp;
    }
  }
  uint64_t part1 = sum_counts(cur);
  
  // Part 2
  map_clear(&g_work0);
  map_clear(&g_work1);
  map_copy(&g_init_map, &g_work0);

  cur  = &g_work0;
  next = &g_work1;

  for (size_t step_idx = 0u; step_idx < PART2_STEPS; step_idx++) {
    step(cur, next);
    struct map *tmp = cur;
    cur  = next;
    next = tmp;
  }

  uint64_t part2 = sum_counts(cur);

  printf("Part 1: %llu\n", (unsigned long long)part1);
  printf("Part 2: %llu\n", (unsigned long long)part2);;
}
