#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ValuesAndExpressions/ProhibitLeadingZeros.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitLeadingZeros;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :characters :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $LEADING_RX => qr<\A [+-]? (?: 0+ _* )+ [1-9]>xms;
Readonly::Scalar my $EXPL       => [ 58 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name           => 'strict',
            description    =>
                q<Don't allow any leading zeros at all.  Otherwise builtins that deal with Unix permissions, e.g. chmod, don't get flagged.>,
            default_string => '0',
            behavior       => 'boolean',
        },
    );
}

sub default_severity     { return $SEVERITY_HIGHEST           }
sub default_themes       { return qw< core pbp bugs >         }
sub applies_to           { return 'PPI::Token::Number::Octal' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem !~ $LEADING_RX;
    return $self->_create_violation($elem) if $self->{_strict};
    return if $self->_is_first_argument_of_chmod_or_umask($elem);
    return if $self->_is_second_argument_of_mkdir($elem);
    return if $self->_is_third_argument_of_dbmopen($elem);
    return if $self->_is_fourth_argument_of_sysopen($elem);
    return $self->_create_violation($elem);
}

sub _create_violation {
    my ($self, $elem) = @_;

    return $self->violation(
        qq<Integer with leading zeros: "$elem">,
        $EXPL,
        $elem
    );
}

sub _is_first_argument_of_chmod_or_umask {
    my ($self, $elem) = @_;

    my $previous_token = _previous_token_that_isnt_a_parenthesis($elem);
    return if not $previous_token;

    my $content = $previous_token->content();
    return $content eq 'chmod' || $content eq 'umask';
}

sub _is_second_argument_of_mkdir {
    my ($self, $elem) = @_;

    # Preceding comma.
    my $previous_token = _previous_token_that_isnt_a_parenthesis($elem);
    return if not $previous_token;
    return if $previous_token->content() ne $COMMA;  # Don't know what it is.

    # Directory name.
    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;

    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;

    return $previous_token->content() eq 'mkdir';
}

sub _is_third_argument_of_dbmopen {
    my ($self, $elem) = @_;

    # Preceding comma.
    my $previous_token = _previous_token_that_isnt_a_parenthesis($elem);
    return if not $previous_token;
    return if $previous_token->content() ne $COMMA;  # Don't know what it is.

    # File path.
    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;

    # Another comma.
    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;
    return if $previous_token->content() ne $COMMA;  # Don't know what it is.

    # Variable name.
    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;

    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;

    return $previous_token->content() eq 'dbmopen';
}

sub _is_fourth_argument_of_sysopen {
    my ($self, $elem) = @_;

    # Preceding comma.
    my $previous_token = _previous_token_that_isnt_a_parenthesis($elem);
    return if not $previous_token;
    return if $previous_token->content() ne $COMMA;  # Don't know what it is.

    # Mode.
    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    while ($previous_token and $previous_token->content() ne $COMMA) {
        $previous_token =
            _previous_token_that_isnt_a_parenthesis($previous_token);
    }
    return if not $previous_token;
    return if $previous_token->content() ne $COMMA;  # Don't know what it is.

    # File name.
    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;

    # Yet another comma.
    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;
    return if $previous_token->content() ne $COMMA;  # Don't know what it is.

    # File handle.
    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;

    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;

    return $previous_token->content() eq 'sysopen';
}

sub _previous_token_that_isnt_a_parenthesis {
    my ($elem) = @_;

    my $previous_token = $elem->previous_token();
    while (
            $previous_token
        and (
                not $previous_token->significant()
            or  $previous_token->content() eq $LEFT_PAREN
            or  $previous_token->content() eq $RIGHT_PAREN
        )
    ) {
        $previous_token = $previous_token->previous_token();
    }

    return $previous_token;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 242

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
