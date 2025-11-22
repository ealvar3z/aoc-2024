// day08.c - AoC 2024 Day 8: Resonant Collinearity (Parts 1 & 2)
// Compile: cc -std=c23 -O2 day08.c -o day08
// Run:     ./day08 < input.txt

#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>

#define MAX_H  256
#define MAX_W  256
#define MAX_ANTENNAS (MAX_H * MAX_W)

typedef struct {
    int x;      // column index
    int y;      // row index
    char freq;  // antenna character
} Antenna;

int main(void) {
    char line[MAX_W + 4];
    char grid[MAX_H][MAX_W];
    int width  = -1;
    int height = 0;

    // Read the grid from stdin
    while (fgets(line, sizeof line, stdin)) {
        size_t len = strlen(line);

        // Strip trailing newline / carriage return
        while (len > 0 && (line[len - 1] == '\n' || line[len - 1] == '\r')) {
            line[--len] = '\0';
        }

        if (len == 0) {
            // Ignore empty lines
            continue;
        }

        if (width < 0) {
            width = (int)len;
        }

        if (height >= MAX_H) {
            fprintf(stderr, "Grid too tall\n");
            return 1;
        }
        if ((int)len != width) {
            fprintf(stderr, "Non-rectangular grid row length\n");
            return 1;
        }

        for (int x = 0; x < width; x++) {
            grid[height][x] = line[x];
        }
        height++;
    }

    if (width <= 0 || height <= 0) {
        fprintf(stderr, "Empty input\n");
        return 1;
    }

    // Collect antennas
    Antenna ants[MAX_ANTENNAS];
    int ant_count = 0;

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            char c = grid[y][x];
            if (c != '.') {
                if (ant_count >= MAX_ANTENNAS) {
                    fprintf(stderr, "Too many antennas\n");
                    return 1;
                }
                ants[ant_count].x    = x;
                ants[ant_count].y    = y;
                ants[ant_count].freq = c;
                ant_count++;
            }
        }
    }

    // Part 1: antinodes with 2x distance rule
    bool antinode1[MAX_H][MAX_W] = { false };

    for (int i = 0; i < ant_count; i++) {
        for (int j = i + 1; j < ant_count; j++) {
            if (ants[i].freq != ants[j].freq) {
                continue;
            }

            int x1 = ants[i].x;
            int y1 = ants[i].y;
            int x2 = ants[j].x;
            int y2 = ants[j].y;

            int dx = x2 - x1;
            int dy = y2 - y1;

            // First antinode: A - (B - A) = 2A - B
            int ax = x1 - dx;
            int ay = y1 - dy;

            if (ax >= 0 && ax < width && ay >= 0 && ay < height) {
                antinode1[ay][ax] = true;
            }

            // Second antinode: B + (B - A) = 2B - A
            int bx = x2 + dx;
            int by = y2 + dy;

            if (bx >= 0 && bx < width && by >= 0 && by < height) {
                antinode1[by][bx] = true;
            }
        }
    }

    int count1 = 0;
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            if (antinode1[y][x]) {
                count1++;
            }
        }
    }

    // Part 2: antinodes at all collinear positions (resonant harmonics)
    bool antinode2[MAX_H][MAX_W] = { false };

    for (int i = 0; i < ant_count; i++) {
        for (int j = i + 1; j < ant_count; j++) {
            if (ants[i].freq != ants[j].freq) {
                continue;
            }

            int x1 = ants[i].x;
            int y1 = ants[i].y;
            int x2 = ants[j].x;
            int y2 = ants[j].y;

            int dx = x2 - x1;
            int dy = y2 - y1;

            // Walk backwards from antenna i along the line: ... A-2d, A-d, A, ...
            int x = x1;
            int y = y1;
            while (x >= 0 && x < width && y >= 0 && y < height) {
                antinode2[y][x] = true;
                x -= dx;
                y -= dy;
            }

            // Walk forwards from antenna j along the line: ... B, B+d, B+2d, ...
            x = x2;
            y = y2;
            while (x >= 0 && x < width && y >= 0 && y < height) {
                antinode2[y][x] = true;
                x += dx;
                y += dy;
            }
        }
    }

    int count2 = 0;
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            if (antinode2[y][x]) {
                count2++;
            }
        }
    }

    // Print results:
    // First line: Part 1
    // Second line: Part 2
    printf("%d\n", count1);
    printf("%d\n", count2);

    return 0;
}

