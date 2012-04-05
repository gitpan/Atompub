#line 1
package PPIx::Regexp::Util;

use 5.006;

use strict;
use warnings;

use Carp;
use Scalar::Util qw{ blessed };

use base qw{ Exporter };

our @EXPORT_OK = qw{ __instance };

our $VERSION = '0.026';

sub __instance {
    my ( $object, $class ) = @_;
    blessed( $object ) or return;
    return $object->isa( $class );
}

1;

__END__

#line 95

# ex: set textwidth=72 :
