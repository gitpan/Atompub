#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ValuesAndExpressions/RequireInterpolationOfMetachars.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Email::Address;

use Perl::Critic::Utils qw< :booleans :characters :severities >;
use base 'Perl::Critic::Policy';

#-----------------------------------------------------------------------------

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q<String *may* require interpolation>;
Readonly::Scalar my $EXPL => [ 51 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'rcs_keywords',
            description     => 'RCS keywords to ignore in potential interpolation.',
            default_string  => $EMPTY,
            behavior        => 'string list',
        },
    );
}

sub default_severity     { return $SEVERITY_LOWEST      }
sub default_themes       { return qw(core pbp cosmetic) }

sub applies_to           {
    return qw< PPI::Token::Quote::Single PPI::Token::Quote::Literal >;
}

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    my $rcs_keywords = $self->{_rcs_keywords};
    my @rcs_keywords = keys %{$rcs_keywords};

    if (@rcs_keywords) {
        my $rcs_regexes = [ map { qr/ \$ $_ [^\n\$]* \$ /xms } @rcs_keywords ];
        $self->{_rcs_regexes} = $rcs_regexes;
    }

    return $TRUE;
}

sub violates {
    my ( $self, $elem, undef ) = @_;

    # The string() method strips off the quotes
    my $string = $elem->string();
    return if not _needs_interpolation($string);
    return if _looks_like_email_address($string);
    return if _looks_like_use_vars($elem);

    my $rcs_regexes = $self->{_rcs_regexes};
    return if $rcs_regexes and _contains_rcs_variable($string, $rcs_regexes);

    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

sub _needs_interpolation {
    my ($string) = @_;

    return
            # Contains a $ or @ not followed by "{}".
            $string =~ m< [\$\@] (?! [{] [}] ) \S+ >xms
            # Contains metachars
            # Note that \1 ... are not documented (that I can find), but are
            # treated the same way as \0 by S_scan_const in toke.c, at least
            # for regular double-quotish strings. Not, obviously, where
            # regexes are involved.
        ||  $string =~ m<
                (?: \A | [^\\] )
                (?: \\{2} )*
                \\ [tnrfbae01234567xcNluLUEQ]
            >xms;
}

#-----------------------------------------------------------------------------

sub _looks_like_email_address {
    my ($string) = @_;

    return if index ($string, q<@>) < 0;
    return if $string =~ m< \W \@ >xms;
    return if $string =~ m< \A \@ \w+ \b >xms;

    return $string =~ $Email::Address::addr_spec;
}

#-----------------------------------------------------------------------------

sub _contains_rcs_variable {
    my ($string, $rcs_regexes) = @_;

    foreach my $regex ( @{$rcs_regexes} ) {
        return $TRUE if $string =~ m/$regex/xms;
    }

    return;
}

#-----------------------------------------------------------------------------

sub _looks_like_use_vars {
    my ($elem) = @_;

    my $statement = $elem;
    while ( not $statement->isa('PPI::Statement::Include') ) {
        $statement = $statement->parent() or return;
    }

    return if $statement->type() ne q<use>;
    return $statement->module() eq q<vars>;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 234

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
