#line 1
package PPI::Token::Number::Octal;

#line 27

use strict;
use PPI::Token::Number ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token::Number';
}

#line 44

sub base () { 8 }

#line 54

sub literal {
	my $self = shift;
	return if $self->{_error};
	my $str = $self->_literal;
	my $neg = $str =~ s/^\-//;
	my $val = oct $str;
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

	if ( $char =~ /\d/ ) {
		# You cannot have 8s and 9s on octals
		if ( $char eq '8' or $char eq '9' ) {
			$t->{token}->{_error} = "Illegal character in octal number '$char'";
		}
		return 1;
	}

	# Doesn't fit a special case, or is after the end of the token
	# End of token.
	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

1;

#line 115
