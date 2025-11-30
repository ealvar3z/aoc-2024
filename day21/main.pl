#!/usr/bin/env perl
use strict;
use warnings;
use List::Util qw(sum0);

# Day 21 – Part 2: set DEPTH = 25 (25 robot directional keypads)
my $DEPTH = 25;

my @codes;
while (my $line = <STDIN>) {
    chomp $line;
    next if $line =~ /^\s*$/;
    push @codes, $line;
}
die "Need codes\n" unless @codes;

sub build_paths {
    my ($rows_ref) = @_;
    my $h = @$rows_ref;
    my $w = length($rows_ref->[0]);
    my %pos;
    for my $y (0 .. $h - 1) {
        my $row = $rows_ref->[$y];
        for my $x (0 .. $w - 1) {
            my $ch = substr($row, $x, 1);
            next if $ch eq ' ';
            $pos{$ch} = [$x, $y];
        }
    }
    my %paths;
    my @dirs = ([1,0,'>'], [-1,0,'<'], [0,1,'v'], [0,-1,'^']);
    for my $start (keys %pos) {
        my ($sx, $sy) = @{$pos{$start}};
        my %minlen;
        my %store;
        my @queue;
        $minlen{"$sx,$sy"} = 0;
        $store{"$sx,$sy"} = [''];
        push @queue, [$sx, $sy, ''];
        my $qi = 0;
        while ($qi < @queue) {
            my ($x, $y, $seq) = @{$queue[$qi++]};
            my $cur_len = length $seq;
            for my $d (@dirs) {
                my ($dx, $dy, $ch) = @$d;
                my $nx = $x + $dx;
                my $ny = $y + $dy;
                next if $nx < 0 || $nx >= $w || $ny < 0 || $ny >= $h;
                my $cell = substr($rows_ref->[$ny], $nx, 1);
                next if $cell eq ' ';
                my $newseq = $seq . $ch;
                my $newlen = $cur_len + 1;
                my $k = "$nx,$ny";
                my $old = $minlen{$k};
                if (!defined $old || $newlen < $old) {
                    $minlen{$k} = $newlen;
                    $store{$k}  = [$newseq];
                    push @queue, [$nx, $ny, $newseq];
                } elsif ($newlen == $old) {
                    push @{$store{$k}}, $newseq;
                    push @queue, [$nx, $ny, $newseq];
                }
            }
        }
        my ($kx, $ky) = @{$pos{$start}};
        my $k0 = "$kx,$ky";
        $store{$k0} //= [''];
        for my $t (keys %pos) {
            my ($tx, $ty) = @{$pos{$t}};
            my $kt = "$tx,$ty";
            my $arr = $store{$kt} // [];
            my @withA = map { $_ . 'A' } @$arr;
            $paths{$start}{$t} = \@withA;
        }
    }
    return %paths;
}

my @num_rows = (
    "789",
    "456",
    "123",
    " 0A",
);

my @dir_rows = (
    " ^A",
    "<v>",
);

my %paths_num = build_paths(\@num_rows);
my %paths_dir = build_paths(\@dir_rows);

my %cache_seq;
my %cache_move_dir;
my %cache_move_num;

sub seq_cost {
    my ($level, $seq) = @_;
    my $key = "$level|$seq";
    return $cache_seq{$key} if exists $cache_seq{$key};
    my $cost;
    if ($level == 0) {
        $cost = length $seq;
    } else {
        my $from = 'A';
        $cost = 0;
        for my $c (split //, $seq) {
            $cost += move_cost_dir($level - 1, $from, $c);
            $from = $c;
        }
    }
    $cache_seq{$key} = $cost;
    return $cost;
}

sub move_cost_dir {
    my ($level, $from, $to) = @_;
    my $key = "$level:$from:$to";
    return $cache_move_dir{$key} if exists $cache_move_dir{$key};
    my $paths = $paths_dir{$from}{$to}
      or die "No dir path from $from to $to\n";
    my $best;
    for my $seq (@$paths) {
        my $c = seq_cost($level, $seq);
        $best = defined($best) ? ($c < $best ? $c : $best) : $c;
    }
    $cache_move_dir{$key} = $best;
    return $best;
}

sub move_cost_num {
    my ($level, $from, $to) = @_;
    my $key = "$level:$from:$to";
    return $cache_move_num{$key} if exists $cache_move_num{$key};
    my $paths = $paths_num{$from}{$to}
      or die "No num path from $from to $to\n";
    my $best;
    for my $seq (@$paths) {
        my $c = seq_cost($level, $seq);
        $best = defined($best) ? ($c < $best ? $c : $best) : $c;
    }
    $cache_move_num{$key} = $best;
    return $best;
}

sub code_cost {
    my ($code) = @_;
    my $from = 'A';
    my $total = 0;
    for my $c (split //, $code) {
        $total += move_cost_num($DEPTH, $from, $c);
        $from = $c;
    }
    return $total;
}

my $sum = 0;
for my $code (@codes) {
    my $cost = code_cost($code);
    (my $digits = $code) =~ s/[^0-9]//g;
    my $num = $digits eq '' ? 0 : int($digits);
    $sum += $cost * $num;
}

print "$sum\n";
