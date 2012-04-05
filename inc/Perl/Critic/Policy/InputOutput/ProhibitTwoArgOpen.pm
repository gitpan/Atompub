#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/InputOutput/ProhibitTwoArgOpen.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::InputOutput::ProhibitTwoArgOpen;

use 5.006001;
use strict;
use warnings;

use Readonly;

use version;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $STDIO_HANDLES_RX => qr/\b STD (?: IN | OUT | ERR \b)/xms;
Readonly::Scalar my $FORK_HANDLES_RX => qr/\A (?: -[|] | [|]- ) \z/xms;
Readonly::Scalar my $DESC => q{Two-argument "open" used};
Readonly::Scalar my $EXPL => [ 207 ];

Readonly::Scalar my $MINIMUM_VERSION => version->new(5.006);

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_HIGHEST          }
sub default_themes       { return qw(core pbp bugs security) }
sub applies_to           { return 'PPI::Token::Word'         }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $document) = @_;

    return if $elem ne 'open';
    return if ! is_function_call($elem);

    my $version = $document->highest_explicit_perl_version();
    return if $version and $version < $MINIMUM_VERSION;

    my @args = parse_arg_list($elem);

    if ( scalar @args == 2 ) {
        # When opening STDIN, STDOUT, or STDERR, the
        # two-arg form is the only option you have.
        return if $args[1]->[0] =~ $STDIO_HANDLES_RX;
        return if $args[1]->[0]->isa( 'PPI::Token::Quote' )
               && $args[1]->[0]->string() =~ $FORK_HANDLES_RX;
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return; # ok!
}

1;

__END__

#-----------------------------------------------------------------------------

#line 137

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
