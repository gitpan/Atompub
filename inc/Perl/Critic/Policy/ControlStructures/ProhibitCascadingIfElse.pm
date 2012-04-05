#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ControlStructures/ProhibitCascadingIfElse.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ControlStructures::ProhibitCascadingIfElse;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Cascading if-elsif chain};
Readonly::Scalar my $EXPL => [ 117, 118 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'max_elsif',
            description     => 'The maximum number of alternatives that will be allowed.',
            default_string  => '2',
            behavior        => 'integer',
            integer_minimum => 1,
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM                      }
sub default_themes   { return qw( core pbp maintenance complexity ) }
sub applies_to       { return 'PPI::Statement::Compound'            }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if ($elem->type() ne 'if');

    if ( _count_elsifs($elem) > $self->{_max_elsif} ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

sub _count_elsifs {
    my $elem = shift;
    return
      grep { $_->isa('PPI::Token::Word') && $_ eq 'elsif' } $elem->schildren();
}

1;

__END__

#-----------------------------------------------------------------------------

#line 127

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
