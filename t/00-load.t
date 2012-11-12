#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'SFC::Room' ) || print "Bail out!\n";
}

diag( "Testing SFC::Room $SFC::Room::VERSION, Perl $], $^X" );
