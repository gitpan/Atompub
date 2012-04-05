#line 1
package PPI::Token::Cast;

#line 32

use strict;
use PPI::Token ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token';
}




#####################################################################
# Tokenizer Methods

# A cast is either % @ $ or $#
sub __TOKENIZER__on_char {
	$_[1]->_finalize_token->__TOKENIZER__on_char( $_[1] );
}

1;

#line 76
