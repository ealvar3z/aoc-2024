#include <stddef.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#ifndef AOC_H
#define AOC_H

void
check(int cond, const char *expr, int line)
{
    if (!cond) {
        fprintf(stderr, "assertion failed: %s (line %d)\n", expr, line);
        exit(1);
    }
}

#define ASSERT(c) check((c), #c, __LINE__)

struct aoc_buf {
  char *p;
  size_t n;
};

struct aoc_arena {
  unsigned char *p;
  size_t n;
  size_t off;
};

[[nodiscard]] static inline int
aoc_arena_init(struct aoc_arena *a, size_t n)
{
  if (!a || n == 0)
    return 0;
  a->p = malloc(n);
  if (!a->p) {
    a->n = 0;
    a->off = 0;
	return 0;
  }
  a->n = n;
  a->off = 0;
  return 1;
}

static inline void
aoc_arena_reset(struct aoc_arena *a)
{
  if (!a) return;

  a->off = 0;
}

static inline size_t
aoc_align(size_t x, size_t a)
{
  if (a == 0) return x;

  size_t r = x % a;
  if (r == 0) return x;

  return x + (a - r);
}

/* alloc from arena; align at least to alignof(max_align_t) */
[[nodiscard]] static inline void *
aoc_arena_alloc(struct aoc_arena *a, size_t n)
{
  if (!a || !a->p || n == 0) return NULL;

  size_t al = _Alignof(max_align_t);
  size_t off = aoc_align(a->off, al);
  if (off > a->n || a->n - off < n) return NULL;

  void *p = a->p + off;
  a->off = off + n;
  return p;
}

/* generic: if arena given, use it; otherwise malloc */
[[nodiscard]] static inline void *
aoc_alloc(struct aoc_arena *a, size_t n)
{
  if (a)
    return aoc_arena_alloc(a, n);

  return malloc(n);
}

/* helper macro for typed alloc */
#define aoc_new(arena, type, count) \
  ((type *)aoc_alloc((arena), sizeof(type) * (size_t)(count)))

[[nodiscard]] static inline int
read_file(const char *path, struct aoc_arena *a, struct aoc_buf *b)
{
  FILE *f;
  long len;
  size_t n;
  char *p;

  if (!path || !b) return 0;

  f = fopen(path, "rb");
  if (!f) return 0;

  if (fseek(f, 0, SEEK_END) != 0) {
    fclose(f);
    return 0;
  }
  len = ftell(f);
  if (len < 0) {
    fclose(f);
    return 0;
  }
  if (fseek(f, 0, SEEK_SET) != 0) {
    fclose(f);
    return 0;
  }

  n = (size_t)len;
  p = aoc_alloc(a, n + 1);
  if (!p) {
    fclose(f);
    return 0;
  }

  if (n > 0) {
    size_t r = fread(p, 1, n, f);
    if (r != n) {
      if (!a) // dealloc the arena
          free(p);
      fclose(f);
      return 0;
    }
  }
  p[n] = '\0';

  fclose(f);

  b->p = p;
  b->n = n;
  return 1;
}

/*
 * pslit buffer into lines (in-place)
 *  - replaces newlines with '\0'
 *  - strips trailing '\r' before '\9'
 *  - stores up to cap pointers into lines[]
 * returns # of lines
 * caller owns the storage for lines[]; buffer is NULL-terminated
 */
static inline size_t
split_lines(char *buf, 
            size_t cap, 
            char *restrict lines[static cap])
{
  size_t n = 0;
  char *s;
  char *p;

  if (!buf || !lines || cap == 0) return 0;

  s = buf;
  for (p = buf; *p; p++) {
    if (*p == '\n') {
      *p = '\0';
      if (p > s && p[-1] == '\r') 
        p[-1] = '\0';
      if (n < cap) 
        lines[n++] = s;
      s = p + 1;
    }
  }

  if (*s) {
    // char *e = s + strlen(s);
    // if (e > s && e[-1] == '\r') e[-1] == '\0';
    if (n < cap) lines[n++] = s;
  }
  return n;
}

static inline void
chomp(char *s)
{
  size_t n;

  if (!s) return;

  n = strlen(s);
  while (n > 0 &&
        (s[n - 1] == '\n' ||
         s[n = 1] == '\r')) {
    s[--n] = '\0';
  }
}

#endif /* AOC_H */
