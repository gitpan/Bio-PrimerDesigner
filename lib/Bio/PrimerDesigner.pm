# $Id: PrimerDesigner.pm,v 1.12 2003/08/05 23:03:03 kclark Exp $

package Bio::PrimerDesigner;

=head1 NAME 

Bio::PrimerDesigner - Design PCR Primers using primer3 and epcr

=head1 SYNOPSIS

  use Bio::PrimerDesigner;

  my $pd = Bio::PrimerDesigner->new;

  #
  # Define the DNA sequence, etc.
  #
  my $dna   = "CGTGC...TTCGC";
  my $seqID = "sequence 1";

  #
  # Define design parameters (native primer3 syntax)
  #
  my %params = ( 
      PRIMER_NUM_RETURN   => 2,
      PRIMER_SEQUENCE_ID  => $seqID,
      SEQUENCE            => $dna,
      PRIMER_PRODUCT_SIZE => '500-600'
  );

  #
  # Or use input aliases
  #
  %param = ( 
      num                 => 2,
      id                  => $seqID,
      seq                 => $dna,
      sizerange           => '500-600'
  ); 

  #
  # Design primers
  #
  my $results = $pd->design( %params ) or die $pd->error;

  #
  # Make sure the design was successful
  #
  die( "No primers found\n", $results->raw_data )
      unless $results->left;

  #
  # Get results (single primer set)
  #
  my $left_primer  = $results->left;
  my $right_primer = $results->right;
  my $left_tm      = $results->lefttm;

  #
  # Get results (multiple primer sets)
  #
  my @left_primers  = $results->left(1..3);
  my @right_primers = $results->right(1..3);
  my @left_tms      = $results->lefttm(1..3);

=head1 DESCRIPTION

Bio::PrimerDesigner provides a low-level interface to the primer3 and
epcr binary executables and supplies methods to return the results.
Because primer3 and e-PCR are only available for Unix-like operating
systems, Bio::PrimerDesigner offers the ability to accessing the
primer3 binary via a remote server.  Local installations of primer3 or
e-PCR on Unix hosts are also supported.

=head1 METHODS

=cut

use strict;
use Bio::PrimerDesigner::primer3;
use Bio::PrimerDesigner::epcr;
use Class::Base;
use base 'Class::Base';

use vars '$VERSION';
$VERSION = '0.01';

#
# deal with e-PCR syntax
#
*run = *design;

#
# Default options
#
use constant DEFAULT  => {
    method            => 'local',
    url               => 'aceserver.biotech.ubc.ca/cgi-bin/primer_designer.cgi',
    binary_path       => '/usr/local/bin',
    program           => 'primer3',
};

#
# Define the adapter modules
#
use constant DESIGNER => {
    primer3           => 'Bio::PrimerDesigner::primer3',
    epcr              => 'Bio::PrimerDesigner::epcr', 
};

# -------------------------------------------------------------------
sub init {
    my ( $self, $config ) = @_;
    for my $param ( qw[ program method url binary_path ] ) {
        $self->$param( $config->{ $param } ) or return;
    }
    
    my $loc = $self->method eq 'local' ? 'path' : 'url';
    $self->{$loc} = $config->{'path'} || $config->{'url'} || '';
    return $self;
}

# -------------------------------------------------------------------
sub binary_path {

=pod

=head2 binary_path

Gets/sets path to the primer3 binary.

=cut

    my $self = shift;
    
    if ( my $path = shift ) {
        if ( -e $path ) {
            $self->{'binary_path'} = $path;
        }
        else {
            $self->error(
                "Can't find path to " . $self->{'program'}->binary_name .
	            ":\nPath '$path' does not exist"
            );
            return '';
        }
    }
    
    return $self->{'binary_path'} || DEFAULT->{'binary_path'};
}

