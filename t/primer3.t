#!/usr/bin/perl

# $Id: primer3.t,v 1.4 2003/08/05 22:43:22 kclark Exp $

#
# Tests specific to "primer3" program.
#

use strict;
use Test::More tests => 7;

use_ok( 'Bio::PrimerDesigner' );

my $pd = Bio::PrimerDesigner->new;
isa_ok( $pd, 'Bio::PrimerDesigner' );

my $prog = $pd->program('primer3');
isa_ok( $prog, 'Bio::PrimerDesigner::primer3', 'program' );

is( $prog->binary_name, 'primer3', 'binary_name is "primer3"' );

ok( $prog->list_params, 'program returns params' );

ok( $prog->list_aliases, 'program returns aliases' );

ok( !$prog->design, 'design method fails without arguments' ); 
