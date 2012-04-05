#line 1
#line 33

package PPIx::Regexp::Token::CharClass;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

our $VERSION = '0.026';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

##=head2 is_case_sensitive
##
##This method returns true if the character class is case-sensitive (that
##is, if it may match or not based on the case of the string being
##matched), false (but defined) if it is not, and simply returns (giving
##C<undef> in scalar context and an empty list in list context) if the
##case-sensitivity can not be determined.
##
##=cut
##
##sub is_case_sensitive {
##    return;
##}

1;

__END__

#line 86

# ex: set textwidth=72 :
