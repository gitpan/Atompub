#line 1
package PPI::Statement::Include::Perl6;

#line 39

use strict;
use PPI::Statement::Include ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Statement::Include';
}

#line 57

sub perl6 {
	$_[0]->{perl6};
}

1;

#line 89
