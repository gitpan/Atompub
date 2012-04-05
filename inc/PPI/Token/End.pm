#line 1
package PPI::Token::End;

#line 41

use strict;
use PPI::Token ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token';
}





#####################################################################
# Tokenizer Methods

### XS -> PPI/XS.xs:_PPI_Token_End__significant 0.900+
sub significant { '' }

sub __TOKENIZER__on_char { 1 }

sub __TOKENIZER__on_line_start {
	my $t = $_[1];

	# Can we classify the entire line in one go
	if ( $t->{line} =~ /^=(\w+)/ ) {
		# A Pod tag... change to pod mode
		$t->_new_token( 'Pod', $t->{line} );
		unless ( $1 eq 'cut' ) {
			# Normal start to pod
			$t->{class} = 'PPI::Token::Pod';
		}

		# This is an error, but one we'll ignore
		# Don't go into Pod mode, since =cut normally
		# signals the end of Pod mode
	} else {
		if ( defined $t->{token} ) {
			# Add to existing token
			$t->{token}->{content} .= $t->{line};
		} else {
			$t->_new_token( 'End', $t->{line} );
		}
	}

	0;
}

1;

#line 113
