#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/CodeLayout/ProhibitHardTabs.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::CodeLayout::ProhibitHardTabs;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :booleans :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Hard tabs used};
Readonly::Scalar my $EXPL => [ 20 ];

#-----------------------------------------------------------------------------

# The following regex should probably be "qr{^ .* [^\t]+ \t}xms" but it doesn't
# match when I expect it to.  I haven't figured out why, so I used "\S" to
# approximately mean "not a tab", and that seemd to work.

Readonly::Scalar my $NON_LEADING_TAB_REGEX => qr{^ .* \S+ \t }xms;

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name           => 'allow_leading_tabs',
            description    => 'Allow hard tabs before first non-whitespace character.',
            default_string => '1',
            behavior       => 'boolean',
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM    }
sub default_themes   { return qw( core cosmetic pbp )   }
sub applies_to       { return 'PPI::Token'        }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    $elem =~ m{ \t }xms || return;

    # The __DATA__ element is exempt
    return if $elem->parent->isa('PPI::Statement::Data');

    # If allowed, permit leading tabs in situations where whitespace s not significant.
    if ( $self->_allow_leading_tabs() ) {

        return if $elem->location->[1] == 1;

        return if _is_extended_regex($elem)
            && $elem !~ $NON_LEADING_TAB_REGEX;

        return if $elem->isa('PPI::Token::QuoteLike::Words')
            && $elem !~ $NON_LEADING_TAB_REGEX;
    }

    # If we get here, then it must be a violation...
    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

sub _allow_leading_tabs {
    my ( $self ) = @_;
    return $self->{_allow_leading_tabs};
}

#-----------------------------------------------------------------------------

sub _is_extended_regex {
    my ($elem) = @_;

    $elem->isa('PPI::Token::Regexp')
        || $elem->isa('PPI::Token::QuoteLike::Regexp')
            || return;

   # Look for the /x modifier near the end
   return $elem =~ m{\b [gimso]* x [gimso]* $}xms;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 159

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
