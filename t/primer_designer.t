#!/usr/bin/perl

# $Id: primer_designer.t,v 1.4 2003/08/05 22:43:22 kclark Exp $

#
# Tests for "Bio::PrimerDesigner" module.
#

use strict;
use Test::More tests => 25;

use_ok( 'Bio::PrimerDesigner' );

my $pd = Bio::PrimerDesigner->new;
isa_ok( $pd, 'Bio::PrimerDesigner' );

#
# Check defaults.
#
is( $pd->method, 'local', 'Default method is "local"' );

my $def_url = 'aceserver.biotech.ubc.ca/cgi-bin/primer_designer.cgi';
is( $pd->url, $def_url, qq[Default url is "$def_url"] );

my $def_bin = '/usr/local/bin';
is( $pd->binary_path, $def_bin, qq[Default binary path is "$def_bin"] );
isa_ok( $pd->program, 'Bio::PrimerDesigner::primer3' );

#
# Check new with args.
#
my $pd2         =  Bio::PrimerDesigner->new(
    binary_path => '/bin',
    method      => 'remote',
    url         => 'https://www.google.com/',
    program     => 'epcr',
) or die Bio::PrimerDesigner->error;
isa_ok( $pd2, 'Bio::PrimerDesigner', 'object with args' );
is( $pd2->method, 'remote', 'method is "remote"' );
is( $pd2->url, 'https://www.google.com/', 'url is "https://www.google.com/"' );
is( $pd2->binary_path, '/bin', 'binary_path is "/bin"' );
isa_ok( $pd2->program, 'Bio::PrimerDesigner::epcr' );

#
# "method" tests.
#
is( $pd->method('REMOTE'), 'remote', 'method set to "remote"' );
is( $pd->method('foo'), undef, 'method rejects bad arg' );
like( $pd->error, qr/invalid argument for method/i, 'Error message set' );
is( $pd->method, 'remote', 'method remembers last good arg' );

#
# "url" tests.
#
my $url = 'http://www.google.com';
is( $pd->url( 'www.google.com' ), $url, qq[url set to "$url"] );
is( $pd->url( '' ), $def_url, 'url takes empty arg, resets to default' );

#
# "binary_path" tests.
#
is ( $pd->binary_path('/bin'), '/bin', 'binary_path set to "/bin"' );
is ( $pd->binary_path('/foo/bar/baz/quux'), '', 
    'binary_path rejects bad arg' );
like( $pd->error, qr/does not exist/i, 'Error message set' );
is( $pd->binary_path, '/bin', 'binary_path remembers last good arg' );

#
# "program" tests.
#
isa_ok( $pd->program('epcr'), 'Bio::PrimerDesigner::epcr', 'program' );
is( $pd->program('foo'), undef, 'program rejects bad arg' );
like( $pd->error, qr/invalid argument for program/i, 'Error message set' );
isa_ok( $pd->program, 'Bio::PrimerDesigner::epcr', 'program still' );
