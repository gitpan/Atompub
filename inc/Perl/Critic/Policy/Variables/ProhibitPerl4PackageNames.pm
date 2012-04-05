#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Variables/ProhibitPerl4PackageNames.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Variables::ProhibitPerl4PackageNames;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :characters :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL =>
    q{Use double colon (::) to separate package name components instead of single quotes (')};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                                        }
sub default_severity     { return $SEVERITY_LOW                             }
sub default_themes       { return qw(core maintenance)                      }
sub applies_to           { return qw( PPI::Token::Word PPI::Token::Symbol ) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    my $content = $elem->content();

    if ( (index $content, $QUOTE) < 0 ) {
        return;
    }

    if ( $content =~ m< \A [\$@%&*] ' \z >xms ) {
        # We've found $POSTMATCH.
        return;
    }

    if ( $elem->isa('PPI::Token::Word') && is_hash_key($elem) ) {
        return;
    }

    return
        $self->violation(
            qq{"$content" uses the obsolete single quote package separator."},
            $EXPL,
            $elem
        );
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

#line 118

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
