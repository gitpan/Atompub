#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/PolicyListing.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::PolicyListing;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Critic::Policy qw();

use overload ( q<""> => 'to_string' );

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    my $policies = $args{-policies} || [];
    $self->{_policies} = [ sort _by_type @{ $policies } ];

    return $self;
}

#-----------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    Perl::Critic::Policy::set_format( "%s %p [%t]\n" );

    return join q{}, map { "$_" } @{ $self->{_policies} };
}

#-----------------------------------------------------------------------------

sub _by_type { return ref $a cmp ref $b }

1;

__END__

#line 119

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
