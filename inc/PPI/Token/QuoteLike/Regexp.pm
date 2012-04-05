#line 1
package PPI::Token::QuoteLike::Regexp;

#line 30

use strict;
use PPI::Token::QuoteLike          ();
use PPI::Token::_QuoteEngine::Full ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = qw{
		PPI::Token::_QuoteEngine::Full
		PPI::Token::QuoteLike
	};
}





#####################################################################
# PPI::Token::QuoteLike::Regexp Methods

#line 59

sub get_match_string {
	return $_[0]->_section_content( 0 );
}

#line 73

sub get_substitute_string {
	return undef;
}

#line 86

sub get_modifiers {
	return $_[0]->_modifiers();
}

#line 100

sub get_delimiters {
	return $_[0]->_delimiters();
}

1;

#line 128
