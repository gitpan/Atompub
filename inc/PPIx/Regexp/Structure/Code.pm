#line 1
#line 33

package PPIx::Regexp::Structure::Code;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

use Carp qw{ cluck };
use PPIx::Regexp::Constant qw{ STRUCTURE_UNKNOWN TOKEN_UNKNOWN };

our $VERSION = '0.026';

# The only child of this structure should be a single
# PPIx::Regexp::Token::Code. Anything else gets turned into the
# appropriate ::Unknown object.
sub __PPIX_LEXER__finalize {
    my ( $self ) = @_;

    my $count;
    my $errors = 0;

    foreach my $kid ( $self->children() ) {

	$kid->isa( 'PPIx::Regexp::Token::Code' )
	    and not $count++
	    and next;

	$errors++;

	if ( $kid->isa( 'PPIx::Regexp::Token' ) ) {
	    bless $kid, TOKEN_UNKNOWN;
	} elsif ( $kid->isa( 'PPIx::Regexp::Structure' ) ) {
	    bless $kid, STRUCTURE_UNKNOWN;
	} else {
	    cluck( 'Programming error - unexpected element of class ',
		ref $kid, ' found in a PPIx::Regexp::Structure::Code. ',
		'Please contact the author' );
	}

    }
    return $errors;
}

1;

__END__

#line 103

# ex: set textwidth=72 :
