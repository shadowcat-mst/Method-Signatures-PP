use strict;
use warnings;
use Test::More;
use Method::Signatures::PP;

package Wat;

use Moo;

method foo {
  "FOO from ".ref($self);
}

method bar ($arg) {
  "WOOO $arg";
}

package main;

my $wat = Wat->new;

is($wat->foo, 'FOO from Wat', 'Parenless method');

is($wat->bar('BAR'), 'WOOO BAR', 'Method w/argument');

done_testing;
