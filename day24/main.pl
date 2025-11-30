#!/usr/bin/env perl
use strict;
use warnings;

# Day 24 – Crossed Wires (Parts 1 and 2) in Perl

my %value;          # wire -> 0/1
my @gates;          # [a, op, b, out]
my %uses;           # wire -> [ [other_in, op, out], ... ]

my $reading_values = 1;
while (my $line = <STDIN>) {
    chomp $line;
    if ($line eq '') {
        $reading_values = 0;
        next;
    }

    if ($reading_values) {
        # x00: 1
        if ($line =~ /^(\w+):\s*([01])\s*$/) {
            $value{$1} = 0 + $2;
        }
    } else {
        # a OP b -> out
        if ($line =~ /^(\w+)\s+(AND|OR|XOR)\s+(\w+)\s+->\s+(\w+)\s*$/) {
            my ($a,$op,$b,$out) = ($1,$2,$3,$4);
            push @gates, [$a,$op,$b,$out];
            push @{ $uses{$a} }, [$b,$op,$out];
            push @{ $uses{$b} }, [$a,$op,$out];
        }
    }
}

# Part 1

sub simulate {
    my (%val) = @_; # copy
    my $changed = 1;
    while ($changed) {
        $changed = 0;
        for my $g (@gates) {
            my ($a,$op,$b,$out) = @$g;
            next if exists $val{$out};
            next unless exists $val{$a} && exists $val{$b};
            my ($va,$vb) = ($val{$a}, $val{$b});
            my $r;
            if    ($op eq 'AND') { $r = $va & $vb; }
            elsif ($op eq 'OR')  { $r = $va | $vb; }
            elsif ($op eq 'XOR') { $r = $va ^ $vb; }
            else { next; }
            $val{$out} = $r;
            $changed = 1;
        }
    }
    return %val;
}

my %final = simulate(%value);

# collect z-bits
my @z_wires = grep { /^z\d+$/ } keys %final;
@z_wires = sort {
    (substr($a,1) + 0) <=> (substr($b,1) + 0)
} @z_wires;

my $part1 = 0;
for my $z (@z_wires) {
    my ($idx) = $z =~ /^z(\d+)$/;
    my $bit = $final{$z} // 0;
    $part1 += (1 << $idx) if $bit;
}

print "Part 1: $part1\n";

# Part 2: find swapped outputs (ripple-carry rules)
# Rules adapted from ripple-carry-adder analysis:
#  - https://www.ece.uvic.ca/~fayez/courses/ceng465/lab_465/project1/adders.pdf

# find last z-bit name
my $max_z_idx = -1;
for my $g (@gates) {
    my $out = $g->[3];
    if ($out =~ /^z(\d+)$/) {
        my $i = $1 + 0;
        $max_z_idx = $i if $i > $max_z_idx;
    }
}
my $last_z = sprintf("z%02d", $max_z_idx);

my %faulty;

for my $g (@gates) {
    my ($a,$op,$b,$out) = @$g;

    # rule 1: z outputs must be XOR except last bit
    if ($out =~ /^z\d+$/ && $out ne $last_z && $op ne 'XOR') {
        $faulty{$out} = 1;
        next;
    }

    # rule 2: internal XOR must involve x/y or produce z
    if ($out !~ /^z/ &&
        $a !~ /^[xy]/ && $b !~ /^[xy]/ &&
        $op eq 'XOR') {
        $faulty{$out} = 1;
        next;
    }

    my ($xa) = $a =~ /^x(\d+)$/;
    my ($ya) = $a =~ /^y(\d+)$/;
    my ($xb) = $b =~ /^x(\d+)$/;
    my ($yb) = $b =~ /^y(\d+)$/;

    my $is_xy = 0;
    my $bit_idx = -1;

    # Case 1: a = xN, b = yN
    if (defined $xa && defined $yb && $xa == $yb) {
        $is_xy = 1;
        $bit_idx = $xa;
    }

    # Case 2: a = yN, b = xN
    elsif (defined $ya && defined $xb && $ya == $xb) {
        $is_xy = 1;
        $bit_idx = $ya;
    }

    # rule 3: XOR(xN,yN) for N>0 must feed another XOR gate
    if ($op eq 'XOR' && $is_xy && $bit_idx > 0) {
        my $uses_ref = $uses{$out};
        unless ($uses_ref && @$uses_ref) {
            $faulty{$out} = 1;
            next;
        }
        my $ok = 0;
        for my $u (@$uses_ref) {
            my ($other_in,$uop,$uout) = @$u;
            if ($uop eq 'XOR') { $ok = 1; last; }
        }
        unless ($ok) {
            $faulty{$out} = 1;
            next;
        }
    }

    # rule 4: AND(xN,yN) for N>0 must feed an OR gate
    if ($op eq 'AND' && $is_xy && $bit_idx > 0) {
        my $uses_ref = $uses{$out};
        unless ($uses_ref && @$uses_ref) {
            $faulty{$out} = 1;
            next;
        }
        my $ok = 0;
        for my $u (@$uses_ref) {
            my ($other_in,$uop,$uout) = @$u;
            if ($uop eq 'OR') { $ok = 1; last; }
        }
        unless ($ok) {
            $faulty{$out} = 1;
            next;
        }
    }
}

my @bad = sort keys %faulty;
my $part2 = join(",", @bad);
print "Part 2: $part2\n";
