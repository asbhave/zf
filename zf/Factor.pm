package Factor;
=head1 NAME
Factor - Utility module for factor computations.

=head1 SYNOPSIS

Module houses statistical algorithm implementations.
                 
=cut

use strict;
use warnings;

use base qw(Exporter); our @EXPORT_OK = qw(linear_combination);

=head1 FUNCTIONS

=over 12

=item C<linear_combinations>

Return linear combination of given values.

Required argument:
  Weights and values: <hash>

Return computed result of the linear combination

Example:
  my $factor = linear_combination(
		 name1 => { weight => 1, value  => 2 },
                 name2 => { weight => 1, value  => 3 }
               );

  # Returns: 5

=head1 TODO

linear_combination() does not validate input to be numeric.
There are external Perl modules that can be employed for this purpose:
Ref: http://perldoc.perl.org/perlfaq4.html#How-do-I-determine-whether-a-scalar-is-a-number%2fwhole%2finteger%2ffloat%3f

=back

=cut

sub linear_combination(%) {
  my %weights_and_vals= @_;
  my $factor = 0;
  map {
    my $item = $weights_and_vals{$_};
    $factor += $item->{value} * $item->{weight};
  } keys %weights_and_vals;

  return $factor;
}
