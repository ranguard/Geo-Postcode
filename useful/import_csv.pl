#!/usr/bin/perl

use strict;
use DBI;
use Text::CSV;
use Getopt::Long;
use Data::Dumper;

$|++;

my $input = './postcodes.csv';
my $output = './postcodes.db';
my $tablename = 'postcodes';

my $result = GetOptions ( 
    i => \$input,
    o => \$output,
    table => \$tablename,
);

die "No such input file" unless $input && -e $input && -f $input;
die "Output file exists" if -e $output;

my $csv = Text::CSV->new;
my $dbh = DBI->connect("dbi:SQLite:dbname=$output","","") || die("can't open SQLite file: $!");
open( INPUT, $input) || die("can't open input file: $!");

my $firstline = <INPUT>;
$csv->parse($firstline);
my @cols = $csv->fields;
my $columns = join(', ', map { "$_ varchar(255)" } grep { $_ ne 'postcode' } @cols);

print "* creating '$tablename' table. \$columns is:\n $columns\n\n";

$dbh->do("create table $tablename (postcode varchar(12) primary key, $columns);");

my $statement = "INSERT INTO $tablename( " . join(',',@cols) . " ) values ( " . join(',', map { '?' } @cols) . ")";
my $sth = $dbh->prepare($statement);

print "* populating table. row statement is $statement\n\n";

my $counter;

while (<INPUT>) {
    $csv->parse($_);
    $sth->execute( $csv->fields );
    print '.';
    $counter++;
}

print "\n\n* done. $counter postcodes stored in $output.\n\n";

$sth->finish;
$dbh->disconnect;
