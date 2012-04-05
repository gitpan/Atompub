#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Exception/Configuration/Option.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Exception::Configuration::Option;

use 5.006001;
use strict;
use warnings;

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

use Perl::Critic::Exception::Fatal::Internal;

use Exception::Class (   # this must come after "use P::C::Exception::*"
    'Perl::Critic::Exception::Configuration::Option' => {
        isa         => 'Perl::Critic::Exception::Configuration',
        description => 'A problem with an option in the Perl::Critic configuration, whether from a file or a command line or some other source.',
        fields      => [ qw{ option_name option_value message_suffix } ],
    },
);

#-----------------------------------------------------------------------------

sub message {
    my $self = shift;

    return $self->full_message();
}

#-----------------------------------------------------------------------------

sub error {
    my $self = shift;

    return $self->full_message();
}

#-----------------------------------------------------------------------------

## no critic (Subroutines::RequireFinalReturn)
sub full_message {
    Perl::Critic::Exception::Fatal::Internal->throw(
        'Subclass failed to override abstract method.'
    );
}
## use critic


1;

__END__

#-----------------------------------------------------------------------------

#line 139

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
