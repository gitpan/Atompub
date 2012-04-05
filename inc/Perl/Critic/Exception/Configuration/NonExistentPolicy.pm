#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Exception/Configuration/NonExistentPolicy.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Exception::Configuration::NonExistentPolicy;

use 5.006001;
use strict;
use warnings;

use Readonly;

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::Configuration::NonExistentPolicy' => {
        isa         => 'Perl::Critic::Exception::Configuration',
        description => 'The configuration referred to a non-existant policy.',
        fields      => [ qw{ policy } ],
    },
);

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw< throw_extra_parameter >;

#-----------------------------------------------------------------------------

sub full_message {
    my ( $self ) = @_;

    my $policy = $self->policy();

    return qq<There is no $policy policy installed.>;
}


1;

__END__

#-----------------------------------------------------------------------------

#line 111

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
