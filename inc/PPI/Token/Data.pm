#line 1
package PPI::Token::Data;

#line 28

use strict;
use IO::String ();
use PPI::Token ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token';
}





#####################################################################
# Methods

#line 61

sub handle {
	my $self = shift;
	IO::String->new( \$self->{content} );
}

sub __TOKENIZER__on_char { 1 }

1;

#line 92
