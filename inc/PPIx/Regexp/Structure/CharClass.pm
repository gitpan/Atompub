#line 1
#line 28

package PPIx::Regexp::Structure::CharClass;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

use PPIx::Regexp::Util qw{ __instance };

our $VERSION = '0.026';

sub _new {
    my ( $class, @args ) = @_;
    ref $class and $class = ref $class;
    my %brkt;
    $brkt{finish} = pop @args;
    $brkt{start} = shift @args;
    __instance( $args[0], 'PPIx::Regexp::Token::Operator' )
	and $args[0]->content() eq '^'
	and $brkt{type} = shift @args;
    return $class->SUPER::_new( \%brkt, @args );
}

#line 60

sub negated {
    my ( $self ) = @_;
    return $self->type() ? 1 : 0;
}

# Called by the lexer to record the capture number.
sub __PPIX_LEXER__record_capture_number {
    my ( $self, $number ) = @_;
    return $number;
}

1;

__END__

#line 98

# ex: set textwidth=72 :
