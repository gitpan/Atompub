#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/CodeLayout/ProhibitTrailingWhitespace.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::CodeLayout::ProhibitTrailingWhitespace;

use 5.006001;
use strict;
use warnings;
use English qw(-no_match_vars);
use Readonly;

use charnames qw{};

use PPI::Token::Whitespace;
use Perl::Critic::Utils qw{ :characters :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => q{Don't use whitespace at the end of lines};

## no critic (RequireInterpolationOfMetachars)
Readonly::Hash my %C_STYLE_ESCAPES =>
    (
        ord "\t" => q{\t},
        ord "\n" => q{\n},
        ord "\r" => q{\r},
        ord "\f" => q{\f},
        ord "\b" => q{\b},
        ord "\a" => q{\a},
        ord "\e" => q{\e},
    );
## use critic

#-----------------------------------------------------------------------------

sub supported_parameters { return qw{ }                    }
sub default_severity     { return $SEVERITY_LOWEST         }
sub default_themes       { return qw( core maintenance )   }
sub applies_to           { return 'PPI::Token::Whitespace' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $token, undef ) = @_;

    if ( $token->content() =~ m< ( (?! \n) \s )+ \n >xms ) {
        my $extra_whitespace = $1;

        my $description = q{Found "};
        $description .=
            join
                $EMPTY,
                map { _escape($_) } split $EMPTY, $extra_whitespace;
        $description .= q{" at the end of the line};

        return $self->violation( $description, $EXPL, $token );
    }

    return;
}

sub _escape {
    my $character = shift;
    my $ordinal = ord $character;

    if (my $c_escape = $C_STYLE_ESCAPES{$ordinal}) {
        return $c_escape;
    }


    # Apparently, the charnames.pm that ships with older perls does not
    # support the C<viacode> function, and newer versions of the module are
    # not distributed separately from perl itself So if the C<viacode> method
    # is not supported, then just substitute something.


    ## no critic (RequireInterpolationOfMetachars)
    if ( charnames->can( 'viacode' ) ) {
        return q/\N{/ . charnames::viacode($ordinal) . q/}/;
    }
    else {
        return '\N{WHITESPACE CHAR}';
    }
}

1;

#-----------------------------------------------------------------------------

__END__

#line 141

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
