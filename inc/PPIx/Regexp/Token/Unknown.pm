#line 1
#line 31

package PPIx::Regexp::Token::Unknown;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

our $VERSION = '0.026';

# Return true if the token can be quantified, and false otherwise
sub can_be_quantified { return };

#line 52

sub ordinal {
    my ( $self ) = @_;
    return ord $self->content();
}

# Since the lexer does not count these on the way in (because it needs
# the liberty to rebless them into a known class if it figures out what
# is going on) we count them as failures at the finalization step.
sub __PPIX_LEXER__finalize {
    return 1;
}

1;

__END__

#line 91

# ex: set textwidth=72 :
