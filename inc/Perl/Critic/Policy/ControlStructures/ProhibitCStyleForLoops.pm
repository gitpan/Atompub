#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ControlStructures/ProhibitCStyleForLoops.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ControlStructures::ProhibitCStyleForLoops;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :characters :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{C-style "for" loop used};
Readonly::Scalar my $EXPL => [ 100 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_LOW              }
sub default_themes       { return qw( core pbp maintenance ) }
sub applies_to           { return 'PPI::Structure::For'  }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( _is_cstyle($elem) ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

sub _is_cstyle {
    my $elem      = shift;
    my $nodes_ref = $elem->find('PPI::Token::Structure');
    return if !$nodes_ref;
    my @semis     = grep { $_ eq $SCOLON } @{$nodes_ref};
    return scalar @semis == 2;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 101

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
