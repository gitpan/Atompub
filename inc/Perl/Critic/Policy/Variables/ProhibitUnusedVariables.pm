#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Variables/ProhibitUnusedVariables.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Variables::ProhibitUnusedVariables;

use 5.006001;
use strict;
use warnings;

use Readonly;
use List::MoreUtils qw< any >;

use PPI::Token::Symbol;

use Perl::Critic::Utils qw< :characters :severities >;
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL =>
    q<Unused variables clutter code and make it harder to read>;

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                     }
sub default_severity     { return $SEVERITY_MEDIUM       }
sub default_themes       { return qw< core maintenance > }
sub applies_to           { return qw< PPI::Document >    }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $document ) = @_;

    my %symbol_usage;
    _get_symbol_usage( \%symbol_usage, $document );
    _get_regexp_symbol_usage( \%symbol_usage, $document );
    return if not %symbol_usage;

    my $declarations = $document->find('PPI::Statement::Variable');
    return if not $declarations;

    my @violations;

    DECLARATION:
    foreach my $declaration ( @{$declarations} ) {
        next DECLARATION if 'my' ne $declaration->type();

        my @children = $declaration->schildren();
        next DECLARATION if any { $_ eq q<=> } @children;

        VARIABLE:
        foreach my $variable ( $declaration->variables() ) {
            my $count = $symbol_usage{ $variable };
            next VARIABLE if not $count; # BUG!
            next VARIABLE if $count > 1;

            push
                @violations,
                $self->violation(
                    qq<"$variable" is declared but not used.>,
                    $EXPL,
                    $declaration,
                );
        }
    }

    return @violations;
}

sub _get_symbol_usage {
    my ( $symbol_usage, $document ) = @_;

    my $symbols = $document->find('PPI::Token::Symbol');
    return if not $symbols;

    foreach my $symbol ( @{$symbols} ) {
        $symbol_usage->{ $symbol->symbol() }++;
    }

    return;
}

sub _get_regexp_symbol_usage {
    my ( $symbol_usage, $document ) = @_;

    foreach my $class ( qw{
        PPI::Token::Regexp::Match
        PPI::Token::Regexp::Substitute
        PPI::Token::QuoteLike::Regexp
        } ) {

        foreach my $regex ( @{ $document->find( $class ) || [] } ) {

            my $ppix = $document->ppix_regexp_from_element( $regex ) or next;
            $ppix->failures() and next;

            foreach my $code ( @{
                $ppix->find( 'PPIx::Regexp::Token::Code' ) || [] } ) {
                my $subdoc = $code->ppi() or next;
                _get_symbol_usage( $symbol_usage, $subdoc );
            }

        }

    }

    return;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

#line 180

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
