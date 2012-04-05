#line 1
#line 27

package PPIx::Regexp::Token::Recursion;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::Reference };

use Carp qw{ confess };
use PPIx::Regexp::Constant qw{ RE_CAPTURE_NAME };

our $VERSION = '0.026';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

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
    return (
	[ qr{ \A \( \? (?: ( [-+]? \d+ )) \) }smx, { is_named => 0 } ],
	[ qr{ \A \( \? (?: R) \) }smx,
	    { is_named => 0, capture => '0' } ],
	[ qr{ \A \( \?  (?: & | P> ) ( @{[ RE_CAPTURE_NAME ]} ) \) }smxo,
	    { is_named => 1 } ],
    );
}

1;

__END__

#line 89

# ex: set textwidth=72 :
