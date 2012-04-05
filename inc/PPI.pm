#line 1
package PPI;

# See POD at end for documentation

use 5.006;
use strict;

# Set the version for CPAN
use vars qw{$VERSION $XS_COMPATIBLE @XS_EXCLUDE};
BEGIN {
	$VERSION       = '1.215';
	$XS_COMPATIBLE = '0.845';
	@XS_EXCLUDE    = ();
}

# Load everything
use PPI::Util                 ();
use PPI::Exception            ();
use PPI::Element              ();
use PPI::Token                ();
use PPI::Statement            ();
use PPI::Structure            ();
use PPI::Document             ();
use PPI::Document::File       ();
use PPI::Document::Fragment   ();
use PPI::Document::Normalized ();
use PPI::Normal               ();
use PPI::Tokenizer            ();
use PPI::Lexer                ();

# If it is installed, load in PPI::XS
unless ( $PPI::XS_DISABLE ) {
	eval { require PPI::XS };
	# Only ignore the failure to load PPI::XS if not installed
	die if $@ && $@ !~ /^Can't locate .*? at /;
}

1;

__END__

#line 846
