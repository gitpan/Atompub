#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Documentation/RequirePodAtEnd.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Documentation::RequirePodAtEnd;

use 5.006001;
use strict;
use warnings;
use Readonly;

use List::Util qw(first);

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $POD_RX => qr{\A = (?: for|begin|end ) }xms;
Readonly::Scalar my $DESC => q{POD before __END__};
Readonly::Scalar my $EXPL => [139, 140];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                      }
sub default_severity     { return $SEVERITY_LOWEST        }
sub default_themes       { return qw( core cosmetic pbp ) }
sub applies_to           { return 'PPI::Document'         }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # No POD means no violation
    my $pods_ref = $doc->find('PPI::Token::Pod');
    return if !$pods_ref;

    # Look for first POD tag that isn't =for, =begin, or =end
    my $pod = first { $_ !~ $POD_RX} @{ $pods_ref };
    return if !$pod;

    my $end = $doc->find_first('PPI::Statement::End');
    if ($end) {  # No __END__ means definite violation
        my $pod_loc = $pod->location();
        my $end_loc = $end->location();
        if ( $pod_loc->[0] > $end_loc->[0] ) {
            # POD is after __END__, or relative position couldn't be determined
            return;
        }
    }

    return $self->violation( $DESC, $EXPL, $pod );
}

1;

__END__

#-----------------------------------------------------------------------------

#line 125

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
