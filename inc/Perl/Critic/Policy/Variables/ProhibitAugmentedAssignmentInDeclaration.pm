#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Variables/ProhibitAugmentedAssignmentInDeclaration.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Variables::ProhibitAugmentedAssignmentInDeclaration;

use 5.006001;
use strict;
use warnings;
use List::MoreUtils qw{ firstval };
use Readonly;

use Perl::Critic::Utils qw{ :severities :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Augmented assignment operator '%s' used in declaration};
Readonly::Scalar my $EXPL => q{Use simple assignment when intializing variables};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_HIGH             }
sub default_themes       { return qw( core bugs )            }
sub applies_to           { return 'PPI::Statement::Variable' }

#-----------------------------------------------------------------------------

my %augmented_assignments = hashify( qw( **= += -= .= *= /= %= x= &= |= ^= <<= >>= &&= ||= //= ) );

sub violates {
    my ( $self, $elem, undef ) = @_;

    # The assignment operator associated with a PPI::Statement::Variable
    # element is assumed to be the first immediate child of that element.
    # Other operators in the statement, e.g. the ',' in "my ( $a, $b ) = ();",
    # as assumed to never be immediate children.

    my $found = firstval { $_->isa('PPI::Token::Operator') } $elem->children();
    if ( $found ) {
        my $op = $found->content();
        if ( !exists $augmented_assignments{ $op } ) {
            # PPI doesn't parse all augmented assignment operators.  Detect
            # the unsupported ones by concatenating two immediately adjacent
            # operators and trying again.
            my $immediately_adjacent = $found->next_sibling();  # not snext_sibling()
            if ( $immediately_adjacent && $immediately_adjacent->isa('PPI::Token::Operator') ) {
                $op .= $immediately_adjacent->content();
            }
        }

        if ( exists $augmented_assignments{ $op } ) {
            return $self->violation( sprintf( $DESC, $op ), $EXPL, $found );
        }
    }

    return;
}


1;

__END__

#-----------------------------------------------------------------------------

#line 121

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
