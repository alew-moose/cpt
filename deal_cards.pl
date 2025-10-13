#!/usr/bin/env perl
use v5.42;
use List::Util qw(shuffle);
use Crypt::PRNG;

sub new_deck {
    my @deck;
    for my $suit (qw(s h c d)) {
        for my $rank (2..10, qw(J Q K A)) {
            push @deck, $rank . $suit;
        }
    }
    return \@deck;
}

sub deal_cards {
    local $List::Util::RAND = Crypt::PRNG::rand;
    my $deck = new_deck();
    @$deck = shuffle @$deck;
    my (@pocket, @community);
    for (0..8) {
        push @pocket, [splice @$deck, 0, 2];
    }
    @community = splice @$deck, 0, 5;
    return \@pocket, \@community;
}

my ($pocket, $community) = deal_cards();
for my $p (0..$#$pocket) {
    say "Player $p: @{$pocket->[$p]}";
}
say "Community: @$community";
