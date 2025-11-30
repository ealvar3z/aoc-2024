#!/usr/bin/env perl
use strict;
use warnings;

# Day 23 – LAN Party (Parts 1 and 2) in Perl
# Input: lines "aa-bb" describing undirected edges.

my %adj;  # adjacency: $adj{u}{v} = 1

while (my $line = <STDIN>) {
    chomp $line;
    next if $line =~ /^\s*$/;
    my ($a, $b) = split /-/, $line;
    next unless defined $a && defined $b;
    $adj{$a}{$b} = 1;
    $adj{$b}{$a} = 1;
}

# Part 1

my $triangle_count = 0;

for my $a (sort keys %adj) {
    my @nbrs = grep { $_ gt $a } sort keys %{ $adj{$a} };
    my $n = @nbrs;
    for (my $i = 0; $i < $n; $i++) {
        my $b = $nbrs[$i];
        my %nb_b = %{ $adj{$b} };  # neighbors of b
        for (my $j = $i + 1; $j < $n; $j++) {
            my $c = $nbrs[$j];
            next unless $nb_b{$c};  # triangle a,b,c

            if (substr($a,0,1) eq 't'
             || substr($b,0,1) eq 't'
             || substr($c,0,1) eq 't') {
                $triangle_count++;
            }
        }
    }
}

# Part 2

my @all_nodes = sort keys %adj;

my @best_clique = ();

sub neighbors_of {
    my ($v) = @_;
    return keys %{ $adj{$v} } if exists $adj{$v};
    return ();
}

sub intersect_with_neighbors {
    my ($set_ref, $v) = @_;
    my %nbr = %{ $adj{$v} };
    my @res = grep { $nbr{$_} } @$set_ref;
    return \@res;
}

sub bronk {
    my ($R_ref, $P_ref, $X_ref) = @_;

    if (!@$P_ref && !@$X_ref) {
        if (@$R_ref > @best_clique) {
            @best_clique = @$R_ref;
        }
        return;
    }

    my @P = @$P_ref;

    for my $v (@P) {
        my @R2 = (@$R_ref, $v);
        my $P2 = intersect_with_neighbors($P_ref, $v);
        my $X2 = intersect_with_neighbors($X_ref, $v);

        bronk(\@R2, $P2, $X2);

        @$P_ref = grep { $_ ne $v } @$P_ref;
        push @$X_ref, $v;
    }
}

my @R0 = ();
my @P0 = @all_nodes;
my @X0 = ();

bronk(\@R0, \@P0, \@X0);

@best_clique = sort @best_clique;
my $password = join(",", @best_clique);

print "$triangle_count\n";
print "$password\n";
