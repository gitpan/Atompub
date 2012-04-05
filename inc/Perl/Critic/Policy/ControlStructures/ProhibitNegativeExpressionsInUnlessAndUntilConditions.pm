#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ControlStructures/ProhibitNegativeExpressionsInUnlessAndUntilConditions.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions;

use 5.006001;
use strict;
use warnings;
use English qw(-no_match_vars);
use Readonly;

use Perl::Critic::Utils qw< :characters :severities :classification hashify >;

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => [99];

#-----------------------------------------------------------------------------

sub supported_parameters { return qw< >                      }
sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core maintenance pbp ) }
sub applies_to           { return 'PPI::Token::Word'         }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $token, undef ) = @_;

    return if $token ne 'until' && $token ne 'unless';

    return if is_hash_key($token);
    return if is_subroutine_name($token);
    return if is_method_call($token);
    return if is_included_module_name($token);

    return
        map
            { $self->_violation_for_operator( $_, $token ) }
            _get_negative_operators( $token );
}

#-----------------------------------------------------------------------------

sub _get_negative_operators {
    my ($token) = @_;

    my @operators;
    foreach my $element ( _get_condition_elements($token) ) {
        if ( $element->isa('PPI::Node') ) {
            my $operators = $element->find( \&_is_negative_operator );
            if ($operators) {
                push @operators, @{$operators};
            }
        }
        else {
            if ( _is_negative_operator( undef, $element ) ) {
                push @operators, $element;
            }
        }
    }

    return @operators;
}

#-----------------------------------------------------------------------------

sub _get_condition_elements {
    my ($token) = @_;

    my $statement = $token->statement();
    return if not $statement;

    if ($statement->isa('PPI::Statement::Compound')) {
        my $condition = $token->snext_sibling();

        return if not $condition;
        return if not $condition->isa('PPI::Structure::Condition');

        return ( $condition );
    }

    my @condition_elements;
    my $element = $token;
    while (
            $element = $element->snext_sibling()
        and $element ne $SCOLON
    ) {
        push @condition_elements, $element;
    }

    return @condition_elements;
}

#-----------------------------------------------------------------------------

Readonly::Hash my %NEGATIVE_OPERATORS => hashify(
    qw/
        ! not
        !~ ne !=
        <   >   <=  >=  <=>
        lt  gt  le  ge  cmp
    /
);

sub _is_negative_operator {
    my (undef, $element) = @_;

    return
            $element->isa('PPI::Token::Operator')
        &&  $NEGATIVE_OPERATORS{$element};
}

#-----------------------------------------------------------------------------

sub _violation_for_operator {
    my ($self, $operator, $control_structure) = @_;

    return
        $self->violation(
            qq<Found "$operator" in condition for an "$control_structure">,
            $EXPL,
            $control_structure,
        );
}

1;

#-----------------------------------------------------------------------------

__END__

#line 200

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
