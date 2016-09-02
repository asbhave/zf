use strict;
use warnings;

use Factor qw(linear_combination);
use Test::More tests => 2;
use Test::Warn;

my $factor;
$factor = linear_combination();
is($factor, 0, "Missing arguments case passed");

warning_like(sub { $factor = linear_combination(a => {value => 'e', weight => 2},
                                                b => {value => 1, weight => 3}) },
          '/isn\'t numeric in multiplication/', "Exception for Non-numeric values in computation");

