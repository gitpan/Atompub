#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/BuiltinFunctions/ProhibitStringySplit.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::BuiltinFunctions::ProhibitStringySplit;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :characters :severities :classification :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{String delimiter used with "split"};
Readonly::Scalar my $EXPL => q{Express it as a regex instead};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                    }
sub default_severity     { return $SEVERITY_LOW         }
sub default_themes       { return qw(core pbp cosmetic) }
sub applies_to           { return 'PPI::Token::Word'    }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem ne 'split';
    return if ! is_function_call($elem);

    my @args = parse_arg_list($elem);
    my $pattern = @args ? $args[0]->[0] : return;

    if ( $pattern->isa('PPI::Token::Quote') && $pattern->string() ne $SPACE ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return;  #ok
}


1;

__END__

#-----------------------------------------------------------------------------

#line 111

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
