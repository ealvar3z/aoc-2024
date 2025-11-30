#!/usr/bin/env perl

use strict;
use warnings;
use List::Util qw(sum0);

my @lines = <STDIN>;
chomp @lines;

@lines = grep { $_ ne '' } @lines;

die "need at least 2 lines\n" if @lines < 2;

my $pat_line = shift @lines;
my @patterns = split /\s*,\s*/, $pat_line;

my %bylen;
my $maxlen = 0;
for my $p (@patterns) {
  my $l = length $p;
  push @{ $bylen{$l} }, $p;
  $maxlen = $l if $l > $maxlen;
}

sub designs {
  my ($s, $bylen, $maxlen) = @_;
  my $n = length $s;
  my @dp = (0) x ($n + 1);
  $dp[0] = 1;
  for my $i (0 .. $n - 1) {
    my $ways = $dp[$i];
    next unless $ways;
    my $remain = $n - $i;
    my $lim = $remain < $maxlen ? $remain : $maxlen;
    for my $len (1 .. $lim) {
      next unless exists $bylen->{$len};
      my $seg = substr($s, $i, $len);
      for my $p (@{ $bylen->{$len} }) {
        if ($seg eq $p) {
          $dp[$i + $len] += $ways;
          last;
        }
      }
    }
  }
  return $dp[$n];
}

my @ways = map { designs($_, \%bylen, $maxlen) } @lines;
my $part1 = scalar grep { $_ > 0 } @ways;
my $part2 = sum0 @ways;
print "$part1\n";
print "$part2\n";
