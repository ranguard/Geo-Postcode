#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use lib qw( ./lib );
use ExtUtils::MakeMaker;
$|++;

WriteMakefile(
    NAME => 'Geo::Postcode',
    VERSION_FROM => 'lib/Geo/Postcode.pm',
    PREREQ_PM => { 'DBD::SQLite' => 0 }, (
        $] >= 5.005 ? (
            ABSTRACT_FROM => 'lib/Geo/Postcode.pm', 
            AUTHOR => 'william ross <wross@cpan.org>'
        ) : ()
    ),
    clean => { 
        FILES => './blib/lib/Geo/Postcode/postcodes.db' 
    },
);

package MY;

sub postamble {
      return <<"EOF";
locationdata:
\tperl ./postcodedata/makesqlite.pl

EOF
}

sub test {
    my $class = shift;
    my $makefragment = $class->SUPER::test(@_);
    $makefragment =~ s/^(test ::)/$1 locationdata/m;
    return $makefragment;
}

sub install {
    my $class = shift;
    my $makefragment = $class->SUPER::install(@_);
    $makefragment =~ s/^(install ::)/$1 locationdata/m;
    return $makefragment;
}


