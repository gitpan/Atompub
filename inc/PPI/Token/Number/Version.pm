#line 1
package PPI::Token::Number::Version;

#line 31

use strict;
use PPI::Token::Number ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token::Number';
}

#line 48

sub base {
	return 256;
}

#line 60

sub literal {
	my $self    = shift;
	my $content = $self->{content};
	$content =~ s/^v//;
	return join '', map { chr $_ } ( split /\./, $content );
}





#####################################################################
# Tokenizer Methods

#line 95

sub __TOKENIZER__on_char {
	my $class = shift;
	my $t     = shift;
	my $char  = substr( $t->{line}, $t->{line_cursor}, 1 );

	# Allow digits
	return 1 if $char =~ /\d/o;

	# Is this a second decimal point in a row?  Then the '..' operator
	if ( $char eq '.' ) {
		if ( $t->{token}->{content} =~ /\.$/ ) {
			# We have a .., which is an operator.
			# Take the . off the end of the token..
			# and finish it, then make the .. operator.
			chop $t->{token}->{content};
			$t->_new_token('Operator', '..');
			return 0;
		} else {
			return 1;
		}
	}

	# Doesn't fit a special case, or is after the end of the token
	# End of token.
	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

sub __TOKENIZER__commit {
	my $t = $_[1];

	# Get the rest of the line
	my $rest = substr( $t->{line}, $t->{line_cursor} );
	unless ( $rest =~ /^(v\d+(?:\.\d+)*)/ ) {
		# This was not a v-string after all (it's a word)
		return PPI::Token::Word->__TOKENIZER__commit($t);
	}

	# This is a v-string
	my $vstring = $1;
	$t->{line_cursor} += length($vstring);
	$t->_new_token('Number::Version', $vstring);
	$t->_finalize_token->__TOKENIZER__on_char($t);
}

1;

#line 171
