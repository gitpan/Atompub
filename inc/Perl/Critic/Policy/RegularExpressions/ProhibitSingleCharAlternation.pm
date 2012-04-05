#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/RegularExpressions/ProhibitSingleCharAlternation.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::RegularExpressions::ProhibitSingleCharAlternation;

use 5.006001;
use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);
use List::MoreUtils qw(all);
use Readonly;

use Perl::Critic::Utils qw{ :booleans :characters :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => [265];

#-----------------------------------------------------------------------------

sub supported_parameters { return qw()                    }
sub default_severity     { return $SEVERITY_LOWEST        }
sub default_themes       { return qw( core pbp performance ) }
sub applies_to           { return qw(PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute
                                     PPI::Token::QuoteLike::Regexp) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $document ) = @_;

    # optimization: don't bother parsing the regexp if there are no pipes
    return if $elem !~ m/[|]/xms;

    my $re = $document->ppix_regexp_from_element( $elem ) or return;
    $re->failures() and return;

    my @violations;
    foreach my $node ( @{ $re->find_parents( sub {
                return $_[1]->isa( 'PPIx::Regexp::Token::Operator' )
                && $_[1]->content() eq q<|>;
            } ) || [] } ) {

        my @singles;
        my @alternative;
        foreach my $kid ( $node->children() ) {
            if ( $kid->isa( 'PPIx::Regexp::Token::Operator' )
                && $kid->content() eq q<|>
            ) {
                @alternative == 1
                    and $alternative[0]->isa( 'PPIx::Regexp::Token::Literal' )
                    and push @singles, map { $_->content() } @alternative;
                @alternative = ();
            } elsif ( $kid->significant() ) {
                push @alternative, $kid;
            }
        }
        @alternative == 1
            and $alternative[0]->isa( 'PPIx::Regexp::Token::Literal' )
            and push @singles, map { $_->content() } @alternative;

        if ( 1 < @singles ) {
            my $description =
                  'Use ['
                . join( $EMPTY, @singles )
                . '] instead of '
                . join q<|>, @singles;
            push @violations, $self->violation( $description, $EXPL, $elem );
        }
    }

    return @violations;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 142

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
