#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/ThemeListing.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::ThemeListing;

use 5.006001;
use strict;
use warnings;

use English qw<-no_match_vars>;

use Perl::Critic::Utils qw< hashify >;

use overload ( q<""> => 'to_string' );

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    $self->{_policies} = $args{-policies} || [];

    return $self;
}

#-----------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    my %themes;
    foreach my $policy ( @{ $self->{_policies} } ) {
        my @themes = $policy->get_themes();
        @themes{ @themes } = @themes;
    }

    return join ("\n", sort keys %themes) . "\n";
}

#-----------------------------------------------------------------------------

1;

__END__

#line 122

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
