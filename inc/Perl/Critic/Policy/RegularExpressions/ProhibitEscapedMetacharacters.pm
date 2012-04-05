#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/RegularExpressions/ProhibitEscapedMetacharacters.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::RegularExpressions::ProhibitEscapedMetacharacters;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);
use List::MoreUtils qw(any);
use Readonly;

use Perl::Critic::Utils qw{ :booleans :severities hashify };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Use character classes for literal metachars instead of escapes};
Readonly::Scalar my $EXPL => [247];

Readonly::Hash my %REGEXP_METACHARS => hashify(split / /xms, '{ } ( ) . * + ? |');

#-----------------------------------------------------------------------------

sub supported_parameters { return qw()                    }
sub default_severity     { return $SEVERITY_LOWEST        }
sub default_themes       { return qw( core pbp cosmetic ) }
sub applies_to           { return qw(PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute
                                     PPI::Token::QuoteLike::Regexp) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $document ) = @_;

    # optimization: don't bother parsing the regexp if there are no escapes
    return if $elem !~ m/\\/xms;

    my $re = $document->ppix_regexp_from_element( $elem ) or return;
    $re->failures() and return;
    my $qr = $re->regular_expression() or return;

    my $exacts = $qr->find( 'PPIx::Regexp::Token::Literal' ) or return;
    foreach my $exact( @{ $exacts } ) {
        $exact->content() =~ m/ \\ ( . ) /xms or next;
        return $self->violation( $DESC, $EXPL, $elem ) if $REGEXP_METACHARS{$1};
    }

    return; # OK
}

1;

__END__

#-----------------------------------------------------------------------------

#line 168

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
