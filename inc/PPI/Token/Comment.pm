#line 1
package PPI::Token::Comment;

#line 59

use strict;
use PPI::Token ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token';
}

### XS -> PPI/XS.xs:_PPI_Token_Comment__significant 0.900+
sub significant { '' }

# Most stuff goes through __TOKENIZER__commit.
# This is such a rare case, do char at a time to keep the code small
sub __TOKENIZER__on_char {
	my $t = $_[1];

	# Make sure not to include the trailing newline
	if ( substr( $t->{line}, $t->{line_cursor}, 1 ) eq "\n" ) {
		return $t->_finalize_token->__TOKENIZER__on_char( $t );
	}

	1;
}

sub __TOKENIZER__commit {
	my $t = $_[1];

	# Get the rest of the line
	my $rest = substr( $t->{line}, $t->{line_cursor} );
	if ( chomp $rest ) { # Include the newline separately
		# Add the current token, and the newline
		$t->_new_token('Comment', $rest);
		$t->_new_token('Whitespace', "\n");
	} else {
		# Add this token only
		$t->_new_token('Comment', $rest);
	}

	# Advance the line cursor to the end
	$t->{line_cursor} = $t->{line_length} - 1;

	0;
}

# Comments end at the end of the line
sub __TOKENIZER__on_line_end {
	$_[1]->_finalize_token if $_[1]->{token};
	1;
}

#line 119

sub line {
	# Entire line comments have a newline at the end
	$_[0]->{content} =~ /\n$/ ? 1 : 0;
}

1;

#line 148
