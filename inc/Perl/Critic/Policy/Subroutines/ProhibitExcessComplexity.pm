#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Subroutines/ProhibitExcessComplexity.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Subroutines::ProhibitExcessComplexity;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :data_conversion :classification };
use Perl::Critic::Utils::McCabe qw{ calculate_mccabe_of_sub };

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => q{Consider refactoring};

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'max_mccabe',
            description     => 'The maximum complexity score allowed.',
            default_string  => '20',
            behavior        => 'integer',
            integer_minimum => 1,
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM                }
sub default_themes   { return qw(core complexity maintenance) }
sub applies_to       { return 'PPI::Statement::Sub'           }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $score = calculate_mccabe_of_sub( $elem );

    # Is it too complex?
    return if $score <= $self->{_max_mccabe};

    my $desc;
    if ( my $name = $elem->name() ) {
        $desc = qq<Subroutine "$name" with high complexity score ($score)>;
    }
    else {
        $desc = qq<Anonymous subroutine with high complexity score ($score)>;
    }

    return $self->violation( $desc, $EXPL, $elem );
}


1;

__END__

#-----------------------------------------------------------------------------

#line 142

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
