#!/usr/bin/env perl
use strict;
use warnings;

# Usage:
#   perl day18.pl [GRID_MAX [BYTES_PART1]] < input.txt
# Example sample: perl day18.pl 6 12 < sample.txt
# Example real:   perl day18.pl 70 1024 < input.txt

my $GRID_MAX    = @ARGV >= 1 ? 0 + $ARGV[0] : 70;
my $BYTES_PART1 = @ARGV >= 2 ? 0 + $ARGV[1] : 1024;

sub read_bytes {
    my @coords;
    while (my $line = <STDIN>) {
        chomp $line;
        next if $line =~ /^\s*$/;
        my ($x, $y) = split /,/, $line;
        push @coords, [ int($x), int($y) ];
    }
    return @coords;
}

sub build_grid {
    my (@blocks) = @_;
    my $size = $GRID_MAX + 1;
    my @grid;
    for my $y (0 .. $size - 1) {
        $grid[$y] = [(0) x $size];
    }
    for my $p (@blocks) {
        my ($x, $y) = @$p;
        next if $x < 0 || $x > $GRID_MAX || $y < 0 || $y > $GRID_MAX;
        $grid[$y][$x] = 1;
    }
    return @grid;
}

sub bfs_dist {
    my (@grid) = @_;
    my $size = $GRID_MAX + 1;

    my ($sx, $sy) = (0, 0);
    my ($tx, $ty) = ($GRID_MAX, $GRID_MAX);

    return undef if $grid[$sy][$sx];
    return undef if $grid[$ty][$tx];

    my @dist;
    for my $y (0 .. $size - 1) {
        $dist[$y] = [(-1) x $size];
    }

    my (@qx, @qy);
    my ($head, $tail) = (0, 0);

    $dist[$sy][$sx] = 0;
    $qx[$tail] = $sx;
    $qy[$tail] = $sy;
    $tail++;

    my @dirs = ([1,0], [-1,0], [0,1], [0,-1]);

    while ($head < $tail) {
        my $x = $qx[$head];
        my $y = $qy[$head];
        $head++;

        if ($x == $tx && $y == $ty) {
            return $dist[$y][$x];
        }

        for my $d (@dirs) {
            my ($dx, $dy) = @$d;
            my $nx = $x + $dx;
            my $ny = $y + $dy;

            next if $nx < 0 || $nx > $GRID_MAX || $ny < 0 || $ny > $GRID_MAX;
            next if $grid[$ny][$nx];
            next if $dist[$ny][$nx] != -1;

            $dist[$ny][$nx] = $dist[$y][$x] + 1;
            $qx[$tail] = $nx;
            $qy[$tail] = $ny;
            $tail++;
        }
    }

    return undef;
}

sub main {
    my @coords = read_bytes();
    my $ncoords = @coords;

    my $limit1 = $BYTES_PART1;
    $limit1 = $ncoords if $limit1 > $ncoords;
    my @blocks1 = @coords[0 .. $limit1 - 1];
    my @grid1   = build_grid(@blocks1);
    my $steps1  = bfs_dist(@grid1);
    if (defined $steps1) {
        print "$steps1\n";
    } else {
        print "NO PATH\n";
    }

    my $lo = 0;
    my $hi = $ncoords;
    while ($lo + 1 < $hi) {
        my $mid = int(($lo + $hi) / 2);
        my @b = @coords[0 .. $mid - 1];
        my @g = build_grid(@b);
        my $d = bfs_dist(@g);
        if (defined $d) {
            $lo = $mid;
        } else {
            $hi = $mid;
        }
    }

    if ($hi >= 1 && $hi <= $ncoords) {
        my ($x, $y) = @{ $coords[$hi - 1] };
        print "$x,$y\n";
    } else {
        print "NO BLOCK\n";
    }
}

main();
