#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use DBI;
$|++;

my $datafile = './blib/lib/Geo/Postcode/postcodes.db';
my $csvdata = './postcodedata/postcodes.csv';
my $tablename = 'postcodes';

if (-e $datafile) {
    print "datafile present.\n";

} else {
    open( INPUT, $csvdata) || die("can\'t open file $csvdata: $!");
    my $dbh = DBI->connect("dbi:SQLite:dbname=$datafile","","");
    
    my @cols = split(",",<INPUT>);
    my $columns = join(", ", map { "$_ varchar(255)" } grep { $_ ne "postcode" } @cols);
    $dbh->do("create table $tablename (postcode varchar(12) primary key, $columns);");
    
    my $counter;
    my $insert = "INSERT INTO $tablename( " . join(",",@cols) . " ) values ( " . join(",", map { "?" } @cols) . ")";
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