#include <iostream>
#include <vector>
#include <string>
#include <queue>
#include <array>
#include <limits>

using namespace std;

/*
 * Advent of Code 2024 - Day 16: Reindeer Maze (Parts 1 & 2)
 *
 * State: (row, col, dir)
 *   dir: 0 = North, 1 = East, 2 = South, 3 = West
 *
 * Start: 'S' facing East (dir = 1)
 * Goal:  reach 'E' with minimal score, any final direction.
 *
 * Costs:
 *   - Move forward 1 cell (if not '#') : +1
 *   - Rotate left or right 90 degrees  : +1000
 *
 * Part 1:
 *   Minimal score from (S, East) to any orientation at E.
 *
 * Part 2:
 *   Count tiles that lie on at least one optimal path.
 *   A tile (r,c) is on some optimal path if there exists a direction d
 *   such that:
 *       dist_start[r][c][d] + dist_end[r][c][d] == best_cost
 *   where dist_end is computed via a Dijkstra on the reversed graph
 *   (from all (E, d) with distance 0).
 */

struct Node {
    long long dist;
    int r;
    int c;
    int d;
};

struct NodeCmp {
    bool operator()(const Node &a, const Node &b) const {
        return a.dist > b.dist;
    }
};

const int DR[4] = {-1, 0, 1, 0};
const int DC[4] = {0, 1, 0, -1};

static const long long INF = numeric_limits<long long>::max();

using DistArray = vector<vector<array<long long, 4>>>;

// Dijkstra from start (S, East) over the forward graph.
DistArray dijkstra_from_start(const vector<string> &grid, int sr, int sc) {
    int R = (int)grid.size();
    int C = (int)grid[0].size();

    DistArray dist(
        R,
        vector<array<long long, 4>>(C, {INF, INF, INF, INF})
    );

    priority_queue<Node, vector<Node>, NodeCmp> pq;

    int start_dir = 1; // East
    dist[sr][sc][start_dir] = 0;
    pq.push(Node{0LL, sr, sc, start_dir});

    while (!pq.empty()) {
        Node cur = pq.top();
        pq.pop();

        long long cost = cur.dist;
        int r = cur.r;
        int c = cur.c;
        int d = cur.d;

        if (cost != dist[r][c][d]) {
            continue; // stale
        }

        // 1) Move forward
        int nr = r + DR[d];
        int nc = c + DC[d];
        if (nr >= 0 && nr < R && nc >= 0 && nc < C) {
            if (grid[nr][nc] != '#') {
                long long ncost = cost + 1;
                if (ncost < dist[nr][nc][d]) {
                    dist[nr][nc][d] = ncost;
                    pq.push(Node{ncost, nr, nc, d});
                }
            }
        }

        // 2) Rotate left
        {
            int nd = (d + 3) % 4;
            long long ncost = cost + 1000;
            if (ncost < dist[r][c][nd]) {
                dist[r][c][nd] = ncost;
                pq.push(Node{ncost, r, c, nd});
            }
        }

        // 3) Rotate right
        {
            int nd = (d + 1) % 4;
            long long ncost = cost + 1000;
            if (ncost < dist[r][c][nd]) {
                dist[r][c][nd] = ncost;
                pq.push(Node{ncost, r, c, nd});
            }
        }
    }

    return dist;
}

