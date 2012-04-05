#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/InputOutput/ProhibitExplicitStdin.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::InputOutput::ProhibitExplicitStdin;

use 5.006001;
use strict;
use warnings;
use Readonly;
use List::MoreUtils qw(any);

use Perl::Critic::Utils qw{ :severities :classification &parse_arg_list };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Use "<>" or "<ARGV>" or a prompting module instead of "<STDIN>"};
Readonly::Scalar my $EXPL => [216,220,221];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                                }
sub default_severity     { return $SEVERITY_HIGH                    }
sub default_themes       { return qw( core pbp maintenance )        }
sub applies_to           { return 'PPI::Token::QuoteLike::Readline' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem ne '<STDIN>';
    return $self->violation( $DESC, $EXPL, $elem );
}


1;

__END__

#-----------------------------------------------------------------------------

#line 120

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
