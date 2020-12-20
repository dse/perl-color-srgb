#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Color::sRGB' ) || print "Bail out!\n";
}

diag( "Testing Color::sRGB $Color::sRGB::VERSION, Perl $], $^X" );
