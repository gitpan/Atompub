#line 1
#line 29

package PPIx::Regexp::Structure::Capture;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

our $VERSION = '0.026';

#line 47

sub name {
    return;
}

#line 60

sub number {
    my ( $self ) = @_;
    return $self->{number};
}

# Called by the lexer to record the capture number.
sub __PPIX_LEXER__record_capture_number {
    my ( $self, $number ) = @_;
    $self->{number} = $number++;
    return $self->SUPER::__PPIX_LEXER__record_capture_number( $number );
}

1;

__END__

#line 99

# ex: set textwidth=72 :
