package DataStore::MySQL;

=head1 NAME
DataStore::MySQL - A Singleton Class to maintain a single database
                   connection within the application.

=head1 SYNOPSIS

use DataStore::MySQL;

# Instantiate a Database handle for the application
DataStore::MySQL->new(
  -database => 'testDB',
  -username => 'DBuser',
  -port     => 'MysqlPort' || 3306,
  -host     => 'DBHost',
  -password => 'DBuserpassword');

=head2 DESCRIPTION

DataStore::MySQL is a subclass of Factory class DataStore.

The following interfaces for MySQL specific operations
are provided by it:
  get()
  set()
  update()
  delete()
                
=cut

use strict;
use warnings;
use DBI;

our $VERSION = 1.0.1;

my $dbh;

=head1 METHODS

=over 12

=item C<new>

Instantiates DataStore::MySQL object.

Required argument:
  Database Name : database<string>,
  Database User : username<string>,
  Database Host : host<string>,
  Database Password : password<string>

Optional arguments:
  Mysql Port  : port defaults to 3306,
  Encoding    : encoding

Return an object of DataStore::MySQL including
a connected database handle

=back

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %opts = @_;

  my $obj = bless { _handle      => undef,
                    _database    => $opts{-database}||'',
                    _username    => $opts{-username}||'',
                    _port        => $opts{-port}||3306,
                    _host        => $opts{-host}||'',
                    _password    => $opts{-password}||'',
                    _encoding    => $opts{-encoding}||'',
                  }, $class;
  $dbh ||= $obj->connect(); # implement a singleton
  $obj->{-dbh} = $dbh;
  return $obj
}

sub connect {
  my $self = shift;

  my $dbh = DBI->connect("DBI:mysql:database=$self->{_database};host=$self->{_host};port=$self->{_port}",
                         $self->{_username}, $self->{_password},
                         {'RaiseError' => 1}) or die "Unable to connect to MySQL: $DBI::errstr\n";
  return $dbh;
}

=over 12

=item C<get>

Retreives data from the MySQL database 
tables based on given arguments.

Required argument:
  Table Name : what<string>,

Optional arguments:
  Table columms: value<list>
  Clauses      : condition<hash>

Return a list of hashes of retrieved database rows

Example:
  my $ds = DataStore::MySQL->new(
             -database => 'testDB',
             -username => 'DBuser',
             -port     => 'MysqlPort' || 3306,
             -host     => 'DBHost',
             -password => 'DBuserpassword');

  my @rows = $ds->get(
               -what => 'tablename',
               -value => [ col1, col3],
               -condition => { col2 => 'val1',
                               col1 => 'val2' }); 

  # return format
  @rows: [ { col1: val1, col3: val2 },
           { col1: val3, col3: val4 },
           { col1: val5, col3: val6 } ]
  
=back

=cut

sub get {
  my $self = shift;
  my %opts = @_;   #{-what: , -value: [], -condition: {}}

  die "Cannot get data. Missing argument: '-what'\n" if !$opts{-what};

  my $table = $opts{-what};
  my @cols  = $opts{-value} ? @{$opts{-value}} : ();
  my @condition_cols = ($opts{-condition} && keys %{$opts{-condition}}) ? keys %{$opts{-condition}} : ();
  my @condition_vals = @condition_cols ? values %{$opts{-condition}} : ();
  my @conditions     = map { "$_ = ?" } @condition_cols;

  my $sql = join(' ', "SELECT",
		       join(',', (@cols ? @cols : '*')),
 		      "FROM",
		      $table,
                      (@condition_cols ? ("WHERE", join (' AND ', @conditions)) : ())
                );
  my $sth = $self->{-dbh}->prepare($sql);
  $sth->execute(@condition_vals);
  	
  if ($sth->err) {
    die "Cannot get $opts{-what}: $sth->err\n";
  }
  my @results;
  while (my $ref = $sth->fetchrow_hashref()) {
    push @results, $ref;
  }
  $sth->finish();
  return @results;
}

=over 12

=item C<set>

Insert data into the MySQL database 
tables based on given arguments.

Required argument:
  Table Name : what<string>,
  Table columms: value<hash>

