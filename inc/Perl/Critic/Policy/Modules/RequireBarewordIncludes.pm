#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Modules/RequireBarewordIncludes.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Modules::RequireBarewordIncludes;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => q{Use a bareword instead};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                        }
sub default_severity     { return $SEVERITY_HIGHEST         }
sub default_themes       { return qw(core portability)      }
sub applies_to           { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $child = $elem->schild(1);
    return if !$child;

    if ( $child->isa('PPI::Token::Quote') ) {
        my $type = $elem->type;
        my $desc = qq{"$type" statement with library name as string};
        return $self->violation( $desc, $EXPL, $elem );
    }
    return; #ok!
}


1;

__END__

#-----------------------------------------------------------------------------

#line 123

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
