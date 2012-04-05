#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/BuiltinFunctions/ProhibitSleepViaSelect.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::BuiltinFunctions::ProhibitSleepViaSelect;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{"select" used to emulate "sleep"};
Readonly::Scalar my $EXPL => [168];
Readonly::Scalar my $SELECT_ARGUMENT_COUNT => 4;

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity     { return $SEVERITY_HIGHEST   }
sub default_themes       { return qw( core pbp bugs ) }
sub applies_to           { return 'PPI::Token::Word'  }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    return if ($elem ne 'select');
    return if ! is_function_call($elem);

    my @arguments = parse_arg_list($elem);
    return if $SELECT_ARGUMENT_COUNT != @arguments;

    foreach my $argument ( @arguments[0..2] ) {
        return if $argument->[0] ne 'undef';
    }

    if ( $arguments[-1]->[0] ne 'undef' ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return; #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

#line 112

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
