#!/usr/bin/env perl


use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/../lib";

use aoc qw(assert read_grid_nonempty assert_rectangular_grid);

my @DIR_ROW = (-1, 1, 0, 0);
my @DIR_COL = ( 0, 0, -1, 1);

assert(@DIR_ROW == 4 && @DIR_COL == 4,
      "Direction arrays must have length of 4"
);

sub read_input {
  return <DATA> if -t STDIN;
  return <STDIN>;
}

sub main {
  my @input = read_input();
  @input = grep { /\S/ } map { chomp; $_ } @input;

  my @grid = map { [ split // ] } @input;
  assert(@grid > 0, "Input grid must not be empty");
  assert_rectangular_grid(\@grid);

  my ($part1, $part2) = compute_total_price(\@grid);
  print "Part 1: $part1", "\n";
  print "Part 2: $part2", "\n";
}

sub compute_total_price {
  my ($grid_ref) = @_;

  my $height = scalar @{$grid_ref};
  my $width = scalar @{$grid_ref->[0]};

  assert($height > 0, "Height must be > 0");
  assert($width > 0, "Height must be > 0");

  my @visited;
  for my $r (0 .. $height - 1) {
    for my $c (0 .. $width - 1) {
      $visited[$r][$c] = 0;
    }
  }
  my $total_part1 = 0;
  my $total_part2 = 0;
  for my $r (0 .. $height - 1) {
    for my $c (0 .. $width - 1) {
      assert(
        defined $grid_ref->[$r][$c],
        "Grid cell [$r][$c] must be defined"
      );
      if (!$visited[$r][$c]) {
        my ($area, $perimeter, $sides) = floof_fill_region(
          $grid_ref, \@visited, $r, $c, $height, $width
        );
        assert($area        > 0, "Region area must be > 0");
        assert($perimeter   > 0, "Region perimeter must be > 0");
        assert($sides       > 0, "Region sides must be > 0");
        $total_part1 += $area * $perimeter;
        $total_part2 += $area * $sides;
      }
    }
  }
  return ($total_part1, $total_part2);
}

sub floof_fill_region {
  my ($grid_ref, $visited_ref, $start_row, $start_col, $height, $width) = @_;
  assert($start_row >= 0 && $start_row < $height, "start_row out of bounds");
  assert($start_col >= 0 && $start_col < $width, "start_col out of bounds");

  my $target_char = $grid_ref->[$start_row][$start_col];
  assert(defined $target_char, "Target cell must be defined");

  my @queue;
  my $queue_head = 0;
  push @queue, [$start_row, $start_col];
  $visited_ref->[$start_row][$start_col] = 1;

  my $area      = 0;
  my $perimeter = 0;

  my %edges_top;      # row -> cols
  my %edges_bottom;   # row -> cols
  my %edges_left;     # col -> rows
  my %edges_right;    # col -> rows

  my $max_cells = $height * $width;
  assert($max_cells > 0, "max_cells must be > 0");

  while ($queue_head <= $#queue) {
    assert($queue_head >= 0, "queue_head is >= 0");
    assert($queue_head <= $#queue, "queue_head within bounds");

    my ($row, $col) = @{$queue[$queue_head++]};
    assert($row >= 0 && $row < $height, "row out bounds in BFS");
    assert($col >= 0 && $col < $width,  "col out bounds in BFS");

    my $cell_char = $grid_ref->[$row][$col];
    assert(defined $cell_char, "Cell must be defined");
    assert($cell_char eq $target_char, "Cell must match region type");

    $area++;

    for my $dir (0 .. 3) {
      my $nr = $row + $DIR_ROW[$dir];
      my $nc = $col + $DIR_COL[$dir];

      # out of bounds perimeter
      if ($nr < 0 || $nr >= $height || $nc < 0 || $nc >= $width) {
        $perimeter++;
        if    ($dir == 0)  { push @{$edges_top{$row}},    $col; }
        elsif ($dir == 1)  { push @{$edges_bottom{$row}}, $col; }
        elsif ($dir == 2)  { push @{$edges_left{$col}},   $row; }
        else               { push @{$edges_right{$col}},  $row; }
        next;
      }

      my $neighbor_char = $grid_ref->[$nr][$nc];
      assert(defined $neighbor_char, "Neighbor [$nr][$nc] must be defined");

      if ($neighbor_char ne $target_char) {
        $perimeter++;
        if    ($dir == 0)  { push @{$edges_top{$row}},    $col; }
        elsif ($dir == 1)  { push @{$edges_bottom{$row}}, $col; }
        elsif ($dir == 2)  { push @{$edges_left{$col}},   $row; }
        else               { push @{$edges_right{$col}},  $row; }
        next;
      }

      if (!$visited_ref->[$nr][$nc]) {
        assert(@queue < $max_cells, "Queue exceeded max_cells");
        $visited_ref->[$nr][$nc] = 1;
        push @queue, [$nr, $nc];
      }
    }
  }
  my $sides = 0;
  $sides += count_runs_in_edge_map(\%edges_top);
  $sides += count_runs_in_edge_map(\%edges_bottom);
  $sides += count_runs_in_edge_map(\%edges_left);
  $sides += count_runs_in_edge_map(\%edges_right);
  assert($sides > 0, "Region must have at least one side");

  return ($area, $perimeter, $sides);
}

sub count_runs_in_edge_map {
  my ($edge_ref) = @_;
  my $sides = 0;

  for my $key (keys %{$edge_ref}) {
    my @vals = sort { $a <=> $b } @{$edge_ref->{$key}};
    my $prev;
    my $first = 1;
    for my $v (@vals) {
      if ($first || $v != $prev + 1) { $sides++; }
      $prev = $v;
      $first = 0;
    }
  }
  return $sides;
}

main();


__DATA__
RRRRIICCFF
RRRRIICCCF
VVRRRCCFFF
VVRCCCJFFF
VVVVCJJCFE
VVIVCCJJEE
VVIIICJJEE
MIIIIIJJEE
MIIISIJEEE
MMMISSJEEE
