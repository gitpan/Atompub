#line 1
#line 28

package PPIx::Regexp::Structure::Quantifier;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

our $VERSION = '0.026';

sub can_be_quantified {
    return;
}

sub is_quantifier {
    return 1;
}

# Called by the lexer to record the capture number.
sub __PPIX_LEXER__record_capture_number {
    my ( $self, $number ) = @_;
    return $number;
}

1;

__END__

#line 78

# ex: set textwidth=72 :
