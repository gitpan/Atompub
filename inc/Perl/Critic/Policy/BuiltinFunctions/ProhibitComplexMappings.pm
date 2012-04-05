#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/BuiltinFunctions/ProhibitComplexMappings.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::BuiltinFunctions::ProhibitComplexMappings;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Map blocks should have a single statement};
Readonly::Scalar my $EXPL => [ 113 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'max_statements',
            description     =>
                'The maximum number of statements to allow within a map block.',
            default_string  => '1',
            behavior        => 'integer',
            integer_minimum => 1,
        },
    );
}

sub default_severity  { return $SEVERITY_MEDIUM                     }
sub default_themes    { return qw( core pbp maintenance complexity) }
sub applies_to        { return 'PPI::Token::Word'                   }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem ne 'map';
    return if ! is_function_call($elem);

    my $sib = $elem->snext_sibling();
    return if !$sib;

    my $arg = $sib;
    if ( $arg->isa('PPI::Structure::List') ) {
        $arg = $arg->schild(0);
        # Forward looking: PPI might change in v1.200 so schild(0) is a PPI::Statement::Expression
        if ( $arg && $arg->isa('PPI::Statement::Expression') ) {
            $arg = $arg->schild(0);
        }
    }
    # If it's not a block, it's an expression-style map, which is only one statement by definition
    return if !$arg;
    return if !$arg->isa('PPI::Structure::Block');

    # If we get here, we found a sort with a block as the first arg
    return if $self->{_max_statements} >= $arg->schildren()
        && 0 == grep {$_->isa('PPI::Statement::Compound')} $arg->schildren();

    # more than one child statements
    return $self->violation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

#line 145

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
