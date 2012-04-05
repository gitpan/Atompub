#line 1
package PPI::Token::Quote::Single;

#line 35

use strict;
use PPI::Token::Quote ();
use PPI::Token::_QuoteEngine::Simple ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = qw{
		PPI::Token::_QuoteEngine::Simple
		PPI::Token::Quote
	};
}





#####################################################################
# PPI::Token::Quote Methods

#line 69

sub string {
	my $str = $_[0]->{content};
	substr( $str, 1, length($str) - 2 );
}

#line 101

my %UNESCAPE = (
	"\\'"  => "'",
	"\\\\" => "\\",
);

sub literal {
	# Unescape \\ and \' ONLY
	my $str = $_[0]->string;
	$str =~ s/(\\.)/$UNESCAPE{$1} || $1/ge;
	return $str;
}

1;

#line 137
