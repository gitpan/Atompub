#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Modules/ProhibitConditionalUseStatements.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Modules::ProhibitConditionalUseStatements;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :booleans :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Conditional "use" statement};
Readonly::Scalar my $EXPL => q{Use "require" to conditionally include a module.};

# operators

Readonly::Hash my %OPS => map { $_ => 1 } qw( || && or and );

#-----------------------------------------------------------------------------

sub supported_parameters { return ()              }
sub default_severity     { return $SEVERITY_MEDIUM  }
sub default_themes       { return qw( core bugs ) }
sub applies_to           { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    return $self->violation( $DESC, $EXPL, $elem ) if $elem->type() eq 'use'
        && !$elem->pragma()
        && $elem->module()
        && $self->_is_in_conditional_logic($elem);
    return;
}

#-----------------------------------------------------------------------------

# is this a non-string eval statement

sub _is_eval {
    my ( $self, $elem ) = @_;
    $elem->isa('PPI::Statement') or return;
    my $first_elem = $elem->first_element();
    return $TRUE if $first_elem->isa('PPI::Token::Word')
        && $first_elem eq 'eval';
    return;
}

#-----------------------------------------------------------------------------

# is this in a conditional do block

sub _is_in_do_conditional_block {
    my ( $self, $elem ) = @_;
    return if !$elem->isa('PPI::Structure::Block');
    my $prev_sibling = $elem->sprevious_sibling() or return;
    if ($prev_sibling->isa('PPI::Token::Word') && $prev_sibling eq 'do') {
        my $next_sibling = $elem->snext_sibling();
        return $TRUE if $next_sibling
            && $next_sibling->isa('PPI::Token::Word');
        $prev_sibling = $prev_sibling->sprevious_sibling() or return;
        return $TRUE if $prev_sibling->isa('PPI::Token::Operator')
            && $OPS{$prev_sibling->content()};
    }
    return;
}

#-----------------------------------------------------------------------------

# is this a compound statement

sub _is_compound_statement {
    my ( $self, $elem ) = @_;
    return if !$elem->isa('PPI::Statement::Compound');
    return $TRUE if $elem->type() ne 'continue'; # exclude bare blocks
    return;
}

#-----------------------------------------------------------------------------

# is this contained in conditional logic

sub _is_in_conditional_logic {
    my ( $self, $elem ) = @_;
    while ($elem = $elem->parent()) {
        last if $elem->isa('PPI::Document');
        return $TRUE if $self->_is_compound_statement($elem)
            || $self->_is_eval($elem)
            || $self->_is_in_do_conditional_block($elem);
    }
    return;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 201

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
