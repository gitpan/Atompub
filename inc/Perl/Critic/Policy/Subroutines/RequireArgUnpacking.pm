#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Subroutines/RequireArgUnpacking.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Subroutines::RequireArgUnpacking;

use 5.006001;
use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);
use Readonly;

use File::Spec;
use List::Util qw(first);
use List::MoreUtils qw(uniq any);

use Perl::Critic::Utils qw<
    :booleans :characters :severities words_from_string
>;
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $AT => q{@};
Readonly::Scalar my $AT_ARG => q{@_}; ## no critic (InterpolationOfMetachars)
Readonly::Scalar my $DOLLAR => q{$};
Readonly::Scalar my $DOLLAR_ARG => q{$_};   ## no critic (InterpolationOfMetaChars)

Readonly::Scalar my $DESC => qq{Always unpack $AT_ARG first};
Readonly::Scalar my $EXPL => [178];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'short_subroutine_statements',
            description     =>
                'The number of statements to allow without unpacking.',
            default_string  => '0',
            behavior        => 'integer',
            integer_minimum => 0,
        },
        {
            name            => 'allow_subscripts',
            description     =>
                'Should unpacking from array slices and elements be allowed?',
            default_string  => $FALSE,
            behavior        => 'boolean',
        },
        {
            name            => 'allow_delegation_to',
            description     =>
                'Allow the usual delegation idiom to these namespaces/subroutines',
            behavior        => 'string list',
            list_always_present_values => [ qw< SUPER:: NEXT:: > ],
        }
    );
}

sub default_severity     { return $SEVERITY_HIGH             }
sub default_themes       { return qw( core pbp maintenance ) }
sub applies_to           { return 'PPI::Statement::Sub'      }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # forward declaration?
    return if not $elem->block;

    my @statements = $elem->block->schildren;

    # empty sub?
    return if not @statements;

    # Don't apply policy to short subroutines

    # Should we instead be doing a find() for PPI::Statement
    # instances?  That is, should we count all statements instead of
    # just top-level statements?
    return if $self->{_short_subroutine_statements} >= @statements;

    # look for explicit dereferences of @_, including '$_[0]'
    # You may use "... = @_;" in the first paragraph of the sub
    # Don't descend into nested or anonymous subs
    my $state = 'unpacking'; # still in unpacking paragraph
    for my $statement (@statements) {

        my @magic = _get_arg_symbols($statement);

        my $saw_unpack = $FALSE;

        MAGIC:
        for my $magic (@magic) {
            # allow conditional checks on the size of @_
            next MAGIC if _is_size_check($magic);

            if ('unpacking' eq $state) {
                if ($self->_is_unpack($magic)) {
                    $saw_unpack = $TRUE;
                    next MAGIC;
                }
            }

            # allow @$_[] construct in "... for ();"
            # Check for "print @$_[] for ()" construct (rt39601)
            next MAGIC
                if _is_cast_of_array($magic) and _is_postfix_foreach($magic);

            # allow $$_[], which is equivalent to $_->[] and not a use
            # of @_ at all.
            next MAGIC
                if _is_cast_of_scalar( $magic );

            # allow delegation of the form "$self->SUPER::foo( @_ );"
            next MAGIC
                if $self->_is_delegation( $magic );

            # If we make it this far, it is a violaton
            return $self->violation( $DESC, $EXPL, $elem );
        }
        if (not $saw_unpack) {
            $state = 'post_unpacking';
        }
    }
    return;  # OK
}

sub _is_unpack {
    my ($self, $magic) = @_;

    my $prev = $magic->sprevious_sibling();
    my $next = $magic->snext_sibling();

    # If we have a subscript, we're dealing with an array slice on @_
    # or an array element of @_. See RT #34009.
    if ( $next and $next->isa('PPI::Structure::Subscript') ) {
        $self->{_allow_subscripts} or return;
        $next = $next->snext_sibling;
    }

    return $TRUE if
            $prev
        and $prev->isa('PPI::Token::Operator')
        and q{=} eq $prev->content()
        and (
                not $next
            or  $next->isa('PPI::Token::Structure')
            and $SCOLON eq $next->content()
    );
    return;
}

