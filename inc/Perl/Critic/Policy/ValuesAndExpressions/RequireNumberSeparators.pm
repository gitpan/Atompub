#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ValuesAndExpressions/RequireNumberSeparators.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::RequireNumberSeparators;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Long number not separated with underscores};
Readonly::Scalar my $EXPL => [ 59 ];

#-----------------------------------------------------------------------------

Readonly::Scalar my $MINIMUM_INTEGER_WITH_MULTIPLE_DIGITS => 10;

sub supported_parameters {
    return (
        {
            name            => 'min_value',
            description     => 'The minimum absolute value to require separators in.',
            default_string  => '10_000',
            behavior        => 'integer',
            integer_minimum => $MINIMUM_INTEGER_WITH_MULTIPLE_DIGITS,
        },
    );
}

sub default_severity  { return $SEVERITY_LOW           }
sub default_themes    { return qw( core pbp cosmetic ) }
sub applies_to        { return 'PPI::Token::Number'    }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    my $min = $self->{_min_value};

    return if $elem !~ m{ \d{4} }xms;
    return if abs $elem->literal() < $min;

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

#line 117

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
