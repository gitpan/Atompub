#line 1
#line 31

package PPIx::Regexp::Token::Whitespace;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

our $VERSION = '0.026';

sub significant {
    return;
}

sub whitespace {
    return 1;
}

# Return true if the token can be quantified, and false otherwise
sub can_be_quantified { return };

# Objects of this class are generated either by the tokenizer itself
# (when scanning for delimiters) or by PPIx::Regexp::Token::Literal (if
# it hits a match for \s and finds the regular expression has the /x
# modifier asserted.

#line 69

1;

__END__

#line 96

# ex: set textwidth=72 :
