#!/usr/bin/env perl
use v5.42;
use Benchmark;
use DDP;

sub delete_duplicate_values($hash) {
    my %seen;
    while (my ($key, $val) = each %$hash) {
        if ($seen{$val}) {
            delete $hash->{$key};
        } else {
            $seen{$val} = 1;
        }
    }
}

sub delete_duplicate_values2($hash) {
    my %seen;
    while (my ($key, $val) = each %$hash) {
        delete $hash->{$key} if $seen{$val}++;
    }
}

sub delete_duplicate_values3($hash) {
    my %vals;
    while (my ($key, $val) = each %$hash) {
        $vals{$val} = $key;
    }
    my %copy;
    while (my ($val, $key) = each %vals) {
        $copy{$key} = $val;
    }
    %$hash = %copy;
}


sub new_hash {
    my %hash;
    my $key = 'a';
    my $n = 0;

    for (0..1e6) {
        $hash{$key++} = $n++;
        $n = 0 if $n >= 9;
    }
    
    return \%hash;
}

my $hash = new_hash;

timethese(10, {
    1 => sub { my %h = %$hash; delete_duplicate_values(\%h); },
    2 => sub { my %h = %$hash; delete_duplicate_values2(\%h); },
    3 => sub { my %h = %$hash; delete_duplicate_values3(\%h); },
});





