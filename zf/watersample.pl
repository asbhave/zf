#/usr/bin/perl
# A simple client script to demonstrate how to use the application interfaces
use strict;
use warnings;

use Data::Dumper;
use WaterSample;
use DataStore;

$Data::Dumper::Sortkeys = sub { [sort {length($a) <=> length($b)} keys %{$_[0]}] };
$Data::Dumper::Terse    = 1;

# Initialize DataStore connection
my $host     = 'localhost';
my $database = 'zf';
my $password = 'zfpass';
my $user     = 'root';
my $ds = DataStore->new(
	   'MySQL',
           -database => $database,
           -host     => $host,
           -username => $user,
           -password => $password);

# Retrieve IDs of all available water samples
my @water_samples = $ds->get(-what => 'water_samples');

#######################
# See all water samples
foreach (@water_samples) {
  my $water_sample_obj = WaterSample->find($_->{id});

  
  print "\nWater sample ($water_sample_obj->{site}) with computed factors:\n",
         Dumper($water_sample_obj->to_hash(1));

   print Dumper($water_sample_obj->to_hash());
}

#########################
# Individual samples

my $ws = WaterSample->find(1);
my $factor = $ws->factor(2);

print "\n\n Factor 2 for water sample 1 is: ", $factor, "\n";
