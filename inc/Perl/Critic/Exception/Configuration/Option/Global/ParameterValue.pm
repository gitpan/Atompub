#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Exception/Configuration/Option/Global/ParameterValue.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Exception::Configuration::Option::Global::ParameterValue;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :characters };

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::Configuration::Option::Global::ParameterValue' => {
        isa         => 'Perl::Critic::Exception::Configuration::Option::Global',
        description => 'A problem with the value of a global parameter.',
        alias       => 'throw_global_value',
    },
);

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw< throw_global_value >;

#-----------------------------------------------------------------------------

sub full_message {
    my ( $self ) = @_;

    my $source = $self->source();
    if ($source) {
        $source = qq{ found in "$source"};
    }
    else {
        $source = $EMPTY;
    }

    my $option_name = $self->option_name();
    my $option_value =
        defined $self->option_value()
            ? $DQUOTE . $self->option_value() . $DQUOTE
            : '<undef>';
    my $message_suffix = $self->message_suffix() || $EMPTY;

    return
            qq{The value for the global "$option_name" option }
        .   qq{($option_value)$source $message_suffix};
}


1;

__END__

#-----------------------------------------------------------------------------

#line 129

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
