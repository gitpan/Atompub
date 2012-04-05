#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Utils/DataConversion.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Utils::DataConversion;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :characters :booleans };

use base 'Exporter';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw(
    boolean_to_number
    dor
    defined_or_empty
);

#-----------------------------------------------------------------------------

sub boolean_to_number {  ## no critic (RequireArgUnpacking)
    return $_[0] ? $TRUE : $FALSE;
}

#-----------------------------------------------------------------------------

sub dor {  ## no critic (RequireArgUnpacking)
    foreach (@_) {
        defined $_ and return $_;
    }
    return;
}

#-----------------------------------------------------------------------------

sub defined_or_empty {  ## no critic (RequireArgUnpacking)
    return defined $_[0] ? $_[0] : $EMPTY;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 117

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
