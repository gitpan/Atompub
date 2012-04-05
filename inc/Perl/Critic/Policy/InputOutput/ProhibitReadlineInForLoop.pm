#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/InputOutput/ProhibitReadlineInForLoop.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::InputOutput::ProhibitReadlineInForLoop;

use 5.006001;
use strict;
use warnings;
use Readonly;

use List::Util qw< first >;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Readline inside "for" loop};
Readonly::Scalar my $EXPL => [ 211 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                             }
sub default_severity     { return $SEVERITY_HIGH                 }
sub default_themes       { return qw< core bugs pbp >            }
sub applies_to           { return qw< PPI::Statement::Compound > }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem->type() ne 'foreach';

    my $list = first { $_->isa('PPI::Structure::List') } $elem->schildren()
        or return;

    if (
        my $readline = $list->find_first('PPI::Token::QuoteLike::Readline')
    ) {
        return $self->violation( $DESC, $EXPL, $readline );
    }

    return;  #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

#line 100

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
