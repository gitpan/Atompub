#line 1
package PPI::Document::Fragment;

#line 19

use strict;
use PPI::Document ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Document';
}





#####################################################################
# PPI::Document Methods

#line 46

# There's no point indexing a fragment
sub index_locations {
	warn "Useless attempt to index the locations of a document fragment";
	undef;
}





#####################################################################
# PPI::Element Methods

# We are not a scope boundary
### XS -> PPI/XS.xs:_PPI_Document_Fragment__scope 0.903+
sub scope { '' }

1;

#line 92
