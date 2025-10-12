#!/usr/bin/env perl
use v5.42;
# use utf8;
# use DDP;
# use mro 'c3';


# package AA;
# sub func { print "AA\n" }
# package BB;
# use parent -norequire, 'AA';
# sub func { print "BB\n"; shift->SUPER::func(@_); }
# package CC;
# use parent -norequire, 'AA';
# sub func { print "CC\n"; shift->SUPER::func(@_); }
# package DD;
# use parent -norequire, qw/BB CC/;
# sub func { print "DD\n"; shift->SUPER::func(@_); }
# package main;
# DD->func;

package AA;
sub func { print "AA\n" }

package BB;
use parent -norequire, 'AA';
sub func { print "BB\n"; shift->next::method(@_); }

package CC;
use parent -norequire, 'AA';
sub func { print "CC\n"; shift->next::method(@_); }

package DD;
use parent -norequire, qw/BB CC/;
sub func { print "DD\n"; shift->next::method(@_); }

package main;
use mro;
DD->func;

