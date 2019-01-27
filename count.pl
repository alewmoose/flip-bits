#!/usr/bin/env perl
use v5.28;
use warnings;
use DDP;


my %cnt;

my ($size, $board, $n);

while (<<>>) {
    chomp;
    next unless length;
    next if /^-+$/;
    if (/size:\s*(\d+)/i) {
        $size = $1;
        $n = 0;
        next;
    }
    if ($size && $n < $size) {
        $board->[$n] = [ split ];
        $n++;
        next;
    }
    if ($n == $size) {
        <<>> for 1..4;
        for my $y (0..$size-1) {
            for my $x (0..$size-1) {
                $cnt{$y}{$x} += $board->[$y][$x];
            }
        }
    }
}

p %cnt;
