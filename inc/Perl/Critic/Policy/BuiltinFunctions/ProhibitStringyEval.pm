#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/BuiltinFunctions/ProhibitStringyEval.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::BuiltinFunctions::ProhibitStringyEval;

use 5.006001;
use strict;
use warnings;

use Readonly;

use PPI::Document;

use Perl::Critic::Utils qw{ :booleans :severities :classification :ppi $SCOLON };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Expression form of "eval"};
Readonly::Scalar my $EXPL => [ 161 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name           => 'allow_includes',
            description    => q<Allow eval of "use" and "require" strings.>,
            default_string => '0',
            behavior       => 'boolean',
        },
    );
}
sub default_severity     { return $SEVERITY_HIGHEST   }
sub default_themes       { return qw( core pbp bugs ) }
sub applies_to           { return 'PPI::Token::Word'  }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem ne 'eval';
    return if not is_function_call($elem);

    my $argument = first_arg($elem);
    return if not $argument;
    return if $argument->isa('PPI::Structure::Block');
    return if
        $self->{_allow_includes} and _string_eval_is_an_include($argument);

    return $self->violation( $DESC, $EXPL, $elem );
}

sub _string_eval_is_an_include {
    my ($eval_argument) = @_;

    return if not $eval_argument->isa('PPI::Token::Quote');

    my $string = $eval_argument->string();
    my $document;

    eval { $document = PPI::Document->new(\$string); 1 }
        or return;

    my @statements = $document->schildren;

    return if @statements > 2;
    my $include = $statements[0];
    return if not defined $include; # RT 60179
    return if not $include->isa('PPI::Statement::Include');
    return if $include->type() eq 'no';

    if (
            $eval_argument->isa('PPI::Token::Quote::Single')
        or  $eval_argument->isa('PPI::Token::Quote::Literal')
    ) {
        # Don't allow funky inclusion of arbitrary code (note we do allow
        # interpolated values in interpolating strings because they can't
        # entirely screw with the syntax).
        return if $include->find('PPI::Token::Symbol');
    }

    return $TRUE if @statements == 1;

    my $follow_on = $statements[1];
    return if not $follow_on->isa('PPI::Statement');

    my @follow_on_components = $follow_on->schildren();

    return if @follow_on_components > 2;
    return if not $follow_on_components[0]->isa('PPI::Token::Number');
    return $TRUE if @follow_on_components == 1;

    return $follow_on_components[1]->content() eq $SCOLON;
}


1;

__END__

#-----------------------------------------------------------------------------

#line 182

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
