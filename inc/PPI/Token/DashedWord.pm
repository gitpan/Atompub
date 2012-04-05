#line 1
package PPI::Token::DashedWord;

#line 27

use strict;
use PPI::Token ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token';
}

#line 67

*literal = *PPI::Token::Word::literal;



#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_char {
	my $t = $_[1];

	# Suck to the end of the dashed bareword
	my $line = substr( $t->{line}, $t->{line_cursor} );
	if ( $line =~ /^(\w+)/ ) {
		$t->{token}->{content} .= $1;
		$t->{line_cursor} += length $1;
	}

	# Are we a file test operator?
	if ( $t->{token}->{content} =~ /^\-[rwxoRWXOezsfdlpSbctugkTBMAC]$/ ) {
		# File test operator
		$t->{class} = $t->{token}->set_class( 'Operator' );
	} else {
		# No, normal dashed bareword
		$t->{class} = $t->{token}->set_class( 'Word' );
	}

	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

1;

#line 120
