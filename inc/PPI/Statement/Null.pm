#line 1
package PPI::Statement::Null;

#line 41

use strict;
use PPI::Statement ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Statement';
}

# A null statement is not significant
sub significant { '' }

1;

#line 77
