#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Utils/POD/ParseInteriorSequence.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Utils::POD::ParseInteriorSequence;

use 5.006001;
use strict;
use warnings;

use base qw{ Pod::Parser };

use IO::String;

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

sub interior_sequence {
    my ( $self, $seq_cmd, $seq_arg, $pod_seq ) = @_;
    push @{ $self->{+__PACKAGE__}{interior_sequence} ||= [] }, $pod_seq;
    return $self->SUPER::interior_sequence( $seq_cmd, $seq_arg, $pod_seq );
}

#-----------------------------------------------------------------------------

sub get_interior_sequences {
    my ( $self, $pod ) = @_;
    $self->{+__PACKAGE__}{interior_sequence} = [];
    my $result;
    $self->parse_from_filehandle(
        IO::String->new( \$pod ),
        IO::String->new( \$result )
    );
    return @{ $self->{+__PACKAGE__}{interior_sequence} };
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

#line 110

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
