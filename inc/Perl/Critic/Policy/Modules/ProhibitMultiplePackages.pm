#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Modules/ProhibitMultiplePackages.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Modules::ProhibitMultiplePackages;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC   => q{Multiple "package" declarations};
Readonly::Scalar my $EXPL   => q{Limit to one per file};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()              }
sub default_severity     { return $SEVERITY_HIGH  }
sub default_themes       { return qw( core bugs ) }
sub applies_to           { return 'PPI::Document' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    my $nodes_ref = $doc->find('PPI::Statement::Package');
    return if !$nodes_ref;
    my @matches = @{$nodes_ref} > 1 ? @{$nodes_ref}[ 1 .. $#{$nodes_ref} ] :();

    return map {$self->violation($DESC, $EXPL, $_)} @matches;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 89

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
