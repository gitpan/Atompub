#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Utils/Perl.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Utils::Perl;

use 5.006001;
use strict;
use warnings;

use base 'Exporter';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw(
    symbol_without_sigil
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#-----------------------------------------------------------------------------

sub symbol_without_sigil {
    my ($symbol) = @_;

    (my $without_sigil = $symbol) =~ s< \A [\$@%*&] ><>xms;

    return $without_sigil;
}

#-----------------------------------------------------------------------------

1;

__END__

#line 98

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
