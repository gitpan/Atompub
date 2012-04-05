#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/CodeLayout/RequireTrailingCommas.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::CodeLayout::RequireTrailingCommas;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :characters :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{List declaration without trailing comma};
Readonly::Scalar my $EXPL => [ 17 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                     }
sub default_severity     { return $SEVERITY_LOWEST       }
sub default_themes       { return qw(core pbp cosmetic)  }
sub applies_to           { return 'PPI::Structure::List' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    $elem =~ m{ \n }xms || return;

    # Is it an assignment of some kind?
    my $sib = $elem->sprevious_sibling();
    return if !$sib;
    $sib->isa('PPI::Token::Operator') && $sib =~ m{ = }xms || return;

    # List elements are children of an expression
    my $expr = $elem->schild(0);
    return if !$expr;

    # Does the list have more than 1 element?
    # This means list element, not PPI element.
    my @children = $expr->schildren();
    return if 1 >= grep {    $_->isa('PPI::Token::Operator')
                          && $_ eq $COMMA } @children;

    # Is the final element a comma?
    my $final = $children[-1];
    if ( ! ($final->isa('PPI::Token::Operator') && $final eq $COMMA) ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return; #ok!
}

1;

__END__

#line 121

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