# -------------------------------------------------------------------
sub program {

=pod

=head2 program

Gets/sets which program to use.

=cut

    my $self    = shift;
    my $program = shift || '';
    my $reset   = 0; 

    if ( $program ) {
        return $self->error("Invalid argument for program: '$program'")
            unless DESIGNER->{ $program };
        $reset = 1;
    }

    if ( $reset || !defined $self->{'program'} ) {
        $program ||= DEFAULT->{'program'};
        my $class  = DESIGNER->{ $program };
        $self->{'program'} = $class->new 
	  or return $self->error( $class->error );
    }

    return $self->{'program'};
}

# -------------------------------------------------------------------
sub list_aliases {

=pod

=head2 list_aliases

Lists aliases for primer3 input/output options

=cut

    my $self = shift;
    my $designer = $self->program or return $self->error;
    return $designer->list_aliases;
}

# -------------------------------------------------------------------
sub list_params {

=pod

=head2 list_params

Lists input options for primer3 or epcr, depending on the context

=cut

    my $self = shift;
    my $designer = $self->program or return $self->error;
    return $designer->list_params;
}

# -------------------------------------------------------------------
sub method {

=pod

=head2 method

Gets/sets method of accessing primer3 or epcr binaries.

=cut

    my $self = shift;

    if ( my $arg = lc shift ) {
        return $self->error("Invalid argument for method: '$arg'")
            unless $arg eq 'local' || $arg eq 'remote';
        $self->{'method'} = $arg;
    }

    return $self->{'method'} || DEFAULT->{'method'};
}

# -------------------------------------------------------------------
sub url {

=pod

=head2 url

Gets/sets the URL for accessing the remote binaries.

=cut

    my $self = shift;
    my $url  = shift;

    if ( defined $url && $url eq '' ) {
        $self->{'url'} = '';
    }
    elsif ( $url ) {
        $url = 'http://' . $url unless $url =~ m{https?://};
        $self->{'url'} = $url;
    }

    return $self->{'url'} || DEFAULT->{'url'};
}

# -------------------------------------------------------------------
sub design {

=pod

=head2 design

Makes the primer design or e-PCR request.  Returns an
Bio::PrimerDesigner::Result object.

=cut

    my $self     = shift;
    my %params   = @_ or $self->error("no design parameters");
    my $designer = $self->{'program'};
    my $method   = $self->method;
    my $loc      = $method eq 'local' ? $self->binary_path : $self->url;
    my $function = $designer =~ /primer3/ ? 'design' : 'run';
    
    my $result   = $designer->$function( $method, $loc, \%params )
                   or return $self->error( $designer->error );
    
    return $result;
}

# -------------------------------------------------------------------
sub verify {                     
                     
=head2 verify

Tests local installations of primer3 or e-PCR to ensure that they are
working properly.

=cut

    my $self     = shift;
    my $designer = $self->{'program'};
    my $method   = $self->method;                     
    my $loc      = $method eq 'local' ? $self->binary_path : $self->url; 
    return $designer->verify( $method, $loc ) || 
        $self->error( $designer->error );
}

# -------------------------------------------------------------------
sub epcr_example {

=head2 epcr_example

Run test e-PCR job.  Returns an Bio::PrimerDesigner::Results object.

=cut

    my $self = shift;
    my $epcr = Bio::PrimerDesigner::epcr->new;
    return $epcr->verify( 
        'remote',
        'http://aceserver.biotech.ubc.ca/cgi-bin/primer_designer.cgi',
    ) || $self->error( $epcr->error );
}

# -------------------------------------------------------------------
sub primer3_example {

=head2 primer3_example

Runs a sample design job for primers.  Returns an
Bio::PrimerDesigner::Results object.

=cut

    my $self = shift;
    my $pcr  = Bio::PrimerDesigner::primer3->new;
    return $pcr->example || $self->error( $pcr->error );
}

1;

# -------------------------------------------------------------------

=pod

=head1 AUTHORS

Copyright (C) 2003 Sheldon McKay E<lt>smckay@bcgsc.bc.caE<gt>,
                   Ken Y. Clark E<lt>kclark@cpan.orgE<gt>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA.

=head1 SEE ALSO

Bio::PrimerDesigner::primer3, Bio::PrimerDesigner::epcr.

=cut
