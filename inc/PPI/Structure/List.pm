#line 1
package PPI::Structure::List;

#line 36

use strict;
use Carp           ();
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
		if (
			$_[0]->parent->isa('PPI::Statement::Compound')
			and
			$_[0]->parent->type =~ /^for/
		) {
			unless ( $has_warned ) {
				local $Carp::CarpLevel = $Carp::CarpLevel + 1;
				Carp::carp("PPI::Structure::ForLoop has been deprecated");
				$has_warned = 1;
			}
			return 1;
		}
	}
	return shift->SUPER::isa(@_);
}

1;

#line 91
