#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Exception/Configuration/Option/Global/ExtraParameter.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Exception::Configuration::Option::Global::ExtraParameter;

use 5.006001;
use strict;
use warnings;

use Readonly;

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::Configuration::Option::Global::ExtraParameter' => {
        isa         => 'Perl::Critic::Exception::Configuration::Option::Global',
        description => 'The configuration referred to a non-existant global option.',
        alias       => 'throw_extra_global',
    },
);

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw< throw_extra_global >;

#-----------------------------------------------------------------------------

sub full_message {
    my ( $self ) = @_;

    my $source = $self->source();
    if ($source) {
        $source = qq{ (found in "$source")};
    }
    else {
        $source = q{};
    }

    my $option_name = $self->option_name();

    return qq{"$option_name" is not a supported option$source.};
}


1;

__END__

#-----------------------------------------------------------------------------

#line 120

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
