#!/usr/bin/env perl
use strict;
use warnings;

use constant MOD   => 16777216;  # 2^24
use constant STEPS => 2000;      # number of new secrets

sub next_secret {
    my ($s) = @_;

    my $v = $s * 64;
    $s ^= $v;
    $s %= MOD;

    $v = int($s / 32);
    $s ^= $v;
    $s %= MOD;

    $v = $s * 2048;
    $s ^= $v;
    $s %= MOD;

    return $s;
}

my @seeds;
while (my $line = <STDIN>) {
    chomp $line;
    next if $line =~ /^\s*$/;
    push @seeds, 0 + $line;
}

my $total_last = 0;
my %pattern_sum;

for my $seed (@seeds) {
    my $secret = $seed;
    my $price_prev = $secret % 10;
    my @window;
    my %seen_pattern;

    for (1 .. STEPS) {
        $secret = next_secret($secret);
        my $price = $secret % 10;

        my $delta = $price - $price_prev;
        $price_prev = $price;

        push @window, $delta;
        shift @window if @window > 4;

        if (@window == 4) {
            my $pat = join ',', @window;
            next if $seen_pattern{$pat};
            $seen_pattern{$pat} = 1;
            $pattern_sum{$pat} += $price;
        }
    }

    $total_last += $secret;
}

my $best = 0;
for my $pat (keys %pattern_sum) {
    my $v = $pattern_sum{$pat};
    $best = $v if $v > $best;
}

print "$total_last\n";
print "$best\n";
