#include "arena.c"

typedef enum {
	UP = 0,
	RIGHT,
	DOWN,
	LEFT,
} FacingDir;

typedef struct {
	int x;
	int y;
	FacingDir dir;
} Guard;

typedef struct {
	char **grid;
	int rows;
	int cols;
} Map;

Map
parse_map(const char *fn, Guard *g, Arena *a)
{
	FILE *f = fopen(fn, "r");
	if (!f) {
		perror("error opening file");
		exit(EXIT_FAILURE);
	}

	char **lines = NULL;
	size_t cap = 0;
	ssize_t len;
	size_t rows = 0;
	size_t cols = 0;

	lines = arena_alloc(a, sizeof(char*) * 1, alignof(char*));
	if (!lines) {
		fprintf(stderr, "failed to alloc memory for lines.\n");
		fclose(f);
		exit(EXIT_FAILURE);
	}
	lines[0] = NULL;
	
	while ((len = getline(&lines[rows], &cap, f)) != -1) {
		if (lines[rows][len-1] == '\n') {
			lines[rows][len-1] = '\0';
			len--;
		}

		if (rows == 0) {
			cols = len;
		} else if ((size_t)len != cols) {
			fprintf(stderr, "Error: inconsistent row len in the map.\n");
			fclose(f);
			exit(EXIT_FAILURE);
		}

		rows++;
		char **temp = arena_alloc(a, sizeof(char*) * (rows+1), alignof(char*));
		if (!temp) {
			fprintf(stderr, "failed to alloc memory for lines.\n");
			fclose(f);
			exit(EXIT_FAILURE);
		}
		memcpy(temp, lines, sizeof(char*) * rows);
		temp[rows] = NULL;
		lines = temp;
	}
	fclose(f);

	char **grid = arena_alloc(a, sizeof(char*) * rows, alignof(char*));
	if (!grid) {
		fprintf(stderr, "failed to alloc mem for map grid.\n");
		exit(EXIT_FAILURE);
	}

	for (size_t i = 0; i < rows; i++) {
		grid[i] = arena_alloc(a, sizeof(char) * (cols+1), alignof(char));
		if (!grid[i]) {
			fprintf(stderr, "failes to alloc mem for map grid row %zu.\n", i);
			exit(EXIT_FAILURE);
		}
		strcpy(grid[i], lines[i]);
	}
	Map m;
	m.grid = grid;
	m.rows = rows;
	m.cols = cols;

	bool found = false;
	for (int y = 0; y < m.rows && !found; y++) {
		for (int x = 0; x < m.cols && !found; x++) {
			char cell = m.grid[y][x];
			if (cell == '^' ||
			    cell == '>' ||
			    cell == 'v' ||
			    cell == '<') {
				g->x = x;
				g->y = y;
				switch (cell) {
					case '^':
						g->dir = UP;
						break;
					case '>':
						g->dir = RIGHT;
						break;
					case 'v':
						g->dir = DOWN;
						break;
					case '<':
						g->dir = LEFT;
						break;
				}
				found = true;
				m.grid[y][x] = '.';
			}
		}
	}
	if (!found) {
		fprintf(stderr, "Error: no guard found in the map.\n");
		exit(EXIT_FAILURE);
	}
	return m;
}

void
turn_90(Guard *g)
{
	g->dir = (g->dir+1)%4;
}

bool
within_map(Map m, int x, int y)
{
	return (x >= 0 && x < m.cols && y >= 0 && y < m.rows);
}

int
part_1(Map m, Guard *g, bool **visited_set, Arena *a)
{
	int visits = 0;
	visited_set[g->y][g->x] = true;
	visits++;

	while (true) {
		int dx, dy;
		switch (g->dir) {
			case UP:
				dx = 0;
				dy = -1;
				break;
			case RIGHT:
				dx = 1;
				dy = 0;
				break;
			case DOWN:
				dx = 0;
				dy = 1;
				break;
			case LEFT:
				dx = -1;
				dy = 0;
				break;
			default:
				fprintf(stderr, "Error: wrong direction.\n");
				goto cleanup;
		}
		int next_x = g->x + dx;
		int next_y = g->y + dy;
	
		if (!within_map(m, next_x, next_y)) { break; }
		if (m.grid[next_y][next_x] == '#') {
			turn_90(g);
		} else {
			g->x = next_x;
			g->y = next_y;
			if (!visited_set[g->y][g->x]) {
				visited_set[g->y][g->x] = true;
				visits++;
			}
		}
	}
	return visits;

cleanup:
	return visits;
}

int
main(int argc, char *argv[])
{
	if (argc != 2) {
		fprintf(stderr, "Usage: %s <file>\n", argv[0]);
		return EXIT_FAILURE;
	}
	const char *fn = argv[1];
	Arena a;
	Guard g;
	Map map;
	bool **visited_set = NULL;
	int distinct_visits = 0;
	
	a = arena_init(&a);	
	if (!a) {
		perror("arena init failed");
		return EXIT_FAILURE;
	}

	map = parse_map(fn, &g, &a);
	if (!map.grid) {
		perror("parsing map failed");
		goto cleanup;
	}

	for (int i = 0; i < map.rows; i++) {
		visited_set[i] = arena_alloc(&a, sizeof(bool*) * map.rows, alignof(bool*));
		turn_90(&g);
		if (!visited_set[i]) {
			perror("failed to alloc mem for visited_set");
			goto cleanup;
		}
		memset(visited_set[i], 0, sizeof(bool) * map.cols);
	}
	distinct_visits = part_1(map, &g, visited_set, &a);
	printf("Distinct positions visited: %d\n", distinct_visits);

cleanup:
	arena_free(&a);
	return EXIT_SUCCESS;
}
