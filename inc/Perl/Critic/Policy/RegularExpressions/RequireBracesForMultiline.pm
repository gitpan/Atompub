#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/RegularExpressions/RequireBracesForMultiline.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::RegularExpressions::RequireBracesForMultiline;

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

Readonly::Scalar my $DESC => q<Use '{' and '}' to delimit multi-line regexps>;
Readonly::Scalar my $EXPL => [242];

Readonly::Array my @EXTRA_BRACKETS => qw{ () [] <> };

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name               => 'allow_all_brackets',
            description        =>
                q[In addition to allowing '{}', allow '()', '[]', and '{}'.],
            behavior           => 'boolean',
        },
    );
}

sub default_severity     { return $SEVERITY_LOWEST        }
sub default_themes       { return qw( core pbp cosmetic ) }
sub applies_to           { return qw(PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute
                                     PPI::Token::QuoteLike::Regexp) }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    my %delimiters = ( q<{}> => 1 );
    if ( $self->{_allow_all_brackets} ) {
        @delimiters{ @EXTRA_BRACKETS } = (1) x @EXTRA_BRACKETS;
    }

    $self->{_allowed_delimiters} = \%delimiters;

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $re = $elem->get_match_string();
    return if $re !~ m/\n/xms;

    my ($match_delim) = $elem->get_delimiters();
    return if $self->{_allowed_delimiters}{$match_delim};

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

#line 154

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
