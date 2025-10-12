#!/usr/bin/env perl
use v5.42;
use Carp 'croak';
use Benchmark 'cmpthese';


sub find_closest_linear($array, $target) {
    croak 'array is empty' unless @$array;
    my $closest_idx = 0;
    my $closest_diff = abs($array->[0] - $target);
    for (my $i = 1; $i <= $#$array; $i++) {
        return $i if $target == $array->[$i];
        my $diff = abs($array->[$i] - $target);
        if ($diff < $closest_diff) {
            $closest_diff = $diff;
            $closest_idx = $i;
        }
    }
    return $closest_idx;
}

sub find_closest($array, $target) {
    croak 'array is empty' unless @$array;
    my ($closest_idx, $low, $high) = (0, 0, $#$array);
    while ($low <= $high) {
        my $mid = $low + int(($high - $low) / 2);
        if (abs($target - $array->[$mid]) < abs($target - $array->[$closest_idx])) {
            $closest_idx = $mid;
        }
        if ($array->[$mid] == $target) {
            return $mid;
        } elsif ($array->[$mid] < $target) {
            $low = $mid + 1;
        } else {
            $high = $mid - 1;
        }
    }
    return $closest_idx;
}


my $array = [0..1e6];
cmpthese(100, {
    linear        => sub { find_closest_linear($array, 500_000) },
    binary_search => sub { find_closest($array, 500_000) },
});

