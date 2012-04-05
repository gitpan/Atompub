#line 1
#line 28

package PPIx::Regexp::Structure::BranchReset;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

use Carp qw{ confess };

our $VERSION = '0.026';

# Called by the lexer to record the capture number.
sub __PPIX_LEXER__record_capture_number {
    my ( $self, $number ) = @_;
    defined $number
	or confess 'Programming error - initial $number is undef';
    my $original = $number;
    my $hiwater = $number;
    foreach my $kid ( $self->children() ) {
	if ( $kid->isa( 'PPIx::Regexp::Token::Operator' )
	    && $kid->content() eq '|' ) {
	    $number > $hiwater and $hiwater = $number;
	    $number = $original;
	} else {
	    $number = $kid->__PPIX_LEXER__record_capture_number( $number );
	}
    }
    return $number > $hiwater ? $number : $hiwater;
}

1;

__END__

#line 85

# ex: set textwidth=72 :
