#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Miscellanea/ProhibitUnrestrictedNoCritic.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Miscellanea::ProhibitUnrestrictedNoCritic;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw<:severities :booleans>;
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Unrestricted '## no critic' annotation};
Readonly::Scalar my $EXPL => q{Only disable the Policies you really need to disable};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core maintenance )     }
sub applies_to           { return 'PPI::Document'            }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $doc, undef ) = @_;

    # If for some reason $doc is not a P::C::Document, then all bets are off
    return if not $doc->isa('Perl::Critic::Document');

    my @violations = ();
    for my $annotation ($doc->annotations()) {
        if ($annotation->disables_all_policies()) {
            my $elem = $annotation->element();
            push @violations, $self->violation($DESC, $EXPL, $elem);
        }
    }

    return @violations;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

#line 134

###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
