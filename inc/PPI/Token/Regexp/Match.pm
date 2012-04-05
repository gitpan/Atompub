#line 1
package PPI::Token::Regexp::Match;

#line 43

use strict;
use PPI::Token::Regexp             ();
use PPI::Token::_QuoteEngine::Full ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = qw{
		PPI::Token::_QuoteEngine::Full
		PPI::Token::Regexp
	};
}

1;

#line 80
