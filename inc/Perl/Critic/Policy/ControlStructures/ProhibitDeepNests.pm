#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ControlStructures/ProhibitDeepNests.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ControlStructures::ProhibitDeepNests;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Code structure is deeply nested};
Readonly::Scalar my $EXPL => q{Consider refactoring};

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'max_nests',
            description     => 'The maximum number of nested constructs to allow.',
            default_string  => '5',
            behavior        => 'integer',
            integer_minimum => 1,
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM                }
sub default_themes   { return qw(core maintenance complexity) }
sub applies_to       { return 'PPI::Statement::Compound'      }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $nest_count = 1;  #For _this_ element
    my $parent = $elem;

    while ( $parent = $parent->parent() ){
        if( $parent->isa('PPI::Statement::Compound') ) {
            $nest_count++;
        }
    }

    if ( $nest_count > $self->{_max_nests} ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}


1;

__END__


#-----------------------------------------------------------------------------

#line 116

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
