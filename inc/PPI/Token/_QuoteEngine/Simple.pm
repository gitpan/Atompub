#line 1
package PPI::Token::_QuoteEngine::Simple;

# Simple quote engine

use strict;
use PPI::Token::_QuoteEngine ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token::_QuoteEngine';
}

sub new {
	my $class     = shift;
	my $separator = shift or return undef;

	# Create a new token containing the separator
	### This manual SUPER'ing ONLY works because none of
	### Token::Quote, Token::QuoteLike and Token::Regexp
	### implement a new function of their own.
	my $self = PPI::Token::new( $class, $separator ) or return undef;
	$self->{separator} = $separator;

	$self;
}

sub _fill {
	my $class = shift;
	my $t     = shift;
	my $self  = $t->{token} or return undef;

	# Scan for the end separator
	my $string = $self->_scan_for_unescaped_character( $t, $self->{separator} );
	return undef unless defined $string;
	if ( ref $string ) {
		# End of file
		$self->{content} .= $$string;
		return 0;
	} else {
		# End of string
		$self->{content} .= $string;
		return $self;
	}
}

1;

#line 69
