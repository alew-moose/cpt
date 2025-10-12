#!/usr/bin/env perl
use v5.42;

package Accessor::Hash;
use Carp 'croak';

sub new($proto, %args) {
    if (ref $proto) {
        return bless {%$proto, %args} => ref $proto;
    } else {
        return bless \%args => $proto;
    }
}

sub make_accessors($class, @fields) {
    no strict 'refs';
    croak 'make_accessors is a class method' if ref $class;
    for my $field (@fields) {
        *{"${class}::$field"} = sub {
            if (@_ == 1) {
                return $_[0]{$field};
            } elsif (@_ == 2) {
                return $_[0]{$field} = $_[1];
            } else {
                croak "$field takes 0 or 1 argument";
            }
        };
    }
}

package Accessor::Array;
use Carp 'croak';

my %field_index;

sub new ($proto, %args) {
    my ($self, $class);
    if (ref $proto) {
        $class = ref $proto;
        $self = bless [@$proto] => $class;
    } else {
        $class = $proto;
        $self = bless [] => $class;
    }
    for my $key (keys %args) {
        my $index = $field_index{$class}{$key} // croak "unknown field '$key'";
        $self->[$index] = $args{$key};
    }
    return $self;
}

sub make_accessors($class, @fields) {
    no strict 'refs';
    croak 'make_accessors is a class method' if ref $class;
    for my $field (@fields) {
        *{"${class}::$field"} = _make_accessor($class, $field);
    }
}

sub _make_accessor($class, $field) {
    my $index = _field_index($class, $field);
    eval sprintf q{
        sub {
            if (@_ == 1) {
                return $_[0][%d];
            } elsif (@_ == 2) {
                return $_[0][%d] = $_[1];
            } else {
                croak "$field takes 0 or 1 argument";
            }
        };
    }, $index, $index;
}

sub _field_index($class, $field) {
    my $index = $field_index{$class}{$field};
    return $index if defined $index;
    return $field_index{$class}{$field} = %{$field_index{$class}};
}

package FooHash;
use base 'Accessor::Hash';
FooHash->make_accessors(qw(field));

package FooArray;
use base 'Accessor::Array';
FooArray->make_accessors(qw(field));


package main;
use Benchmark qw(cmpthese timethese);

my $foo_hash = FooHash->new;
my $foo_array = FooArray->new;

cmpthese(1e7, {
    hash_getter  => sub { $foo_hash->field },
    array_getter => sub { $foo_array->field },
});

cmpthese(1e7, {
    array_setter => sub { $foo_array->field(42) },
    hash_setter  => sub { $foo_hash->field(42) },
});

