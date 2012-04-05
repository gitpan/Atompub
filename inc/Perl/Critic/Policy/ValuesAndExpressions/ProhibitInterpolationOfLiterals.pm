#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ValuesAndExpressions/ProhibitInterpolationOfLiterals.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals;

use 5.006001;
use strict;
use warnings;
use Readonly;

use List::MoreUtils qw(any);

use Perl::Critic::Utils qw{ :characters :severities :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Useless interpolation of literal string};
Readonly::Scalar my $EXPL => [51];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name               => 'allow',
            description        =>
                'Kinds of delimiters to permit, e.g. "qq{", "qq(", "qq[", "qq/".',
            default_string     => $EMPTY,
            parser             => \&_parse_allow,
        },
        {
            name               => 'allow_if_string_contains_single_quote',
            description        =>
                q<If the string contains ' characters, allow "" to quote it.>,
            default_string     => '0',
            behavior           => 'boolean',
        },
    );
}

sub default_severity { return $SEVERITY_LOWEST        }
sub default_themes   { return qw( core pbp cosmetic ) }
sub applies_to       { return qw(PPI::Token::Quote::Double
                                 PPI::Token::Quote::Interpolate) }

#-----------------------------------------------------------------------------

Readonly::Scalar my $MAX_SPECIFICATION_LENGTH => 3;

sub _parse_allow {
    my ($self, $parameter, $config_string) = @_;

    my @allow;

    if (defined $config_string) {
        @allow = words_from_string( $config_string );
        #Try to be forgiving with the configuration...
        for (@allow) {
            m{ \A qq }xms || ($_ = 'qq' . $_)
        }  #Add 'qq'
        for (@allow) {
            (length $_ <= $MAX_SPECIFICATION_LENGTH) || chop
        }    #Chop closing char
    }

    $self->{_allow} = \@allow;

    return;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # Skip if this string needs interpolation
    return if _has_interpolation($elem);

    # Overlook allowed quote styles
    return if any { $elem =~ m{ \A \Q$_\E }xms } @{ $self->{_allow} };

    # If the flag is set, allow "I'm here".
    if ( $self->{_allow_if_string_contains_single_quote} ) {
        return if index ($elem, $QUOTE) >= 0;
    }

    # Must be a violation
    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

sub _has_interpolation {
    my $elem = shift;
    return $elem =~ m<
        (?: \A | [^\\] )
        (?: \\{2} )*
        (?: [\$\@] \S+ | \\[tnrfbae0xcNLuLUEQ] )
    >xmso;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 195

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
