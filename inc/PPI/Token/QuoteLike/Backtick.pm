#line 1
package PPI::Token::QuoteLike::Backtick;

#line 29

use strict;
use PPI::Token::QuoteLike            ();
use PPI::Token::_QuoteEngine::Simple ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = qw{
		PPI::Token::_QuoteEngine::Simple
		PPI::Token::QuoteLike
	};
}

1;

#line 66
