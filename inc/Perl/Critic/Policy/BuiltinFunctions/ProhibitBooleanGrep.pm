#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/BuiltinFunctions/ProhibitBooleanGrep.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::BuiltinFunctions::ProhibitBooleanGrep;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification hashify };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{"grep" used in boolean context};
Readonly::Scalar my $EXPL => [71,72];

Readonly::Hash my %POSTFIX_CONDITIONALS => hashify( qw(if unless while until) );
Readonly::Hash my %BOOLEAN_OPERATORS => hashify( qw(&& || ! not or and));

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                     }
sub default_severity     { return $SEVERITY_LOW          }
sub default_themes       { return qw( core pbp performance ) }
sub applies_to           { return 'PPI::Token::Word'     }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem ne 'grep';
    return if not is_function_call($elem);
    return if not _is_in_boolean_context($elem);

    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

sub _is_in_boolean_context {
    my ($token) = @_;

    return _does_prev_sibling_cause_boolean($token) || _does_parent_cause_boolean($token);
}

sub _does_prev_sibling_cause_boolean {
    my ($token) = @_;

    my $prev = $token->sprevious_sibling;
    return if !$prev;
    return 1 if $prev->isa('PPI::Token::Word') and $POSTFIX_CONDITIONALS{$prev};
    return if not ($prev->isa('PPI::Token::Operator') and $BOOLEAN_OPERATORS{$prev});
    my $next = $token->snext_sibling;
    return 1 if not $next; # bizarre: grep with no arguments

    # loose heuristic: unparenthesized grep has no following non-boolean operators
    return 1 if not $next->isa('PPI::Structure::List');

    $next = $next->snext_sibling;
    return 1 if not $next;
    return 1 if $next->isa('PPI::Token::Operator') and $BOOLEAN_OPERATORS{$next};
    return;
}

sub _does_parent_cause_boolean {
    my ($token) = @_;

    my $prev = $token->sprevious_sibling;
    return if $prev;
    my $parent = $token->statement->parent;
    for (my $node = $parent; $node; $node = $node->parent) { ## no critic (CStyleForLoop)
        next if $node->isa('PPI::Structure::List');
        return 1 if $node->isa('PPI::Structure::Condition');
    }

    return;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 153

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
