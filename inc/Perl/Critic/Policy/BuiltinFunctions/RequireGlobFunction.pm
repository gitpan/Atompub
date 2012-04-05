#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/BuiltinFunctions/RequireGlobFunction.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::BuiltinFunctions::RequireGlobFunction;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $GLOB_RX => qr< [*?] >xms;
Readonly::Scalar my $DESC    => q{Glob written as <...>};
Readonly::Scalar my $EXPL    => [ 167 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                                }
sub default_severity     { return $SEVERITY_HIGHEST                 }
sub default_themes       { return qw( core pbp bugs )               }
sub applies_to           { return 'PPI::Token::QuoteLike::Readline' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $elem =~ $GLOB_RX ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

#line 91

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
