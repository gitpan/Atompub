#line 1
package PPI::Token::Operator;

#line 40

use strict;
use PPI::Token ();

use vars qw{$VERSION @ISA %OPERATOR};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token';

	# Build the operator index
	### NOTE - This is accessed several times explicitly
	###        in PPI::Token::Word. Do not rename this
	###        without also correcting them.
	%OPERATOR = map { $_ => 1 } (
		qw{
		-> ++ -- ** ! ~ + -
		=~ !~ * / % x . << >>
		< > <= >= lt gt le ge
		== != <=> eq ne cmp ~~
		& | ^ && || // .. ...
		? : = += -= *= .= /= //=
		=> <>
		and or xor not
		}, ',' 	# Avoids "comma in qw{}" warning
		);
}





#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_char {
	my $t    = $_[1];
	my $char = substr( $t->{line}, $t->{line_cursor}, 1 );

	# Are we still an operator if we add the next character
	my $content = $t->{token}->{content};
	return 1 if $OPERATOR{ $content . $char };

	# Handle the special case of a .1234 decimal number
	if ( $content eq '.' ) {
		if ( $char =~ /^[0-9]$/ ) {
			# This is a decimal number
			$t->{class} = $t->{token}->set_class('Number::Float');
			return $t->{class}->__TOKENIZER__on_char( $t );
		}
	}

	# Handle the special case if we might be a here-doc
	if ( $content eq '<<' ) {
		my $line = substr( $t->{line}, $t->{line_cursor} );
		# Either <<FOO or << 'FOO' or <<\FOO
		### Is the zero-width look-ahead assertion really
		### supposed to be there?
		if ( $line =~ /^(?: (?!\d)\w | \s*['"`] | \\\w ) /x ) {
			# This is a here-doc.
			# Change the class and move to the HereDoc's own __TOKENIZER__on_char method.
			$t->{class} = $t->{token}->set_class('HereDoc');
			return $t->{class}->__TOKENIZER__on_char( $t );
		}
	}

	# Handle the special case of the null Readline
	if ( $content eq '<>' ) {
		$t->{class} = $t->{token}->set_class('QuoteLike::Readline');
	}

	# Finalize normally
	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

1;

#line 137
