#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdalign.h>
#include <sys/types.h>

#define ARENA_INIT_SIZE 1024

typedef struct {
	char *buf;
	size_t sz;
	size_t offset;
} Arena;

Arena
arena_init(Arena *a)
{
	a->buf = (char *)malloc(ARENA_INIT_SIZE);
	if (!a->buf) { return NULL; }
	a->sz = ARENA_INIT_SIZE;
	a->offset = 0;
	return a;
}

void *
arena_alloc(Arena *a, size_t sz, size_t alignment)
{
	size_t aligned_offset = (a->offset + (alignment - 1)) & ~(alignment - 1);
	if (aligned_offset + sz > a->sz) {
		size_t new_sz = a->sz * 2;
		while (aligned_offset + sz > new_sz) {
			new_sz *= 2;
		}
		char *new_buf = realloc(a->buf, new_sz);
		if (!new_buf) { return NULL; } // allocation failed
		a->buf = new_buf;
		a->sz = new_sz;
	}

	void *ptr = (void *)(a->buf + aligned_offset);
	a->offset = aligned_offset + sz;
	return ptr;
}


void
arena_reset(Arena *a)
{
	a->offset = 0;
}

void
arena_free(Arena *a)
{
	free(a->buf);
	a->buf = NULL;
	a->sz = 0;
	a->offset = 0;
}

ssize_t getline(char **restrict lineptr, size_t *restrict n,
                       FILE *restrict stream);
