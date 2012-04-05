#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/RegularExpressions/ProhibitComplexRegexes.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::RegularExpressions::ProhibitComplexRegexes;

use 5.006001;
use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);
use List::Util qw{ min };
use Readonly;

use Perl::Critic::Utils qw{ :booleans :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Split long regexps into smaller qr// chunks};
Readonly::Scalar my $EXPL => [261];

Readonly::Scalar my $MAX_LITERAL_LENGTH => 7;
Readonly::Scalar my $MAX_VARIABLE_LENGTH => 4;

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'max_characters',
            description     =>
                'The maximum number of characters to allow in a regular expression.',
            default_string  => '60',
            behavior        => 'integer',
            integer_minimum => 1,
        },
    );
}

sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core pbp maintenance ) }
sub applies_to           { return qw(PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute
                                     PPI::Token::QuoteLike::Regexp) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $document ) = @_;

    # Optimization: if its short enough now, parsing won't make it longer
    return if $self->{_max_characters} >= length $elem->get_match_string();

    my $re = $document->ppix_regexp_from_element( $elem )
        or return;  # Abort on syntax error.
    $re->failures()
        and return; # Abort if parse errors found.
    my $qr = $re->regular_expression()
        or return;  # Abort if no regular expression.

    my $length = 0;
    # We use map { $_->tokens() } qr->children() rather than just
    # $qr->tokens() because we are not interested in the delimiters.
    foreach my $token ( map { $_->tokens() } $qr->children() ) {

        # Do not count whitespace or comments
        $token->significant() or next;

        if ( $token->isa( 'PPIx::Regexp::Token::Interpolation' ) ) {

            # Do not penalize long variable names
            $length += min( $MAX_VARIABLE_LENGTH, length $token->content() );

        } elsif ( $token->isa( 'PPIx::Regexp::Token::Literal' ) ) {

            # Do not penalize long literals like \p{...}
            $length += min( $MAX_LITERAL_LENGTH, length $token->content() );

        } else {

            # Take everything else at face value
            $length += length $token->content();

        }

    }

    return if $self->{_max_characters} >= $length;

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

#line 219

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
