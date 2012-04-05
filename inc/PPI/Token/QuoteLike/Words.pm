#line 1
package PPI::Token::QuoteLike::Words;

#line 26

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

#line 93

sub literal {
	my $self    = shift;
	my $section = $self->{sections}->[0];
	return split ' ', substr(
		$self->{content},
		$section->{position},
		$section->{size},
	);
}

1;

#line 127
