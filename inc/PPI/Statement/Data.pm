#line 1
package PPI::Statement::Data;

#line 41

use strict;
use PPI::Statement ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Statement';
}

# Data is never complete
sub _complete () { '' }

1;

#line 83
