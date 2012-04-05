#line 1
#line 30

package PPIx::Regexp::Structure::Regexp;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure::Main };

our $VERSION = '0.026';

sub can_be_quantified { return; }

#line 51

sub capture_names {
    my ( $self ) = @_;
    my %name;
    my $captures = $self->find(
	'PPIx::Regexp::Structure::NamedCapture')
	or return;
    foreach my $grab ( @{ $captures } ) {
	$name{$grab->name()}++;
    }
    return ( sort keys %name );
}

#line 73

sub max_capture_number {
    my ( $self ) = @_;
    return $self->{max_capture_number};
}

# Called by the lexer once it has done its worst to all the tokens.
# Called as a method with no arguments. The return is the number of
# parse failures discovered when finalizing.
sub __PPIX_LEXER__finalize {
    my ( $self ) = @_;
    my $rslt = 0;
    foreach my $elem ( $self->elements() ) {
	$rslt += $elem->__PPIX_LEXER__finalize();
    }

    # Calculate the maximum capture group, and number all the other
    # capture groups along the way.
    $self->{max_capture_number} =
	$self->__PPIX_LEXER__record_capture_number( 1 ) - 1;

    return $rslt;
}

1;

__END__

#line 123

# ex: set textwidth=72 :
