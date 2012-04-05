#line 1
#line 33

package PPIx::Regexp::Structure::NamedCapture;

use strict;
use warnings;

use Carp;

use base qw{ PPIx::Regexp::Structure::Capture };

our $VERSION = '0.026';

#line 52

sub name {
    my ( $self ) = @_;
    my $type = $self->type()
	or croak 'Programming error - ', __PACKAGE__, ' without type object';
    return $type->name();
}

1;

__END__

#line 86

# ex: set textwidth=72 :
