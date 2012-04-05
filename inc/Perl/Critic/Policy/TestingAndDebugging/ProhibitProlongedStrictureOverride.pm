#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/TestingAndDebugging/ProhibitProlongedStrictureOverride.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::TestingAndDebugging::ProhibitProlongedStrictureOverride;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Don't turn off strict for large blocks of code};
Readonly::Scalar my $EXPL => [ 433 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'statements',
            description     => 'The maximum number of statements in a no strict block.',
            default_string  => '3',
            behavior        => 'integer',
            integer_minimum => 1,
        },
    );
}

sub default_severity { return $SEVERITY_HIGH            }
sub default_themes   { return qw( core pbp bugs )       }
sub applies_to       { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    return if $elem->type ne 'no';
    return if $elem->module ne 'strict';

    my $sib = $elem->snext_sibling;
    my $nstatements = 0;
    while ($nstatements++ <= $self->{_statements}) {
        return if !$sib;
        return if $sib->isa('PPI::Statement::Include') &&
            $sib->type eq 'use' &&
            $sib->module eq 'strict';
       $sib = $sib->snext_sibling;
    }

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

#line 115

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
