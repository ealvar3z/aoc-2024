#!/usr/bin/env perl
use strict;
use warnings;

# Usage:
#   perl day20.pl [CHEAT_RANGE [MIN_SAVE]] < input.txt
# Defaults for Part 2: CHEAT_RANGE=20, MIN_SAVE=100
# For Part 1:          CHEAT_RANGE=2,  MIN_SAVE=100

my $CHEAT_RANGE = @ARGV >= 1 ? 0 + $ARGV[0] : 20;
my $MIN_SAVE    = @ARGV >= 2 ? 0 + $ARGV[1] : 100;

my @grid;
while (my $line = <STDIN>) {
    chomp $line;
    next if $line eq '';
    push @grid, [ split //, $line ];
}

my $H = @grid;
my $W = @grid ? @{ $grid[0] } : 0;

die "Empty grid\n" if $H == 0 || $W == 0;

my ($sx, $sy) = (-1, -1);
my ($ex, $ey) = (-1, -1);

for my $y (0 .. $H - 1) {
    for my $x (0 .. $W - 1) {
        if ($grid[$y][$x] eq 'S') {
            ($sx, $sy) = ($x, $y);
        }
        if ($grid[$y][$x] eq 'E') {
            ($ex, $ey) = ($x, $y);
        }
    }
}

die "No S found\n" if $sx < 0;
die "No E found\n" if $ex < 0;

sub bfs_from {
    my ($start_x, $start_y) = @_;
    my @dist;
    for my $y (0 .. $H - 1) {
        $dist[$y] = [ (-1) x $W ];
    }

    my @qx;
    my @qy;
    my ($head, $tail) = (0, 0);

    $dist[$start_y][$start_x] = 0;
    $qx[$tail] = $start_x;
    $qy[$tail] = $start_y;
    $tail++;

    my @dirs = ([1,0], [-1,0], [0,1], [0,-1]);

    while ($head < $tail) {
        my $x = $qx[$head];
        my $y = $qy[$head];
        $head++;
        my $d = $dist[$y][$x];

        for my $dir (@dirs) {
            my ($dx, $dy) = @$dir;
            my $nx = $x + $dx;
            my $ny = $y + $dy;
            next if $nx < 0 || $nx >= $W || $ny < 0 || $ny >= $H;
            my $cell = $grid[$ny][$nx];
            next if $cell eq '#';
            next if $dist[$ny][$nx] != -1;
            $dist[$ny][$nx] = $d + 1;
            $qx[$tail] = $nx;
            $qy[$tail] = $ny;
            $tail++;
        }
    }

    return @dist;
}

my @dist_start = bfs_from($sx, $sy);
my @dist_end   = bfs_from($ex, $ey);

my $baseline = $dist_start[$ey][$ex];
die "End not reachable from start without cheat\n" if $baseline < 0;

my $count_good = 0;

for my $y (0 .. $H - 1) {
    for my $x (0 .. $W - 1) {
        next if $grid[$y][$x] eq '#';
        my $d_start = $dist_start[$y][$x];
        next if $d_start < 0;
        for my $dx (-$CHEAT_RANGE .. $CHEAT_RANGE) {
            my $max_dy = $CHEAT_RANGE - abs($dx);
            for my $dy (-$max_dy .. $max_dy) {
                next if $dx == 0 && $dy == 0;
                my $nx = $x + $dx;
                my $ny = $y + $dy;
                next if $nx < 0 || $nx >= $W || $ny < 0 || $ny >= $H;
                next if $grid[$ny][$nx] eq '#';
                my $d_end = $dist_end[$ny][$nx];
                next if $d_end < 0;
                my $cheat_len = abs($dx) + abs($dy);
                my $new_cost = $d_start + $cheat_len + $d_end;
                my $saved = $baseline - $new_cost;
                if ($saved >= $MIN_SAVE) {
                    $count_good++;
                }
            }
        }
    }
}

print "$count_good\n";
