#line 1
package PPI::Statement::Unknown;

#line 33

use strict;
use PPI::Statement ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Statement';
}

# If one of these ends up in the final document,
# we're pretty much screwed. Just call it a day.
sub _complete () { 1 }

1;

#line 70
