#line 1
package PPI::Token::Quote::Double;

#line 32

use strict;
use Params::Util                     qw{_INSTANCE};
use PPI::Token::Quote                ();
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
# PPI::Token::Quote::Double Methods

#line 87

# Upgrade: Return the interpolated substrings.
# Upgrade: Returns parsed expressions.
sub interpolations {
	# Are there any unescaped $things in the string
	!! ($_[0]->content =~ /(?<!\\)(?:\\\\)*[\$\@]/);
}

#line 132

sub simplify {
	# This only works on EXACTLY this class
	my $self = _INSTANCE(shift, 'PPI::Token::Quote::Double') or return undef;

	# Don't bother if there are characters that could complicate things
	my $content = $self->content;
	my $value   = substr($content, 1, length($content) - 2);
	return $self if $value =~ /[\\\$@\'\"]/;

	# Change the token to a single string
	$self->{content} = "'$value'";
	bless $self, 'PPI::Token::Quote::Single';
}







#####################################################################
# PPI::Token::Quote Methods

#line 169

sub string {
	my $str = $_[0]->{content};
	substr( $str, 1, length($str) - 2 );
}

1;

#line 198
