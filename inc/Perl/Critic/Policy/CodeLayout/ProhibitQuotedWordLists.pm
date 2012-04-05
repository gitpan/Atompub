#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/CodeLayout/ProhibitQuotedWordLists.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::CodeLayout::ProhibitQuotedWordLists;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :characters :severities :classification};
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{List of quoted literal words};
Readonly::Scalar my $EXPL => q{Use 'qw()' instead};

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'min_elements',
            description     => 'The minimum number of words in a list that will be complained about.',
            default_string  => '2',
            behavior        => 'integer',
            integer_minimum => 1,
        },
        {
            name            => 'strict',
            description     => 'Complain even if there are non-word characters in the values.',
            default_string  => '0',
            behavior        => 'boolean',
        },
    );
}

sub default_severity { return $SEVERITY_LOW          }
sub default_themes   { return qw( core cosmetic )    }
sub applies_to       { return 'PPI::Structure::List' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # Don't worry about subroutine calls
    my $sibling = $elem->sprevious_sibling();
    return if not $sibling;

    return if $sibling->isa('PPI::Token::Symbol');
    return if $sibling->isa('PPI::Token::Operator') and $sibling eq '->';
    return if $sibling->isa('PPI::Token::Word') and not is_included_module_name($sibling);

    # Get the list elements
    my $expr = $elem->schild(0);
    return if not $expr;
    my @children = $expr->schildren();
    return if not @children;

    my $count = 0;
    for my $child ( @children ) {
        next if $child->isa('PPI::Token::Operator')  && $child eq $COMMA;

        # All elements must be literal strings,
        # and must contain 1 or more word characters.

        return if not _is_literal($child);

        my $string = $child->string();
        return if $string =~ m{ \s }xms;
        return if $string eq $EMPTY;
        return if not $self->{_strict} and $string !~ m{\A [\w-]+ \z}xms;
        $count++;
    }

    # Were there enough?
    return if $count < $self->{_min_elements};

    # If we get here, then all elements were literals
    return $self->violation( $DESC, $EXPL, $elem );
}

sub _is_literal {
    my $elem = shift;
    return $elem->isa('PPI::Token::Quote::Single')
        || $elem->isa('PPI::Token::Quote::Literal');
}

1;

__END__

#line 179

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