sub _is_size_check {
    my ($magic) = @_;

    # No size check on $_[0]. RT #34009.
    $AT eq $magic->raw_type or return;

    my $prev = $magic->sprevious_sibling;
    my $next = $magic->snext_sibling;

    return $TRUE
        if
                not $next
            and $prev
            and $prev->isa('PPI::Token::Operator')
            and (q<==> eq $prev->content() or q<!=> eq $prev->content());

    return $TRUE
        if
                not $prev
            and $next
            and $next->isa('PPI::Token::Operator')
            and (q<==> eq $next->content() or q<!=> eq $next->content());

    return;
}

sub _is_postfix_foreach {
    my ($magic) = @_;

    my $sibling = $magic;
    while ( $sibling = $sibling->snext_sibling ) {
        return $TRUE
            if
                    $sibling->isa('PPI::Token::Word')
                and $sibling =~ m< \A for (?:each)? \z >xms;
    }
    return;
}

sub _is_cast_of_array {
    my ($magic) = @_;

    my $prev = $magic->sprevious_sibling;

    return $TRUE
        if ( $prev && $prev->content() eq $AT )
            and $prev->isa('PPI::Token::Cast');
    return;
}

# This subroutine recognizes (e.g.) $$_[0]. This is a use of $_ (equivalent to
# $_->[0]), not @_.

sub _is_cast_of_scalar {
    my ($magic) = @_;

    my $prev = $magic->sprevious_sibling;
    my $next = $magic->snext_sibling;

    return $DOLLAR_ARG eq $magic->content() &&
        $prev && $prev->isa('PPI::Token::Cast') &&
            $DOLLAR eq $prev->content() &&
        $next && $next->isa('PPI::Structure::Subscript');
}

# A literal @_ is allowed as the argument for a delegation.
# An example of the idiom we are looking for is $self->SUPER::foo(@_).
# The argument list of (@_) is required; no other use of @_ is allowed.

sub _is_delegation {
    my ($self, $magic) = @_;

    $AT_ARG eq $magic->content() or return; # Not a literal '@_'.
    my $parent = $magic->parent()           # Don't know what to do with
        or return;                          #   orphans.
    $parent->isa( 'PPI::Statement::Expression' )
        or return;                          # Parent must be expression.
    1 == $parent->schildren()               # '@_' must stand alone in
        or return;                          #   its expression.
    $parent = $parent->parent()             # Still don't know what to do
        or return;                          #   with orphans.
    $parent->isa ( 'PPI::Structure::List' )
        or return;                          # Parent must be a list.
    1 == $parent->schildren()               # '@_' must stand alone in
        or return;                          #   the argument list.
    my $subroutine_name = $parent->sprevious_sibling()
        or return;                          # Missing sub name.
    $subroutine_name->isa( 'PPI::Token::Word' )
        or return;
    $self->{_allow_delegation_to}{$subroutine_name}
        and return 1;
    my ($subroutine_namespace) = $subroutine_name =~ m/ \A ( .* ::) \w+ \z /smx
        or return;
    return $self->{_allow_delegation_to}{$subroutine_namespace};
}


sub _get_arg_symbols {
    my ($statement) = @_;

    return grep {$AT_ARG eq $_->symbol} @{$statement->find(\&_magic_finder) || []};
}

sub _magic_finder {
    # Find all @_ and $_[\d+] not inside of nested subs
    my (undef, $elem) = @_;
    return $TRUE if $elem->isa('PPI::Token::Magic'); # match

    if ($elem->isa('PPI::Structure::Block')) {
        # don't descend into a nested named sub
        return if $elem->statement->isa('PPI::Statement::Sub');

        my $prev = $elem->sprevious_sibling;
        # don't descend into a nested anon sub block
        return if $prev
            and $prev->isa('PPI::Token::Word')
            and 'sub' eq $prev->content();
    }

    return $FALSE; # no match, descend
}


1;

__END__

#-----------------------------------------------------------------------------

#line 393

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
