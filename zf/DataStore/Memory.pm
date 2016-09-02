package DataStore::Memory;
# Simulated DataStore with in memory data

=head1 NAME
DataStore::Memory - A simulated datastore to test edge cases.

=head1 SYNOPSIS

use DataStore::Memorry;

# Instantiate a Database handle for the application
DataStore::MySQL->new();

=head2 DESCRIPTION

DataStore::Memory is a subclass of Factory class DataStore.

The following interfaces for simulated datastore specific operations
are provided by it:
  get()
  set()
  update()
  delete()

=cut

use strict;
use warnings;
no warnings 'experimental::smartmatch';

our $VERSION = 1.0.1;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  bless {}, $class;
}

my $DataStore =
  { water_samples => [
  	               { id => 1,
                         site => undef,
  	                 chloroform => 0.00104,
                         bromoform  => 0,
                         bromodichloromethane => 0.00149,
                         dibromichloromethane => 0.00275,
                       },
  	               { id => 2,
  	                 site => 'Simulated Data',
  	                 chloroform => 0.00291,
                         bromoform  => 0.00487,
                       },
    	               { id => 3,
  	                 site => 'Simulate Data 2',
  	                 chloroform => 0.00065,
                         bromoform  => 0.00876,
                         bromodichloromethane => 0.0013,
                         dibromichloromethane => 0.00428,
                       },
   	               { id => 4,
  	                 site => 'Simulated Data 3',                  
  	                 chloroform => 0.00971,
                         bromoform  => 0.00317,
                         bromodichloromethane => 0.00931,
                         dibromichloromethane => 0.0116,
                       },
                     ],
   factor_weights => [
		       { id => 1,
			 chloroform_weight => 0.8,
                         bromodichloromethane_weight => 1.5,
 			 dibromichloromethane_weight => 0.7,
                       },
		       { id => 2,
			 chloroform_weight => 1,
			 bromoform_weight => 1,
                         bromodichloromethane_weight => 1,
 			 dibromichloromethane_weight => 1,
                       },
		       { id => 3,
			 chloroform_weight => 0.9,
			 bromoform_weight => 1.1,
                         bromodichloromethane_weight => 1.3,
 			 dibromichloromethane_weight => 0.6,
                       },
		       { id => 4,
			 chloroform_weight => 0,
			 bromoform_weight => 1,
                         bromodichloromethane_weight => 1,
 			 dibromichloromethane_weight => 1.7,
                       },
                     ]
  };

# connect() stub 
sub connect { return 1;	}

=over 12

=item C<get>

Retreives data from the data hash 

Required argument:
  Entity Name : what<string>,

Optional arguments:
  Entity details: value<list>
  Conditions    : condition<hash>

Return a list of hashes of retrieved data points

Example:
  my @list = $ds->get(
               -what => 'entityname',
               -value => [ detail1, detail2],
               -condition => { detail2 => 'val1',
                               detail3 => 'val2' }); 

  # return format
  @rows: [ { detail1: val1, detail2: val2 },
           { detail1: val3, detail2: val4 },
           { detail1: val5, detail2: val6 } ]
  
=back

=cut

sub get {
  my $self = shift;
  my %opts = @_;   # { what: , value: [], condition: }

  die "DataStore error: Cannot get: Missing argument -what\n"
    if !$opts{-what};

  die "DataStore error: Cannot get $opts{-what}: Invalid entity '$opts{-what}'\n"
    if !exists $opts{-what} || !exists $DataStore->{$opts{-what}};

  die "DataStore error: Cannot get $opts{-what}: Invalid values requested ", join(',', @{$opts{-value}}),"\n"
    if grep { ! exists $DataStore->{$opts{-what}}[0]->{$_}  } @{$opts{-value}};

  map {
    my $a = $_;
    !@{$opts{-value}} ? $a : {map {  $_ => $a->{$_} } @{$opts{-value}}};
  }
  grep {
    my $sample = $_;
    my @matched_conditions = grep { $sample->{$_} ~~ $opts{-condition}->{$_} }
    			     keys %{$opts{-condition}};  
    @matched_conditions == keys %{$opts{-condition}}
  }
  @{$DataStore->{$opts{-what}}};
}

=over 12

=item C<set>

Inserts data into the datastore. It is only available 
for the current instance of the application.

Required argument:
  Entity Name   : what<string>,
  Entity Details: value<hash>

Example:
  my $ds = DataStore::Memory->new()

  $ds->set(-what  => 'entityname',
           -value => { detail2 => 'val1',
                       detail1 => 'val2' }); 

=back

=cut


sub set {
  my $self = shift;
  use Data::Dumper;
  my %opts = @_;  # {what: , value: {}}

  die "DataStore error: Cannot get $opts{-what}: Invalid entity '$opts{-what}'\n"
    if !exists $DataStore->{$opts{-what}};
  
  die "DataStore error: Cannot get $opts{-what}: Invalid values: ", Dumper($opts{-value}), "\n"
    if ! $opts{-value};

  push @{$DataStore->{$opts{-what}}}, $opts{-value};
}

=item C<update>

Updates data in the simulated datastore. The update
is only application for the current instance of 
the application. 

Required argument:
  Entity Name   : what<string>,
  Entity Details: value<hash>
  Clauses      : condition<hash>

Example:
  my $ds = DataStore::Memory->new();

  $ds->update(
    -what => 'entityname',
    -value => { detail2 => 'val1',
                detail1 => 'val2' }
    -condition => { detail3 => 'val3',
                    detail4 => 'val4'}); 

  # return format
  @list: [ { detail1: val1, detail3: val2 },
           { detail1: val3, detail3: val4 },
           { detail1: val5, detail3: val6 } ]

=back

=cut

sub update {
  my $self = shift;

  my %opts = @_;  # {what: , value: {}, condition: {} }

  die "DataStore error: Cannot update $opts{-what}: Invalid entity '$opts{-what}'\n"
    if !exists $DataStore->{$opts{-what}};

  map {
    my $to_update = $_;
    map { $to_update->{$_} = $opts{-value}->{$_} } keys %{$opts{-value}}
  }
  grep {
    my $item = $_;
    my @matched_conditions = grep { $item->{$_} ~~ $opts{-condition}->{$_} }
    			     keys %{$opts{-condition}||{}};  
    @matched_conditions == keys %{$opts{-condition}||{}}; 
  }
  @{$DataStore->{$opts{-what}}};
}

=over 12

=item C<remove>

Deletes data from datastore. The delete only stays in effect for
the current instance of the application.

Required argument:
  Entity Name  : what<string>,
  Clauses      : condition<hash>

Example:
  my $ds = DataStore::Memory->new()

  $ds->remove(
    -what => 'entityname',
    -condition => { detail3 => 'val3',
                    detail4 => 'val4'}); 

=back

=cut


sub remove {
  my $self = shift;

  my %opts = @_;   # { what: , condition: {} }

  die "DataStore error: Cannot remove $opts{-what}: Invalid entity '$opts{-what}'\n"
    if !exists $DataStore->{$opts{-what}};
  
  my @remaining_entries =
    grep {
      my $item = $_;
      my @matched_conditions = grep { $item->{$_} ~~ $opts{-condition}->{$_} }
      			     keys %{$opts{-condition}||{}};  
      @matched_conditions != keys %{$opts{-condition}||{}};     # filter out entries that match all given criteria  
    }
    @{$DataStore->{$opts{-what}}};

  $DataStore->{$opts{-what}} = [ @remaining_entries ];
}

1;
