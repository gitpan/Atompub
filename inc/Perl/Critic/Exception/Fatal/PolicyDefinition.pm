#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Exception/Fatal/PolicyDefinition.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Exception::Fatal::PolicyDefinition;

use 5.006001;
use strict;
use warnings;

use Readonly;

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::Fatal::PolicyDefinition' => {
        isa         => 'Perl::Critic::Exception::Fatal',
        description => 'A bug in a policy was found.',
        alias       => 'throw_policy_definition',
    },
);

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw< throw_policy_definition >;

#-----------------------------------------------------------------------------


1;

__END__

#-----------------------------------------------------------------------------

#line 78

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
