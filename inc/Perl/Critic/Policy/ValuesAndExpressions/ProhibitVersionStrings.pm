#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ValuesAndExpressions/ProhibitVersionStrings.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitVersionStrings;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Version string used};
Readonly::Scalar my $EXPL => q{Use a real number instead};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                        }
sub default_severity     { return $SEVERITY_MEDIUM          }
sub default_themes       { return qw(core pbp maintenance)  }
sub applies_to           { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    my $version;

    if ( my $module = $elem->module() ) {
        return if $module eq 'lib';

        $version = $elem->module_version();
    } else {
        $version = $elem->schild(1);
    }

    return if not defined $version;
    return if not $version->isa('PPI::Token::Number::Version');

    return $self->violation($DESC, $EXPL, $elem);
}

1;

__END__

#-----------------------------------------------------------------------------

#line 103

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
