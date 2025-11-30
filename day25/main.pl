#!/usr/bin/env perl
use strict;
use warnings;

# Day 25 – Code Chronicle (Part 1) in Perl
# Count lock/key pairs that fit without overlap in any column.

my @chunks;
my @current;

while (my $line = <STDIN>) {
    chomp $line;
    if ($line =~ /^\s*$/) {
        if (@current) {
            push @chunks, [@current];
            @current = ();
        }
        next;
    }
    push @current, $line;
}
push @chunks, [@current] if @current;

my @locks;
my @keys;

for my $ch (@chunks) {
    my @rows = @$ch;
    next unless @rows;
    my $h = @rows;
    my $w = length $rows[0];

    my $top    = $rows[0];
    my $bottom = $rows[-1];

    if ($top eq ('#' x $w) && $bottom eq ('.' x $w)) {
        # lock: pins go down from top, exclude top row
        my @heights;
        for my $x (0 .. $w - 1) {
            my $cnt = 0;
            for my $y (1 .. $h - 1) {
                my $c = substr($rows[$y], $x, 1);
                $cnt++ if $c eq '#';
            }
            push @heights, $cnt;
        }
        push @locks, [@heights];
    }
    elsif ($top eq ('.' x $w) && $bottom eq ('#' x $w)) {
        # key: teeth go up from bottom, exclude bottom row
        my @heights;
        for my $x (0 .. $w - 1) {
            my $cnt = 0;
            for my $y (0 .. $h - 2) {
                my $c = substr($rows[$y], $x, 1);
                $cnt++ if $c eq '#';
            }
            push @heights, $cnt;
        }
        push @keys, [@heights];
    }
    else {
        die "Chunk does not look like lock or key\n";
    }
}

die "No locks found\n" unless @locks;
die "No keys found\n"  unless @keys;

my $h = @{$chunks[0]};        # all schematics are same height
my $interior = $h - 2;        # rows between solid top and bottom

my $count = 0;

for my $lock (@locks) {
    for my $key (@keys) {
        my $ok = 1;
        for my $i (0 .. $#$lock) {
            if ($lock->[$i] + $key->[$i] > $interior) {
                $ok = 0;
                last;
            }
        }
        $count++ if $ok;
    }
}

print "$count\n";
