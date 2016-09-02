use strict;
use warnings;

use DBI;
use Data::Dumper;
use DataStore qw($DS);
use Test::More tests => 28;
use Test::Exception;

$Data::Dumper::Terse = 1;
## root@localhost: zfpass
my $host     = 'localhost';
my $database = 'zf';
my $password = 'zfpass';
my $user     = 'root';

# Test package is included correctly
use_ok('WaterSample');
use_ok('DBI');
use_ok('DataStore');
use_ok('DataStore::MySQL');

##################################
# DataStore connectivity tests
print "-------------------------------------\n";
print "Test DB instatiation\n";
my $ds = DataStore->new('MySQL',
			-database => $database,
			-host     => $host,
			-username => $user,
			-password => $password);
isa_ok($ds, "DataStore::MySQL");
ok(defined $ds, "MySQL DataStore connection successful");

my @water_site = $ds->get(-what      => 'water_samples',
         		  -value     => ['site'],
         		  -condition => {id => 1});

is($water_site[0]->{site}, 'LA Aquaduct Filteration Plant Effluent', "Found 'LA Aquaduct Filteration Plant Effluent' water sample site");

@water_site = $ds->get(-what      => 'water_samples',
        	       -condition => {id => 2}
                       # omit -value to get all data
                      );
is($water_site[0]->{chloroform}, 0.00291, "Found 0.00291 chloroform in site 2");

@water_site = $ds->get(-what => 'water_samples');
is(scalar @water_site, 4, "Found 4 sites");

$ds->set(-what   => 'water_samples',
         -value  => { site       => 'Test site',
                      chloroform => 0.666 });

@water_site = $ds->get(-what      => 'water_samples',
                       -condition => {site => "Test site"});
is($water_site[0]->{chloroform}, 0.666, "New water sample site added");

$ds->update(-what      => 'water_samples',
            -value     => { chloroform => 0.555, bromoform => 0.25 },
            -condition => {site => "Test site"});
@water_site = $ds->get(-what => 'water_samples',
                       -condition => {site => "Test site"});
is($water_site[0]->{chloroform}, 0.555, "New water sample site updated");

my $new_water_site = WaterSample->find($water_site[0]->{id});
is($new_water_site->factor(2), 0.805,  "New site factor 2 verified: 0.805");
is($new_water_site->factor(3), 0.7745, "New site factor 3 verified: 0.7745");

$ds->remove(-what      => 'water_samples',
            -condition => {site => "Test site"});
@water_site = $ds->get(-what => 'water_samples',
                       -condition => {site => "Test site"});
is(scalar @water_site, 0, "Water sample site 'Test site' removed");

$ds->set(-what   => 'water_samples',
         -value  => { site => 'Test site 2',
                      chloroform => 0.666 });

@water_site = $ds->get(-what      => 'water_samples',
                       -condition => {chloroform => 0.666});
is($water_site[0], undef, "Floating point comparison fails: known issue");

@water_site = $ds->get(-what      => 'water_samples',
                       -condition => { site => 'Test site 2' });

$ds->update(-what   => 'water_samples',
            -value  => { site => undef },
            -condition => { site => 'Test site 2' });

$new_water_site = WaterSample->find($water_site[0]->{id});
is($new_water_site->{site}, undef, "Update column to NULL");

$ds->remove(-what      => 'water_samples',
            -condition => {id => $water_site[0]->{id}});
@water_site = $ds->get(-what => 'water_samples',
                       -condition => {id => $water_site[0]->{id}});
is(scalar @water_site, 0, "Water sample site 'Test site 2' removed");

print "\nDB 'get' validation tests\n";
dies_ok(sub { $ds->get(-what  => 'factor_weight',
                       -condition => {id => 100}) },
        "Failed to retrieve from non-existent DB table");

dies_ok(sub { $ds->get(-condition => {id => 100}) },
        "Failed to retrieve with missing argument");

######################################
# Class and interface tests
print "-------------------------------------\n";
print "Test WaterSample Class methods and interfaces \n";
my $site3 = WaterSample->find(3);
is($site3->{site}, 'Jensen Plant Effluent', "Found 'Jensen Plant Effluent' site");

dies_ok(sub { $site3->factor(10);}, "Failed to compute factor for invalid id");
my $computed_factor = $site3->factor(5);;
is($computed_factor, 0.01479, "Computed factor with missing weights verified: 0.01479");

my $site3_to_hash = $site3->to_hash();
is($site3->site(), $site3_to_hash->{site}, "Site 3: Site: $site3->{site}");
is($site3->chloroform(), $site3_to_hash->{chloroform}, "Site 3: Chloroform: $site3_to_hash->{chloroform}");
is($site3->bromoform(), $site3_to_hash->{bromoform}, "Site 3: Bromoform: $site3_to_hash->{bromoform}");
is($site3->bromodichloromethane(), $site3_to_hash->{bromodichloromethane}, "Site 3: Bromodichloromethane: $site3_to_hash->{bromodichloromethane}");
is($site3->dibromichloromethane(), $site3_to_hash->{dibromichloromethane}, "Site 3: Dibromichloromethane: $site3_to_hash->{dibromichloromethane}");

my $site4 = WaterSample->find(4);
my $site4_factor = $site4->factor(2);
is($site4_factor, .03379, "Computed sample 4, 2nd factor: $site4_factor = .03379");
my $site4_to_hash = $site4->to_hash(1);
print "Hash format of site4:\n", Dumper($site4_to_hash);


