package aoc;

use strict;
use warnings;
use Carp qw(croak);
use Exporter qw(import);

our @EXPORT_OK = qw(
  assert
  read_lines
  read_blocks
  read_grid_nonempty
  assert_rectangular_grid
  parse_ints
);

sub assert {
  my ($cond, $msg) = @_;
  croak "ASSERTION FAILURE: $msg" if !$cond;
}

sub read_lines {
  my @input = @_;
  @input = <STDIN> if !@input;
  chomp @input;
  return @input;
}

sub read_blocks {
  my ($lines_ref) = @_;
  assert(defined $lines_ref && ref($lines_ref) eq 'ARRAY', "read_blocks expects array_ref");
  my @blocks;
  my @current;
  for my $line (@{$lines_ref}) {
    if ($line =~ /^\s*$/) {
      if (@current) {
        push @blocks, [ @current ];
        @current = ();
      }
      next;
    }
    push @current, $line;
  }
  if (@current) {
    push @blocks, [ @current ];
  }
  return @blocks;
}

sub read_grid_nonempty { 
  my @input = @_;
  @input = <STDIN> if !@input;
  my @grid;
  for my $line (@input) {
    chomp $line;
    next if $line eq '';
    my @chars = split //, $line;
    push @grid, \@chars;
  }
  return @grid;
}

sub assert_rectangular_grid {
  my ($grid_ref) = @_;
  assert(defined $grid_ref && ref($grid_ref) eq 'ARRAY', "grid ref must be arrayref");
  my $h = scalar @{$grid_ref};
  assert($h > 0, "grid height must be > 0");
  my $w = scalar @{$grid_ref->[0]};
  assert($w > 0, "grid width must be > 0");
  for my $r (0 .. $h - 1) {
    my $row = $grid_ref->[$r];
    assert(defined $row && ref($row) eq 'ARRAY', "row must be arrayref");
    my $rw = scalar @{$row};
    assert($rw == $w, "row width mismatch");
  }
}

sub parse_ints {
  my ($line) = @_;
  return ($line =~ /(-?\d_)/g);
}

1; # end of aoc.pm
