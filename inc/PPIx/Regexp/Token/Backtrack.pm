#line 1
#line 27

package PPIx::Regexp::Token::Backtrack;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

our $VERSION = '0.026';

# Return true if the token can be quantified, and false otherwise
sub can_be_quantified { return };

sub perl_version_introduced {
    return '5.009005';
}

# This must be implemented by tokens which do not recognize themselves.
# The return is a list of list references. Each list reference must
# contain a regular expression that recognizes the token, and optionally
# a reference to a hash to pass to make_token as the class-specific
# arguments. The regular expression MUST be anchored to the beginning of
# the string.
sub __PPIX_TOKEN__recognize {
    return ( [ qr{ \A \( \* [^\)]* \) }smx ] );
}

# This class gets recognized by PPIx::Regexp::Token::Structure as part
# of its left parenthesis processing.

#line 68

1;

__END__

#line 95

# ex: set textwidth=72 :
