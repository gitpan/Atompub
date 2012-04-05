#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Miscellanea/ProhibitUselessNoCritic.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Miscellanea::ProhibitUselessNoCritic;

use 5.006001;
use strict;
use warnings;

use Readonly;

use List::MoreUtils qw< none >;

use Perl::Critic::Utils qw{ :severities :classification hashify };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Useless '## no critic' annotation};
Readonly::Scalar my $EXPL => q{This annotation can be removed};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_LOW              }
sub default_themes       { return qw(core maintenance)       }
sub applies_to           { return 'PPI::Document'            }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, undef, $doc ) = @_;

    # If for some reason $doc is not a P::C::Document, then all bets are off
    return if not $doc->isa('Perl::Critic::Document');

    my @violations = ();
    my @suppressed_viols = $doc->suppressed_violations();

    for my $ann ( $doc->annotations() ) {
        if ( none { _annotation_suppresses_violation($ann, $_) } @suppressed_viols ) {
            push @violations, $self->violation($DESC, $EXPL, $ann->element());
        }
    }

    return @violations;
}

#-----------------------------------------------------------------------------

sub _annotation_suppresses_violation {
    my ($annotation, $violation) = @_;

    my $policy_name = $violation->policy();
    my $line = $violation->location()->[0];

    return $annotation->disables_line($line)
        && $annotation->disables_policy($policy_name);
}

#-----------------------------------------------------------------------------

1;

__END__

#line 157

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
