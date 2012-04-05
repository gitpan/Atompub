#line 1
package PPI::Token::ArrayIndex;

#line 27

use strict;
use PPI::Token ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token';
}





#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_char {
	my $t = $_[1];

	# Suck in till the end of the arrayindex
	my $line = substr( $t->{line}, $t->{line_cursor} );
	if ( $line =~ /^([\w:']+)/ ) {
		$t->{token}->{content} .= $1;
		$t->{line_cursor} += length $1;
	}

	# End of token
	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

1;

#line 81
