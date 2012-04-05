#line 1
package PPI::Statement::UnmatchedBrace;

#line 45

use strict;
use PPI::Statement ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Statement';
}

# Once we've hit a naked unmatched brace we can never truly be complete.
# So instead we always just call it a day...
sub _complete () { 1 }

1;

#line 82
