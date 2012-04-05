#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/InputOutput/ProhibitJoinedReadline.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::InputOutput::ProhibitJoinedReadline;

use 5.006001;
use strict;
use warnings;
use Readonly;
use List::MoreUtils qw(any);

use Perl::Critic::Utils qw{ :severities :classification parse_arg_list };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Use "local $/ = undef" or File::Slurp instead of joined readline}; ## no critic qw(InterpolationOfMetachars)
Readonly::Scalar my $EXPL => [213];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                     }
sub default_severity     { return $SEVERITY_MEDIUM       }
sub default_themes       { return qw( core pbp performance ) }
sub applies_to           { return 'PPI::Token::Word'     }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem ne 'join';
    return if ! is_function_call($elem);
    my @args = parse_arg_list($elem);
    shift @args; # ignore separator string

    if (any { any { $_->isa('PPI::Token::QuoteLike::Readline') } @{$_} } @args) {
       return $self->violation( $DESC, $EXPL, $elem );
    }

    return;  # OK
}


1;

__END__

#-----------------------------------------------------------------------------

#line 124

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
