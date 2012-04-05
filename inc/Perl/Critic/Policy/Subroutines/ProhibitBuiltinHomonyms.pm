#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Subroutines/ProhibitBuiltinHomonyms.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :data_conversion
                            :classification :characters };

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Array my @ALLOW => qw( import AUTOLOAD DESTROY );
Readonly::Hash my %ALLOW => hashify( @ALLOW );
Readonly::Scalar my $DESC  => q{Subroutine name is a homonym for builtin %s};
Readonly::Scalar my $EXPL  => [177];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                    }
sub default_severity     { return $SEVERITY_HIGH        }
sub default_themes       { return qw( core bugs pbp )   }
sub applies_to           { return 'PPI::Statement::Sub' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if $elem->isa('PPI::Statement::Scheduled'); #e.g. BEGIN, INIT, END
    return if exists $ALLOW{ $elem->name() };

    my $homonym_type = $EMPTY;
    if ( is_perl_builtin( $elem ) ) {
        $homonym_type = 'function';
    }
    elsif ( is_perl_bareword( $elem ) ) {
        $homonym_type = 'keyword';
    }
    else {
        return;    #ok!
    }

    my $desc = sprintf $DESC, $homonym_type;
    return $self->violation($desc, $EXPL, $elem);
}

1;

__END__

#-----------------------------------------------------------------------------

#line 121

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
