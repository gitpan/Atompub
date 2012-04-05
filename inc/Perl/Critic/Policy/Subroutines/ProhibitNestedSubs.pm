#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Subroutines/ProhibitNestedSubs.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Subroutines::ProhibitNestedSubs;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Nested named subroutine};
Readonly::Scalar my $EXPL =>
    q{Declaring a named sub inside another named sub does not prevent the }
        . q{inner sub from being global};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                    }
sub default_severity     { return $SEVERITY_HIGHEST     }
sub default_themes       { return qw(core bugs)         }
sub applies_to           { return 'PPI::Statement::Sub' }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    return if $elem->isa('PPI::Statement::Scheduled');

    my $inner = $elem->find_first(
        sub {
            return
                    $_[1]->isa('PPI::Statement::Sub')
                &&  ! $_[1]->isa('PPI::Statement::Scheduled');
        }
    );
    return if not $inner;

    # Must be a violation...
    return $self->violation($DESC, $EXPL, $inner);
}

1;

__END__

#-----------------------------------------------------------------------------

#line 114

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
