# $Id: Makefile.PL,v 1.5 2003/08/05 22:47:38 kclark Exp $

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                 => 'Bio::PrimerDesigner',
    VERSION_FROM         => 'lib/Bio/PrimerDesigner.pm',
    AUTHOR               => 'Sheldon McKay <smckay@bcgsc.bc.ca>',
    ABSTRACT             => 'Design PCR primers using primer3 and epcr',
    PREREQ_PM            => {
        'Test::More'     => 0,
        'Class::Base'    => 0,
        'HTTP::Request'  => 0,
        'HTTP::Response' => 0,
        'LWP::UserAgent' => 0,
    },
    EXE_FILES            => [
        'bin/primer_designer.pl',
    ],
    clean                => {
        FILES            => '$(DISTNAME)-$(VERSION).tar.gz',
    },
);
