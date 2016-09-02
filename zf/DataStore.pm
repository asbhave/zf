package DataStore;

=head1 NAME
DataStore - Factory pattern to initialize different datastores.

=head1 SYNOPSIS

The factory defers object instantiation to its subclasses based on requested type.

use DataStore;

# Instantiate a DataStore based on requested type
my $ds = DataStore->new('DataStoreType');

Returns an object of one of the subclasses
                 
=cut

use strict;
use warnings;
use DataStore::MySQL;
use DataStore::Memory;

our $VERSION = 1.0.1;
our $DS;  # Global DataStore object

# Export the DataStore objects so other modules in the application can access it.
use base qw(Exporter); our @EXPORT_OK = qw($DS);

sub new {
  # Invoke the construtor of the subclass if not already initialized.
  return $DS ||= do {
  		      my $class          = shift;
  		      my $requested_type = shift;
  		      my $location       = "DataStore/".$requested_type.".pm";
  		      my $req_class      = "DataStore::".$requested_type;
  		      $req_class->new(@_);
 		    };
}

=head1 AUTHOR

A Bhave

=head1 SEE ALSO

L<DataStore::MySQL>, L<DataStore::Memory>

=cut;

1;
