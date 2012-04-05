#line 1
package PPI::Statement::End;

#line 45

use strict;
use PPI::Statement ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Statement';
}

# Once we have an __END__ we're done
sub _complete () { 1 }

1;

#line 81
