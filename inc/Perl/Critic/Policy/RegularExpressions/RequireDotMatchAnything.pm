#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/RegularExpressions/RequireDotMatchAnything.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::RegularExpressions::RequireDotMatchAnything;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Regular expression without "/s" flag};
Readonly::Scalar my $EXPL => [ 240, 241 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                    }
sub default_severity     { return $SEVERITY_LOW         }
sub default_themes       { return qw<core pbp cosmetic> }
sub applies_to           { return qw<PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute
                                     PPI::Token::QuoteLike::Regexp> }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $re = $doc->ppix_regexp_from_element( $elem )
        or return;
    $re->modifier_asserted( 's' )
        or return $self->violation( $DESC, $EXPL, $elem );

    return; #ok!;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 106

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