Example:
  my $ds = DataStore::MySQL->new(
             -database => 'testDB',
             -username => 'DBuser',
             -port     => 'MysqlPort' || 3306,
             -host     => 'DBHost',
             -password => 'DBuserpassword');

  $ds->set(
    -what => 'tablename',
    -value => { col2 => 'val1',
                col1 => 'val2' }); 

=back

=cut

sub set {
  my $self = shift;
  
  my %opts = @_;  # {-what: , -value: }

  die "Cannot set data. Missing argument: '-what'\n" if !$opts{-what};

  my $table = $opts{-what};
  my @cols  = $opts{-value} ? keys %{$opts{-value}} : ();
  my @vals  = $opts{-value} ? values %{$opts{-value}} : ();

  my $sql = join(' ', "INSERT INTO",
                      $table,
                      ($opts{-value} ? ('(', join(',', @cols), ')',
					 "VALUES",
 					 '(', join(',', ("?") x @vals), ')' ) : ())
                );

  my $sth = $self->{-dbh}->prepare($sql);
  $sth->execute(@vals);

  if ($sth->err) {
    die "Cannot set $opts{-what}: $sth->err\n";
  }
}

=over 12

=item C<update>

Update data in the MySQL database tables
based on given arguments.

Required argument:
  Table Name   : what<string>,
  Table columms: value<hash>
  Clauses      : condition<hash>

Example:
  my $ds = DataStore::MySQL->new(
             -database => 'testDB',
	     -username => 'DBuser',
             -port     => 'MysqlPort' || 3306,
             -host     => 'DBHost',
             -password => 'DBuserpassword');

  $ds->update(
    -what => 'tablename',
    -value => { col2 => 'val1',
                col1 => 'val2' }
    -condition => { col3 => 'val3',
                    col4 => 'val4'}); 

  # return format
  @rows: [ { col1: val1, col3: val2 },
           { col1: val3, col3: val4 },
           { col1: val5, col3: val6 } ]

=back

=cut

sub update {
  my $self = shift;

  my %opts = @_;

  die "Cannot update data. Missing argument: 'what'\n" if !$opts{-what};

  my $table = $opts{-what};
  my @cols  = $opts{-value} ? keys %{$opts{-value}}   : ();
  my @vals  = @cols          ? values %{$opts{-value}} : ();
  my @condition_cols = ($opts{-condition} && keys %{$opts{-condition}}) ? keys %{$opts{-condition}} : ();
  my @condition_vals = @condition_cols ? values %{$opts{-condition}} : ();
  my @col_clauses    = map { "$_ = ?" } @cols;

  my $sql = join(' ', "UPDATE",
		      $table,
                      (@cols ? ("SET", join(',', @col_clauses)) : ()),
                      (@condition_cols ? ("WHERE", join(' AND ', map { "$_ = ?" } @condition_cols)) : ())
                ); 
                      
  my $sth = $self->{-dbh}->prepare($sql);
  $sth->execute(@vals, @condition_vals);

  if ($sth->err) {
    die "Cannot update $opts{-what}: $sth->err\n";
  }
}

=over 12

=item C<remove>

Delete data from MySQL database tables
based on given arguments.

Required argument:
  Table Name   : what<string>,
  Clauses      : condition<hash>

Example:
  my $ds = DataStore::MySQL->new(
            -database => 'testDB',
	    -username => 'DBuser',
            -port     => 'MysqlPort' || 3306,
            -host     => 'DBHost',
            -password => 'DBuserpassword');

  $ds->remove(
    -what => 'tablename',
    -condition => { col3 => 'val3',
                    col4 => 'val4'}); 

=back

=cut

sub remove {
  my $self = shift;

  my %opts = @_;

  die "Cannot remove data. Missing argument: 'what'\n" if !$opts{-what};

  my $table = $opts{-what};
  my @condition_cols = ($opts{-condition} && keys %{$opts{-condition}}) ? keys %{$opts{-condition}} : ();
  my @condition_vals = @condition_cols ? values %{$opts{-condition}} : ();

  my $sql = join(' ', "DELETE FROM",
		      $table,
                      (@condition_cols ? ("WHERE", join(' AND ', map { "$_ = ?" } @condition_cols)) : ())
                ); 
                      
  my $sth = $self->{-dbh}->prepare($sql);
  $sth->execute(@condition_vals);

  if ($sth->err) {
    die "Cannot remove $opts{-what}: $sth->err\n";
  }
}


1;
