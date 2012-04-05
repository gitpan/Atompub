#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/RegularExpressions/RequireExtendedFormatting.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Regular expression without "/x" flag};
Readonly::Scalar my $EXPL => [ 236 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name               => 'minimum_regex_length_to_complain_about',
            description        =>
                q<The number of characters that a regular expression must contain before this policy will complain.>,
            behavior           => 'integer',
            default_string     => '0',
            integer_minimum    => 0,
        },
        {
            name               => 'strict',
            description        =>
                q<Should regexes that only contain whitespace and word characters be complained about?>,
            behavior           => 'boolean',
            default_string     => '0',
        },
    );
}

sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw< core pbp maintenance > }
sub applies_to           {
    return qw<
        PPI::Token::Regexp::Match
        PPI::Token::Regexp::Substitute
        PPI::Token::QuoteLike::Regexp
    >;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $match = $elem->get_match_string();
    return if length $match <= $self->{_minimum_regex_length_to_complain_about};
    return if not $self->{_strict} and $match =~ m< \A [\s\w]* \z >xms;

    my $re = $doc->ppix_regexp_from_element( $elem )
        or return;
    $re->modifier_asserted( 'x' )
        or return $self->violation( $DESC, $EXPL, $elem );

    return; # ok!;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 176

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
