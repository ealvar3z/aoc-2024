#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/../lib";

use aoc qw(assert read_lines read_blocks);

sub main {
  my @lines  = read_lines();
  my @blocks = read_blocks(\@lines);

  my @machines;
  for my $b (@blocks) {
    push @machines, parse_machine_block($b);
  }

  my $part1  = 0;
  my $part2  = 0;
  my $offset = 10000000000000;

  for my $m (@machines) {
    my ($ax, $ay, $bx, $by, $px, $py) =
      @{$m}{qw(ax ay bx by px py)};

    my $cost1 = solve_for_prize($ax, $ay, $bx, $by, $px, $py, 100, 100);
    $part1 += $cost1 if defined $cost1;

    my $cost2 = solve_for_prize(
      $ax, $ay, $bx, $by,
      $px + $offset, $py + $offset,
      undef, undef
    );
    $part2 += $cost2 if defined $cost2;
  }

  print "$part1\n";
  print "$part2\n";
}

sub parse_machine_block {
  my ($block_ref) = @_;

  my @lines = @{$block_ref};
  assert(@lines == 3, "Each machine block must have 3 lines");

  my ($line_a, $line_b, $line_p) = @lines;

  my ($ax, $ay) = $line_a =~ /Button\s+A:\s*X\+(-?\d+),\s*Y\+(-?\d+)/;
  my ($bx, $by) = $line_b =~ /Button\s+B:\s*X\+(-?\d+),\s*Y\+(-?\d+)/;
  my ($px, $py) = $line_p =~ /Prize:\s*X=(-?\d+),\s*Y=(-?\d+)/;

  assert(defined $ax && defined $ay, "Failed to parse A line: '$line_a'");
  assert(defined $bx && defined $by, "Failed to parse B line: '$line_b'");
  assert(defined $px && defined $py, "Failed to parse Prize line: '$line_p'");

  return {
    ax => $ax,
    ay => $ay,
    bx => $bx,
    by => $by,
    px => $px,
    py => $py,
  };
}

sub solve_for_prize {
  my ($ax, $ay, $bx, $by, $px, $py, $max_a, $max_b) = @_;

  my $d = $ax * $by - $ay * $bx;
  return undef if $d == 0;

  my $a_num = $px * $by - $py * $bx;
  my $b_num = $ax * $py - $ay * $px;

  return undef if $a_num % $d != 0;
  return undef if $b_num % $d != 0;

  my $a = $a_num / $d;
  my $b = $b_num / $d;

  return undef if $a < 0 || $b < 0;

  if (defined $max_a) {
    return undef if $a > $max_a;
    return undef if $b > $max_b;
  }

  my $tokens = 3 * $a + $b;
  return $tokens;
}

main();

