#line 1
package PPI::Token::Number::Binary;

#line 27

use strict;
use PPI::Token::Number ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token::Number';
}

#line 44

sub base {
	return 2;
}

#line 56

sub literal {
	my $self = shift;
	return if $self->{_error};
	my $str = $self->_literal;
	my $neg = $str =~ s/^\-//;
	$str =~ s/^0b//;
	my $val = 0;
	for my $bit ( $str =~ m/(.)/g ) {
		$val = $val * 2 + $bit;
	}
	return $neg ? -$val : $val;
}





#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_char {
	my $class = shift;
	my $t     = shift;
	my $char  = substr( $t->{line}, $t->{line_cursor}, 1 );

	# Allow underscores straight through
	return 1 if $char eq '_';

	if ( $char =~ /[\w\d]/ ) {
		unless ( $char eq '1' or $char eq '0' ) {
			# Add a warning if it contains non-hex chars
			$t->{token}->{_error} = "Illegal character in binary number '$char'";
		}
		return 1;
	}

	# Doesn't fit a special case, or is after the end of the token
	# End of token.
	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

1;

#line 121
