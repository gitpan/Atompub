#line 1
package PPI::Token::Regexp;

#line 43

use strict;
use PPI::Token ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token';
}





#####################################################################
# PPI::Token::Regexp Methods

#line 68

sub get_match_string {
	return $_[0]->_section_content( 0 );
}

#line 82

sub get_substitute_string {
	return $_[0]->_section_content( 1 );
}

#line 94

sub get_modifiers {
	return $_[0]->_modifiers();
}

#line 109

sub get_delimiters {
	return $_[0]->_delimiters();
}


1;

#line 138
