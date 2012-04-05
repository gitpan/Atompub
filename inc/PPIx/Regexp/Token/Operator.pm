#line 1
#line 29

package PPIx::Regexp::Token::Operator;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPIx::Regexp::Constant qw{ TOKEN_LITERAL };
use PPIx::Regexp::Util qw{ __instance };

our $VERSION = '0.026';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

# These will be intercepted by PPIx::Regexp::Token::Literal if they are
# really literals, so here we may process them unconditionally.

# Note that if we receive a '-' we unconditionally make it an operator,
# relying on the lexer to turn it back into a literal if necessary.

my %operator = map { $_ => 1 } qw{ | - };

sub _treat_as_literal {
    my ( $token ) = @_;
    return __instance( $token, 'PPIx::Regexp::Token::Literal' ) ||
	__instance( $token, 'PPIx::Regexp::Token::Interpolation' );
}

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # We only receive the '-' if we are inside a character class. But it
    # is only an operator if it is preceded and followed by literals. We
    # can use prior() because there are no insignificant tokens inside a
    # character class.
    if ( $character eq '-' ) {

	_treat_as_literal( $tokenizer->prior() )
	    or return $tokenizer->make_token( 1, TOKEN_LITERAL );
	
	my @tokens = ( $tokenizer->make_token( 1 ) );
	push @tokens, $tokenizer->get_token();
	
	_treat_as_literal( $tokens[1] )
	    or bless $tokens[0], TOKEN_LITERAL;
	
	return ( @tokens );
    }

    return $operator{$character};
}

1;

__END__

#line 109

# ex: set textwidth=72 :
