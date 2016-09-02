package WaterSample;
=head1 NAME
WaterSample - A module to manage Water Sample analysis in LA County

=head1 SYNOPSIS

use WaterSample;

# Lookup a Water Sample by sample ID
my $waterSample = WaterSample->find(sampleId);

# View details of the Water Sample as key value pairs
$waterSample->to_hash();

=cut

use strict;
use warnings;
use DataStore qw($DS); # Imported singleton DataStore handle
use Factor qw(linear_combination);

our $VERSION = 1.0.1;

use constant CONTAMINANTS => qw(chloroform bromoform bromodichloromethane dibromichloromethane);

=head1 METHODS

=over 12

=item C<new>

Instantiates WaterSample object.

Required argument:
  Water Sample ID          : id<int>

Optional arguments:
  Water Sample Name        : sample<string>,
  Water Sample Contaminants: contaminants<hash>

Return an object of Class WaterSample

=back

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %opts = @_;
  bless { id           => ($opts{-id} || die "Cannot instantiate WaterSample: Missing argument: '-id'") ,
          site         => $opts{-site},
	  contaminants => $opts{-contaminants}||{}
         }, $class;
}

=over 12

=item C<find>

Looks up a Water Sample by ID.

Required argument:
  Water Sample Site ID          : id<int>

Return an object of Class WaterSample

Example:
  my $waterSample = WaterSample->find(2);

=back

=cut

sub find {
  my $self = shift;
  my $sample_id = shift || die "Cannot find water sample: No sample id provided\n";

  # Datastore lookup
  my $water_sample = ($DS->get(-what      => 'water_samples',
   		    	       -condition => {id => $sample_id}))[0];

  my $sample = WaterSample->new(-id   => ($water_sample->{id} || die "Cannot find water sample for ID: $sample_id\n"),
		   	        -site => $water_sample->{site},
			        -contaminants => { map { $_ => $water_sample->{$_} } CONTAMINANTS });
  return $sample;
}

=over 12

=item C<factor>

Computes the nth factor for a Water Sample

Required argument:
  Factor ID (n): id<int>

Returns computed nth factor

Example:
  my $waterSample = WaterSample->find(2);
  $waterSample->factor(6); # computes the 6th factor of water sample #2

=back

=cut

sub factor {
  my ($self, $factor_weights_id) = @_;
  die "Cannot compute factor: No factor weight id provided\n" if ! defined $factor_weights_id;

  # Datastore lookup get factors for the given sample
  my $factors = ($DS->get(-what      => 'factor_weights',
   	    	  	  -condition => {id => $factor_weights_id}))[0];

  die "Cannot compute factor: Factor weights not available for factor_weights::id: $factor_weights_id\n" if !$factors; 

  my $computed_factor = linear_combination( map { $_ => { weight => $factors->{$_."_weight"}||1,
                                                          value  => $self->{contaminants}{$_}}
					        }
                                            grep { $self->{contaminants}{$_} } # consider only the chemicals that have defined values
 					    CONTAMINANTS);
  return $computed_factor;
}

=over 12

=item C<to_hash>

Provides water sample details in the form of key-value pairs.

Optional argument:
  Flag to include computed factors: include_factors<flag:1/0> -defaults to 0

Returns a hash of water sample details

Example:
  my $waterSample = WaterSample->find(2);
  $waterSample->to_hash();
  $waterSample->to_hash(1);

=back

=cut

sub to_hash {
  my ($self, $include_factors) = @_;

  return { id   => $self->{id},
           site => $self->{site},
           (map {  $_ => $self->{contaminants}{$_} } CONTAMINANTS),
           ($include_factors ? ( $self->_factors ) : ()) } 
}

# Accessor methods
sub site                 { return shift->{site} }
sub chloroform           { return shift->{contaminants}{chloroform} }
sub bromoform            { return shift->{contaminants}{bromoform} }
sub bromodichloromethane { return shift->{contaminants}{bromodichloromethane} }
sub dibromichloromethane { return shift->{contaminants}{dibromichloromethane} }

# Private methods
sub _factors {
  my $self = shift;
  my @factor_weights = $DS->get(-what => 'factor_weights');	

  map {
    my $factors = $_;
    "factor_".$factors->{id} => linear_combination(
				  map { $_ => { weight => $factors->{$_."_weight"}||1,
                                                value  => $self->{contaminants}{$_}}
			              }
                                  grep { $self->{contaminants}{$_} } # consider only the chemicals that have defined values
                                  CONTAMINANTS
                                );
  } @factor_weights;
}

=head1 AUTHOR

A Bhave

=cut;
