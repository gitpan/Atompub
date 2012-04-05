#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/InputOutput/RequireBracedFileHandleWithPrint.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::InputOutput::RequireBracedFileHandleWithPrint;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Array my @POSTFIX_WORDS => qw( if unless for );
Readonly::Hash my %POSTFIX_WORDS => hashify( @POSTFIX_WORDS );
Readonly::Scalar my $PRINT_RX  => qr/ \A (?: print f? | say ) \z /xms;

Readonly::Scalar my $DESC => q{File handle for "print" or "printf" is not braced};
Readonly::Scalar my $EXPL => [ 217 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                      }
sub default_severity     { return $SEVERITY_LOWEST        }
sub default_themes       { return qw( core pbp cosmetic ) }
sub applies_to           { return 'PPI::Token::Word'      }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem !~ $PRINT_RX;
    return if ! is_function_call($elem);

    my @sib;

    $sib[0] = $elem->snext_sibling();
    return if !$sib[0];

    # Deal with situations where 'print' is called with parentheses
    if ( $sib[0]->isa('PPI::Structure::List') ) {
        my $expr = $sib[0]->schild(0);
        return if !$expr;
        $sib[0] = $expr->schild(0);
        return if !$sib[0];
    }

    $sib[1] = $sib[0]->next_sibling();
    return if !$sib[1];
    $sib[2] = $sib[1]->next_sibling();
    return if !$sib[2];

    # First token must be a scalar symbol or bareword;
    return if !( ($sib[0]->isa('PPI::Token::Symbol') && $sib[0] =~ m/\A \$/xms)
                 || $sib[0]->isa('PPI::Token::Word') );

    # First token must not be a builtin function or control
    return if is_perl_builtin($sib[0]);
    return if exists $POSTFIX_WORDS{ $sib[0] };

    # Second token must be white space
    return if !$sib[1]->isa('PPI::Token::Whitespace');

    # Third token must not be an operator
    return if $sib[2]->isa('PPI::Token::Operator');

    # Special case for postfix controls
    return if exists $POSTFIX_WORDS{ $sib[2] };

    return if $sib[0]->isa('PPI::Structure::Block');

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

#line 137

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :