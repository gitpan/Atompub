#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/InputOutput/ProhibitBarewordFileHandles.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Bareword file handle opened};
Readonly::Scalar my $EXPL => [ 202, 204 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity     { return $SEVERITY_HIGHEST   }
sub default_themes       { return qw( core pbp bugs ) }
sub applies_to           { return 'PPI::Token::Word'  }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    return if $elem ne 'open';
    return if ! is_function_call($elem);

    my $first_arg = ( parse_arg_list($elem) )[0];
    return if !$first_arg;
    my $first_token = $first_arg->[0];
    return if !$first_token;

    if ( $first_token->isa('PPI::Token::Word') ) {
        if ( ($first_token ne 'my') && ($first_token !~ m/^STD(?:IN|OUT|ERR)$/xms ) ) {
            return $self->violation( $DESC, $EXPL, $elem );
        }
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
