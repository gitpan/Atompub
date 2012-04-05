#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Objects/ProhibitIndirectSyntax.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Objects::ProhibitIndirectSyntax;

use 5.006001;
use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);
use Perl::Critic::Utils qw{ :severities :classification };
use Readonly;

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Hash my %COMMA => {
    q<,> => 1,
    q{=>} => 1,
};
Readonly::Scalar my $DOLLAR => q<$>;

Readonly::Scalar my $DESC => 'Subroutine "%s" called using indirect syntax';
Readonly::Scalar my $EXPL => [ 349 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name                       => 'forbid',
            description                => 'Indirect method syntax is forbidden for these methods.',
            behavior                   => 'string list',
            list_always_present_values => [ qw{ new } ],
        }
    )
}

sub default_severity     { return $SEVERITY_HIGH             }
sub default_themes       { return qw( core pbp maintenance ) }
sub applies_to           { return 'PPI::Token::Word'         }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # We are only interested in the functions we have been told to check.
    # Do this before calling is_function_call() because we want to weed
    # out as many candidate tokens as possible before calling it.
    return if not $self->{_forbid}->{$elem->content()};

    # Make sure it really is a function call.
    return if not is_function_call($elem);

    # Per perlobj, it is only an indirect object call if the next sibling
    # is a word, a scalar symbol, or a block.
    my $object = $elem->snext_sibling() or return;
    return if not (
            $object->isa( 'PPI::Token::Word' )
        or      $object->isa( 'PPI::Token::Symbol' )
            and $DOLLAR eq $object->raw_type()
        or  $object->isa( 'PPI::Structure::Block' )
    );

    # Per perlobj, it is not an indirect object call if the operator after
    # the possible indirect object is a comma.
    if ( my $operator = $object->snext_sibling() ) {
        return if
                $operator->isa( 'PPI::Token::Operator' )
            and $COMMA{ $operator->content() };
    }

    my $message = sprintf $DESC, $elem->content();

    return $self->violation( $message, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

#line 161

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :

