#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Exception/Configuration/Option/Policy.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Exception::Configuration::Option::Policy;

use 5.006001;
use strict;
use warnings;

use Perl::Critic::Utils qw{ &policy_short_name };

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::Configuration::Option::Policy' => {
        isa         => 'Perl::Critic::Exception::Configuration::Option',
        description => 'A problem with the configuration of a policy.',
        fields      => [ qw{ policy } ],
    },
);

#-----------------------------------------------------------------------------

sub new {
    my ($class, %options) = @_;

    my $policy = $options{policy};
    if ($policy) {
        $options{policy} = policy_short_name($policy);
    }

    return $class->SUPER::new(%options);
}


1;

__END__

#-----------------------------------------------------------------------------

#line 95

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
