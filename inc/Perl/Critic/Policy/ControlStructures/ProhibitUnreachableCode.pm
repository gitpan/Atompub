#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ControlStructures/ProhibitUnreachableCode.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ControlStructures::ProhibitUnreachableCode;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :data_conversion :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

Readonly::Array my @TERMINALS => qw( die exit croak confess );
Readonly::Hash  my %TERMINALS => hashify( @TERMINALS );

Readonly::Array my @CONDITIONALS => qw( if unless foreach while until for );
Readonly::Hash  my %CONDITIONALS => hashify( @CONDITIONALS );

Readonly::Array my @OPERATORS => qw( && || // and or err ? );
Readonly::Hash  my %OPERATORS => hashify( @OPERATORS );

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Unreachable code};
Readonly::Scalar my $EXPL => q{Consider removing it};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_severity     { return $SEVERITY_HIGH     }
sub default_themes       { return qw( core bugs )    }
sub applies_to           { return 'PPI::Token::Word' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $statement = $elem->statement();
    return if not $statement;

    # We check to see if this is an interesting token before calling
    # is_function_call().  This weeds out most candidate tokens and
    # prevents us from having to make an expensive function call.

    return if ( !exists $TERMINALS{$elem} ) &&
        ( !$statement->isa('PPI::Statement::Break') );

    return if not is_function_call($elem);

    # Scan the enclosing statement for conditional keywords or logical
    # operators.  If any are found, then this the folowing statements
    # could _potentially_ be executed, so this policy is satisfied.

    # NOTE: When the first operand in an boolean expression is
    # C<croak> or C<die>, etc., the second operand is technically
    # unreachable.  But this policy doesn't catch that situation.

    for my $child ( $statement->schildren() ) {
        return if $child->isa('PPI::Token::Operator') && exists $OPERATORS{$child};
        return if $child->isa('PPI::Token::Word') && exists $CONDITIONALS{$child};
    }

    return $self->_gather_violations($statement);
}

sub _gather_violations {
    my ($self, $statement) = @_;

    # If we get here, then the statement contained an unconditional
    # die or exit or return.  Then all the subsequent sibling
    # statements are unreachable, except for those that have labels,
    # which could be reached from anywhere using C<goto>.  Subroutine
    # declarations are also exempt for the same reason.  "use" and
    # "our" statements are exempt because they happen at compile time.

    my @violations = ();
    while ( $statement = $statement->snext_sibling() ) {
        my @children = $statement->schildren();
        last if @children && $children[0]->isa('PPI::Token::Label');
        next if $statement->isa('PPI::Statement::Sub');
        next if $statement->isa('PPI::Statement::End');
        next if $statement->isa('PPI::Statement::Data');
        next if $statement->isa('PPI::Statement::Package');

        next if $statement->isa('PPI::Statement::Include') &&
            $statement->type() ne 'require';

        next if $statement->isa('PPI::Statement::Variable') &&
            $statement->type() eq 'our';

        push @violations, $self->violation( $DESC, $EXPL, $statement );
    }

    return @violations;
}

1;

__END__

#line 227

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
