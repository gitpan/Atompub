#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ValuesAndExpressions/ProhibitMixedBooleanOperators.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitMixedBooleanOperators;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :data_conversion };
use base 'Perl::Critic::Policy';


#-----------------------------------------------------------------------------

our $VERSION = '1.117';
#-----------------------------------------------------------------------------

Readonly::Hash my %LOW_BOOLEANS  => hashify( qw( not or and ) );
Readonly::Hash my %HIGH_BOOLEANS => hashify( qw( ! || && ) );

Readonly::Hash my %EXEMPT_TYPES => hashify(
    qw(
        PPI::Statement::Block
        PPI::Statement::Scheduled
        PPI::Statement::Package
        PPI::Statement::Include
        PPI::Statement::Sub
        PPI::Statement::Variable
        PPI::Statement::Compound
        PPI::Statement::Data
        PPI::Statement::End
    )
);

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Mixed high and low-precedence booleans};
Readonly::Scalar my $EXPL => [ 70 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity     { return $SEVERITY_HIGH      }
sub default_themes       { return qw( core bugs pbp ) }
sub applies_to           { return 'PPI::Statement'    }

#-----------------------------------------------------------------------------

sub violates {

    my ( $self, $elem, undef ) = @_;

    # PPI::Statement is the ancestor of several types of PPI elements.
    # But for this policy, we only want the ones that generally
    # represent a single statement or expression.  There might be
    # better ways to do this, such as scanning for a semi-colon or
    # some other marker.

    return if exists $EXEMPT_TYPES{ ref $elem };

    if (    $elem->find_first(\&_low_boolean)
         && $elem->find_first(\&_high_boolean) ) {

        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

#-----------------------------------------------------------------------------

sub _low_boolean {
    my (undef, $elem) = @_;
    return if $elem->isa('PPI::Statement');
    $elem->isa('PPI::Token::Operator') || return 0;
    return exists $LOW_BOOLEANS{$elem};
}

#-----------------------------------------------------------------------------

sub _high_boolean {
    my (undef, $elem) = @_;
    return if $elem->isa('PPI::Statement');
    $elem->isa('PPI::Token::Operator') || return 0;
    return exists $HIGH_BOOLEANS{$elem};
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