// Dijkstra "backwards" from all orientations at E over the reversed graph.
DistArray dijkstra_reverse_to_end(const vector<string> &grid, int er, int ec) {
    int R = (int)grid.size();
    int C = (int)grid[0].size();

    DistArray dist(
        R,
        vector<array<long long, 4>>(C, {INF, INF, INF, INF})
    );

    priority_queue<Node, vector<Node>, NodeCmp> pq;

    for (int d = 0; d < 4; ++d) {
        dist[er][ec][d] = 0;
        pq.push(Node{0LL, er, ec, d});
    }

    while (!pq.empty()) {
        Node cur = pq.top();
        pq.pop();

        long long cost = cur.dist;
        int r = cur.r;
        int c = cur.c;
        int d = cur.d;

        if (cost != dist[r][c][d]) {
            continue; // stale
        }

        // Reversed edges:

        // 1) Reverse of moving forward:
        //    If in the forward graph, (pr,pc,d) -> (r,c,d) with cost 1,
        //    then in reverse we have (r,c,d) -> (pr,pc,d) with cost 1.
        int pr = r - DR[d];
        int pc = c - DC[d];
        if (pr >= 0 && pr < R && pc >= 0 && pc < C) {
            if (grid[pr][pc] != '#') {
                long long ncost = cost + 1;
                if (ncost < dist[pr][pc][d]) {
                    dist[pr][pc][d] = ncost;
                    pq.push(Node{ncost, pr, pc, d});
                }
            }
        }

        // 2) Reverse of rotations:
        //    Rotations are symmetric, so from (r,c,d) we can still go to
        //    (r,c,(d+1)%4) and (r,c,(d+3)%4) with cost 1000.
        {
            int nd = (d + 3) % 4;
            long long ncost = cost + 1000;
            if (ncost < dist[r][c][nd]) {
                dist[r][c][nd] = ncost;
                pq.push(Node{ncost, r, c, nd});
            }
        }
        {
            int nd = (d + 1) % 4;
            long long ncost = cost + 1000;
            if (ncost < dist[r][c][nd]) {
                dist[r][c][nd] = ncost;
                pq.push(Node{ncost, r, c, nd});
            }
        }
    }

    return dist;
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    vector<string> grid;
    {
        string line;
        while (getline(cin, line)) {
            if (!line.empty() && line.back() == '\r') {
                line.pop_back(); // handle CRLF
            }
            if (!line.empty()) {
                grid.push_back(line);
            }
        }
    }

    if (grid.empty()) {
        return 0;
    }

    int R = (int)grid.size();
    int C = (int)grid[0].size();

    int sr = -1, sc = -1;
    int er = -1, ec = -1;

    // Find S and E
    for (int r = 0; r < R; ++r) {
        for (int c = 0; c < C; ++c) {
            if (grid[r][c] == 'S') {
                sr = r;
                sc = c;
            } else if (grid[r][c] == 'E') {
                er = r;
                ec = c;
            }
        }
    }

    if (sr < 0 || sc < 0 || er < 0 || ec < 0) {
        return 0; // invalid input
    }

    // Part 1: forward Dijkstra
    DistArray dist_start = dijkstra_from_start(grid, sr, sc);

    long long best_cost = INF;
    for (int d = 0; d < 4; ++d) {
        if (dist_start[er][ec][d] < best_cost) {
            best_cost = dist_start[er][ec][d];
        }
    }

    if (best_cost == INF) {
        return 0; // No path, shouldn't be reached
    }

    // Part 2: backward Dijkstra from E
    DistArray dist_end = dijkstra_reverse_to_end(grid, er, ec);

    // Mark tiles that are on some optimal path
    vector<vector<bool>> on_best_path(R, vector<bool>(C, false));

    for (int r = 0; r < R; ++r) {
        for (int c = 0; c < C; ++c) {
            if (grid[r][c] == '#') {
                continue;
            }
            bool ok = false;
            for (int d = 0; d < 4; ++d) {
                long long ds = dist_start[r][c][d];
                long long de = dist_end[r][c][d];
                if (ds == INF || de == INF) {
                    continue;
                }
                if (ds + de == best_cost) {
                    ok = true;
                    break;
                }
            }
            if (ok) {
                on_best_path[r][c] = true;
            }
        }
    }

    long long count_tiles = 0;
    for (int r = 0; r < R; ++r) {
        for (int c = 0; c < C; ++c) {
            if (on_best_path[r][c]) {
                ++count_tiles;
            }
        }
    }

    cout << "Part 1: " << best_cost << "\n";
    cout << "Part 2: " << count_tiles << "\n";

    return 0;
}

