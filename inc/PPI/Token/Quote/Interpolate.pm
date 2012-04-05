#line 1
package PPI::Token::Quote::Interpolate;

#line 29

use strict;
use PPI::Token::Quote ();
use PPI::Token::_QuoteEngine::Full ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = qw{
		PPI::Token::_QuoteEngine::Full
		PPI::Token::Quote
	};
}





#####################################################################
# PPI::Token::Quote Methods

#line 68

sub string {
	my $self     = shift;
	my @sections = $self->_sections;
	my $str      = $sections[0];
	substr( $self->{content}, $str->{position}, $str->{size} );	
}

1;

#line 99
