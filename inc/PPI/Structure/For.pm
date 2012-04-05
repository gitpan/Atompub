#line 1
package PPI::Structure::For;

#line 34

use strict;
use PPI::Structure ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Structure';
}

# Highly special custom isa method that will continue to respond
# positively to ->isa('PPI::Structure::ForLoop') but warns.
my $has_warned = 0;
sub isa {
	if ( $_[1] and $_[1] eq 'PPI::Structure::ForLoop' ) {
		unless ( $has_warned ) {
			warn("PPI::Structure::ForLoop has been deprecated");
			$has_warned = 1;
		}
		return 1;
	}
	return shift->SUPER::isa(@_);
}

1;

#line 81
