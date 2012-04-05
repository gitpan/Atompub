#line 1
package PPI::Token::Number;

#line 30

use strict;
use PPI::Token ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token';
}

#line 48

sub base {
	return 10;
}

#line 60

sub literal {
	return 0 + $_[0]->_literal;
}

sub _literal {
	# De-sugar the string representation
	my $self   = shift;
	my $string = $self->content;
	$string =~ s/^\+//;
	$string =~ s/_//g;
	return $string;
}





#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_char {
	my $class = shift;
	my $t     = shift;
	my $char  = substr( $t->{line}, $t->{line_cursor}, 1 );

	# Allow underscores straight through
	return 1 if $char eq '_';

	# Handle the conversion from an unknown to known type.
	# The regex covers "potential" hex/bin/octal number.
	my $token = $t->{token};
	if ( $token->{content} =~ /^-?0_*$/ ) {
		# This could be special
		if ( $char eq 'x' ) {
			$t->{class} = $t->{token}->set_class( 'Number::Hex' );
			return 1;
		} elsif ( $char eq 'b' ) {
			$t->{class} = $t->{token}->set_class( 'Number::Binary' );
			return 1;
		} elsif ( $char =~ /\d/ ) {
			# You cannot have 8s and 9s on octals
			if ( $char eq '8' or $char eq '9' ) {
				$token->{_error} = "Illegal character in octal number '$char'";
			}
			$t->{class} = $t->{token}->set_class( 'Number::Octal' );
			return 1;
		}
	}

	# Handle the easy case, integer or real.
	return 1 if $char =~ /\d/o;

	if ( $char eq '.' ) {
		$t->{class} = $t->{token}->set_class( 'Number::Float' );
		return 1;
	}
	if ( $char eq 'e' || $char eq 'E' ) {
		$t->{class} = $t->{token}->set_class( 'Number::Exp' );
		return 1;
	}

	# Doesn't fit a special case, or is after the end of the token
	# End of token.
	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

1;

#line 167
