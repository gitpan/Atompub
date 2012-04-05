#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/RegularExpressions/ProhibitFixedStringMatches.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::RegularExpressions::ProhibitFixedStringMatches;

use 5.006001;
use strict;
use warnings;
use Readonly;

use English qw(-no_match_vars);
use Carp;

use Perl::Critic::Utils qw{ :booleans :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Use 'eq' or hash instead of fixed-pattern regexps};
Readonly::Scalar my $EXPL => [271,272];

Readonly::Scalar my $RE_METACHAR => qr/[\\#\$()*+.?\@\[\]^{|}]/xms;

#-----------------------------------------------------------------------------

sub supported_parameters { return qw()                       }
sub default_severity     { return $SEVERITY_LOW              }
sub default_themes       { return qw( core pbp performance ) }
sub applies_to           { return qw(PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute
                                     PPI::Token::QuoteLike::Regexp) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $re = $elem->get_match_string();

    # only flag regexps that are anchored front and back
    if ($re =~ m{\A \s*
                 (\\A|\^)  # front anchor == $1
                 (.*?)
                 (\\z|\$)  # end anchor == $2
                 \s* \z}xms) {

        my ($front_anchor, $words, $end_anchor) = ($1, $2, $3);

        # If it's a multiline match, then end-of-line anchors don't represent the whole string
        if ($front_anchor eq q{^} || $end_anchor eq q{$}) {
            my $regexp = $doc->ppix_regexp_from_element( $elem )
                or return;
            return if $regexp->modifier_asserted( 'm' );
        }

        # check for grouping and optional alternation.  Grouping may or may not capture
        if ($words =~ m{\A \s*
                        [(]              # start group
                          (?:[?]:)?      # optional non-capturing indicator
                          \s* (.*?) \s*  # interior of group
                        [)]              # end of group
                        \s* \z}xms) {
            $words = $1;
            $words =~ s/[|]//gxms; # ignore alternation inside of parens -- just look at words
        }

        # Regexps that contain metachars are not fixed strings
        return if $words =~ m/$RE_METACHAR/oxms;

        return $self->violation( $DESC, $EXPL, $elem );

    } else {
        return; # OK
    }
}

1;

__END__

#-----------------------------------------------------------------------------

#line 178

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
