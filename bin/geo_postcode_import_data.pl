#!/usr/bin/perl
use strict;
use warnings;

use File::Find::Rule;
use Geo::Coordinates::OSGB qw(grid2ll set_ellipsoid);
use Geo::HelmertTransform;
use IO::File;
use List::Util qw(min max);
use Text::CSV_XS;
use DBI;
$|++;

set_ellipsoid( 6378137.0, 6356752.3141 );    # use WGS84
my $AIRY1830 = Geo::HelmertTransform::datum('Airy1830');
my $WGS84    = Geo::HelmertTransform::datum('WGS84');

my $csv = Text::CSV_XS->new();

# Configs
my $data_root = $ARGV[1] || $ARGV[0];
my $db_file = $ARGV[1]
    ? $ARGV[0] || 'full_postcode_data.db';
my $tablename = 'postcodes';

my $test_csv = "$data_root/Data/ab.csv";
die "Unable to find: $test_csv" unless -e $test_csv;

if ( -e $db_file ) {
    warn "You already have: $db_file - exiting";
    exit;
}

my $dbh = DBI->connect( "dbi:SQLite:dbname=$db_file", "", "" );
die "SQLite connection failed\n" unless $dbh;

{

    # Create the table
    my $columns = join( ", ",
        map {"$_ varchar(255)"} qw(fixed_format gride gridn latitude longitude) );
    $dbh->do(
        "create table $tablename (postcode varchar(12) primary key, $columns);"
    );
}

my $sth
    = $dbh->prepare(
    "INSERT INTO postcodes (postcode, fixed_format, gride, gridn, latitude, longitude) VALUES (?, ?, ?, ?, ?)"
    );

my $count = 0;
foreach my $filename ( File::Find::Rule->new->file->name('*.csv')->in("$data_root/Data/") )
{
    my $fh = IO::File->new($filename) || die $!;
    my (@columns,    $postcode,     $osgb1936_x,
        $osgb1936_y, $country_code, $fixed_format
    );

    while ( my $line = <$fh> ) {
        $csv->parse($line);
        @columns = $csv->fields();
        ( $postcode, $osgb1936_x, $osgb1936_y, $country_code )
            = ( $columns[0], $columns[10], $columns[11], $columns[12] );
        $count++;
        $postcode = uc $postcode;

        # following commented out line is more flexible. CSV will probably
        # only need other one
        #if ( $postcode =~ m{^([A-Z]+)(\d{1,2}|\d[A-Z])\s*(\d)([A-Z]{2})$} ) {

        if ($postcode =~ m{^([A-Z]{1,2})(\d{1,2}|\d[A-Z])\s?(\d)([A-Z]{2})$} )
        {
            $fixed_format = sprintf( "%-4s %d%2s", $1 . $2, $3, $4 );
        } else {
            die "Can't format postcode '" . $postcode . "'\n";
        }

        $postcode =~ s/ +//g;

        my ( $latitude, $longitude );

        # only get lat/long for postcodes with a grid reference
        if ( $osgb1936_x && $osgb1936_y ) {

            # convert UK National Grid coordinates to latitude, longitude
            ( $latitude, $longitude ) = grid2ll( $osgb1936_x, $osgb1936_y );
            ( $latitude, $longitude )
                = Geo::HelmertTransform::convert_datum( $AIRY1830, $WGS84,
                $latitude, $longitude, 0 );
        }

        $sth->execute( $postcode, $osgb1936_x, $osgb1936_y, $latitude,
            $longitude );
    }
}

__END__

=head1 NAME

impot_full_uk_data.pl - Import Codepoint data

=head1 SYNOPSIS

  % impot_full_uk_data.pl [outdatabase.db] /path/to/Code-Point Open
  
=head1 DESCRIPTION

This program imports Codepoint data - postcode data which links
postscodes to National Grid locations.

The directory 'Code-Point Open' should be the unzipped codepo_gb.zip
which you can request from https://www.ordnancesurvey.co.uk/opendatadownload/products.html

This should have the directory structure...

//Data/ab.csv
./Data/al.csv
...
./Data/yo.csv
./Data/ze.csv
./Doc/Code-Point_Open_column_headers.csv
./Doc/Codelist.txt
./Doc/licence.txt
./Doc/metadata.txt









