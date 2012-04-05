#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/PPIx-Utilities/lib/PPIx/Utilities/Exception/Bug.pm $
#     $Date: 2010-12-01 20:31:47 -0600 (Wed, 01 Dec 2010) $
#   $Author: clonezone $
# $Revision: 4001 $
##############################################################################

package PPIx::Utilities::Exception::Bug;

use 5.006001;
use strict;
use warnings;

our $VERSION = '1.001000';


use Exception::Class (
    'PPIx::Utilities::Exception::Bug' => {
        isa         => 'Exception::Class::Base',
        description => 'A bug in either PPIx::Utilities or PPI.',
    },
);


1;

__END__


#line 67

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
