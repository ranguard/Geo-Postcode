#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;

use lib qw( ./lib );
use ExtUtils::MakeMaker;
use DBI;
$|++;

my $csvdata = './useful/postcodes.csv';
my $datafile = './lib/Geo/Postcode/postcodes.db';
my $tablename = 'postcodes';

create_sqlite_file() unless -e $datafile;

WriteMakefile(
    NAME => 'Geo::Postcode',
    VERSION_FROM => 'lib/Geo/Postcode.pm',
    PREREQ_PM => { 'DBD::SQLite' => 0 },
    ($] >= 5.005 ?
        (ABSTRACT_FROM => 'lib/Geo/Postcode.pm', AUTHOR => 'william ross <wross@cpan.org>') : ()
    ),
    clean => { 'FILES' => $datafile },
);

sub create_sqlite_file {
    print "Creating sample data file.\n";
    my $dbh;
    eval {
        $dbh = DBI->connect("dbi:SQLite:dbname=$datafile","","");
    };
    if ($@) {
        print "Connection failed. Is DBD::SQLite installed? Makemaker will tell us:\n";
        return;
    }
    
    open( INPUT, $csvdata) || die("can't open file $csvdata: $!");
    
    my @cols = split(',',<INPUT>);
    my $columns = join(', ', map { "$_ varchar(255)" } grep { $_ ne 'postcode' } @cols);
    $dbh->do("create table $tablename (postcode varchar(12) primary key, $columns);");
    
    my $counter;
    my $insert = "INSERT INTO $tablename( " . join(',',@cols) . " ) values ( " . join(',', map { '?' } @cols) . ")";
    my $sth = $dbh->prepare($insert);
    while (<INPUT>) {
        chomp;
        my @data = split(/,/);
        $sth->execute( @data );
        $counter++;
        print "." unless $counter % 40;
    }
    $sth->finish;
    $dbh->disconnect;
    print "done.\n$counter points imported into sample data set.\n\n";

}
