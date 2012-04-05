#line 1
package PPI::Token::Number::Exp;

#line 29

use strict;
use PPI::Token::Number::Float ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token::Number::Float';
}

#line 46

sub literal {
	my $self = shift;
	return if $self->{_error};
	my ($mantissa, $exponent) = split m/e/i, $self->_literal;
	my $neg = $mantissa =~ s/^\-//;
	$mantissa =~ s/^\./0./;
	$exponent =~ s/^\+//;
	my $val = $mantissa * 10 ** $exponent;
	return $neg ? -$val : $val;
}





#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_char {
	my $class = shift;
	my $t     = shift;
	my $char  = substr( $t->{line}, $t->{line_cursor}, 1 );

        # To get here, the token must have already encountered an 'E'

	# Allow underscores straight through
	return 1 if $char eq '_';

	# Allow digits
	return 1 if $char =~ /\d/o;

	# Start of exponent is special
	if ( $t->{token}->{content} =~ /e$/i ) {
		# Allow leading +/- in exponent
		return 1 if $char eq '-' || $char eq '+';

		# Invalid character in exponent.  Recover
		if ( $t->{token}->{content} =~ s/\.(e)$//i ) {
			my $word = $1;
			$t->{class} = $t->{token}->set_class('Number');
			$t->_new_token('Operator', '.');
			$t->_new_token('Word', $word);
			return $t->{class}->__TOKENIZER__on_char( $t );
		}
		else {
			$t->{token}->{_error} = "Illegal character in exponent '$char'";
		}
	}

	# Doesn't fit a special case, or is after the end of the token
	# End of token.
	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

1;

#line 124
