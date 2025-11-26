package aoc;

use strict;
use warnings;
use Carp qw(croak);
use Exporter qw(import);

our @EXPORT_OK = qw(
  assert
  read_grid_nonempty
  assert_rectangular_grid
);

sub assert {
  my ($cond, $msg) = @_;
  croak "ASSERTION FAILURE: $msg" if !$cond;
}

sub read_grid_nonempty {
  my @grid;
  while ( my $l = <STDIN> ) {
    chomp $l;
    next if $l eq '';

    my @chars = split //, $l;
    push @grid, \@chars;
  }
  return @grid;
}

sub assert_rectangular_grid {
  my ($grid_ref) = @_;

  assert(defined $grid_ref, "Grid reference must exist");

  my $height = scalar @{$grid_ref};
  assert($height > 0, "Grid must have a positive height");

  my $expected_width = scalar @{$grid_ref->[0]};
  assert($expected_width > 0, "Grid must have a positive width");

  for (my $r = 0; $r < $height; $r++) {
    my $row_ref = $grid_ref->[$r];
    assert(defined $row_ref, "Row $r must be defined");

    my $width = scalar @{$row_ref};
    assert(
      $width == $expected_width,
      "Have (row: $r, width: $width), Expect: $expected_width"
    );
  }
}

1; # end of aoc.pm
