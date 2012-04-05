#line 1
package PPI::Token::Prototype;

#line 47

use strict;
use PPI::Token ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token';
}

sub __TOKENIZER__on_char {
	my $class = shift;
	my $t     = shift;

	# Suck in until we find the closing bracket (or the end of line)
	my $line = substr( $t->{line}, $t->{line_cursor} );
	if ( $line =~ /^(.*?(?:\)|$))/ ) {
		$t->{token}->{content} .= $1;
		$t->{line_cursor} += length $1;
	}

	# Shortcut if end of line
	return 0 unless $1 =~ /\)$/;

	# Found the closing bracket
	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

#line 83

sub prototype {
	my $self  = shift;
	my $proto = $self->content;
	$proto =~ s/\(\)\s//g; # Strip brackets and whitespace
	$proto;
}

1;

#line 114
