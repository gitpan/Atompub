#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ValuesAndExpressions/ProhibitCommaSeparatedStatements.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitCommaSeparatedStatements;

use 5.006001;
use strict;
use warnings;
use Readonly;


use Perl::Critic::Utils qw{ :booleans :characters :severities :classification };
use Perl::Critic::Utils::PPI qw{ is_ppi_statement_subclass };

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Comma used to separate statements};
Readonly::Scalar my $EXPL => [ 68, 71 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name           => 'allow_last_statement_to_be_comma_separated_in_map_and_grep',
            description    => 'Allow map and grep blocks to return lists.',
            default_string => $FALSE,
            behavior       => 'boolean',
        },
    );
}

sub default_severity     { return $SEVERITY_HIGH      }
sub default_themes       { return qw( core bugs pbp ) }
sub applies_to           { return 'PPI::Statement'    }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # Grrr... PPI instantiates non-leaf nodes in its class hierarchy...
    return if is_ppi_statement_subclass($elem);

    # Now, if PPI hasn't introduced any new PPI::Statement subclasses, we've
    # got an element who's class really is PPI::Statement.

    return if _is_parent_a_constructor_or_list($elem);
    return if _is_parent_a_for_loop($elem);

    if (
        $self->{_allow_last_statement_to_be_comma_separated_in_map_and_grep}
    ) {
        return if not _is_direct_part_of_map_or_grep_block($elem);
    }

    foreach my $child ( $elem->schildren() ) {
        if (
                not $self->{_allow_last_statement_to_be_comma_separated_in_map_and_grep}
            and not _is_last_statement_in_a_block($child)
        ) {
            if ( $child->isa('PPI::Token::Word') ) {
                return if _succeeding_commas_are_list_element_separators($child);
            }
            elsif ( $child->isa('PPI::Token::Operator') ) {
                if ( $child->content() eq $COMMA ) {
                    return $self->violation($DESC, $EXPL, $elem);
                }
            }
        }
    }

    return;
}

sub _is_parent_a_constructor_or_list {
    my ($elem) = @_;

    my $parent = $elem->parent();

    return if not $parent;

    return (
            $parent->isa('PPI::Structure::Constructor')
        or  $parent->isa('PPI::Structure::List')
    );
}

sub _is_parent_a_for_loop {
    my ($elem) = @_;

    my $parent = $elem->parent();

    return if not $parent;

    return if not $parent->isa('PPI::Structure::For');

    return 1 == scalar $parent->schildren(); # Multiple means C-style loop.
}

sub _is_direct_part_of_map_or_grep_block {
    my ($elem) = @_;

    my $parent = $elem->parent();
    return if not $parent;
    return if not $parent->isa('PPI::Structure::Block');

    my $block_prior_sibling = $parent->sprevious_sibling();
    return if not $block_prior_sibling;
    return if not $block_prior_sibling->isa('PPI::Token::Word');

    return $block_prior_sibling eq 'map' || $block_prior_sibling eq 'grep';
}

sub _is_last_statement_in_a_block {
    my ($elem) = @_;

    my $parent = $elem->parent();
    return if not $parent;
    return if not $parent->isa('PPI::Structure::Block');

    my $next_sibling = $elem->snext_sibling();
    return if not $next_sibling;

    return 1;
}

sub _succeeding_commas_are_list_element_separators {
    my ($elem) = @_;

    if (
            is_perl_builtin_with_zero_and_or_one_arguments($elem)
        and not is_perl_builtin_with_multiple_arguments($elem)
    ) {
        return;
    }

    my $sibling = $elem->snext_sibling();

    return 1 if not $sibling;  # There won't be any succeeding commas.

    return not $sibling->isa('PPI::Structure::List');
}

1;

__END__

#-----------------------------------------------------------------------------

#line 251

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
