#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/PolicyParameter/Behavior/Boolean.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::PolicyParameter::Behavior::Boolean;

use 5.006001;
use strict;
use warnings;
use Perl::Critic::Utils;

use base qw{ Perl::Critic::PolicyParameter::Behavior };

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

sub _parse {
    my ($policy, $parameter, $config_string) = @_;

    my $value;
    my $value_string = $parameter->get_default_string();

    if (defined $config_string) {
        $value_string = $config_string;
    }

    if ( $value_string ) {
        $value = $TRUE;
    } else {
        $value = $FALSE;
    }

    $policy->__set_parameter_value($parameter, $value);

    return;
}

#-----------------------------------------------------------------------------

sub initialize_parameter {
    my ($self, $parameter, $specification) = @_;

    $parameter->_set_parser(\&_parse);

    return;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

#line 112

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
