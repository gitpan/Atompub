#line 1
package PPI::Token::Number::Float;

#line 29

use strict;
use PPI::Token::Number ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token::Number';
}

#line 46

sub base () { 10 }

#line 56

sub literal {
	my $self = shift;
	my $str = $self->_literal;
	my $neg = $str =~ s/^\-//;
	$str =~ s/^\./0./;
	my $val = 0+$str;
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

	# Allow digits
	return 1 if $char =~ /\d/o;

	# Is there a second decimal point?  Then version string or '..' operator
	if ( $char eq '.' ) {
		if ( $t->{token}->{content} =~ /\.$/ ) {
			# We have a .., which is an operator.
			# Take the . off the end of the token..
			# and finish it, then make the .. operator.
			chop $t->{token}->{content};
                        $t->{class} = $t->{token}->set_class( 'Number' );
			$t->_new_token('Operator', '..');
			return 0;
		} elsif ( $t->{token}->{content} !~ /_/ ) {
			# Underscore means not a Version, fall through to end token
			$t->{class} = $t->{token}->set_class( 'Number::Version' );
			return 1;
		}
	}
	if ($char eq 'e' || $char eq 'E') {
		$t->{class} = $t->{token}->set_class( 'Number::Exp' );
		return 1;
	}

	# Doesn't fit a special case, or is after the end of the token
	# End of token.
	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

1;

#line 133
