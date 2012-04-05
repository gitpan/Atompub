#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/InputOutput/RequireEncodingWithUTF8Layer.pm $
#     $Date: 2010-06-22 16:14:07 -0400 (Tue, 22 Jun 2010) $
#   $Author: clonezone $
# $Revision: 3843 $
##############################################################################

package Perl::Critic::Policy::InputOutput::RequireEncodingWithUTF8Layer;

use 5.006001;
use strict;
use warnings;

use Readonly;

use version;

use Perl::Critic::Utils qw{ :severities :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{I/O layer ":utf8" used};
Readonly::Scalar my $EXPL => q{Use ":encoding(UTF-8)" to get strict validation};

Readonly::Scalar my $THREE_ARGUMENT_OPEN => 3;
Readonly::Hash   my %RECOVER_ENCODING => (
    binmode => \&_recover_binmode_encoding,
    open => \&_recover_open_encoding,
);

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_HIGHEST          }
sub default_themes       { return qw(core bugs security) }
sub applies_to           { return 'PPI::Token::Word'         }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $document) = @_;

    my $handler = $RECOVER_ENCODING{ $elem->content() }
        or return;  # If we don't have a handler, we're not interested.
    my $encoding = $handler->( parse_arg_list( $elem ) )
        or return;  # If we can't recover an encoding, we give up.
    return if $encoding !~ m/ (?: \A | : ) utf8 \b /smxi;   # OK

    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

# my $string = _get_argument_string( $arg[1] );
#
# This subroutine returns the string from the given argument (which must
# be a reference to an array of PPI objects), _PROVIDED_ the array
# contains a single PPI::Token::Quote object. Otherwise it simply
# returns, since we're too stupid to analyze anything else.

sub _get_argument_string {
    my ( $arg ) = @_;
    ref $arg eq 'ARRAY' or return;
    return if @{ $arg } == 0 || @{ $arg } > 1;
    return $arg->[0]->string() if $arg->[0]->isa( 'PPI::Token::Quote' );
    return;
}

#-----------------------------------------------------------------------------

# my $encoding = _recover_binmode_encoding( _parse_arg_list( $elem ) );
#
# This subroutine returns the encoding specified by the given $elem,
# which _MUST_ be the 'binmode' of a binmode() call.

sub _recover_binmode_encoding {
    my ( @args ) = @_;
    return _get_argument_string( $args[1] );
}

#-----------------------------------------------------------------------------

# my $encoding = _recover_open_encoding( _parse_arg_list( $elem ) );
#
# This subroutine returns the encoding specified by the given $elem,
# which _MUST_ be the 'open' of a open() call.

sub _recover_open_encoding {
    my ( @args ) = @_;
    @args < $THREE_ARGUMENT_OPEN
        and return;
    defined( my $string = _get_argument_string( $args[1] ) )
        or return;
    $string =~ s/ [+]? (?: < | >{1,2} ) //smx;
    return $string;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 187

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
