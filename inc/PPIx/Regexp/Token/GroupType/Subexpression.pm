#line 1
#line 28

package PPIx::Regexp::Token::GroupType::Subexpression;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::GroupType };

our $VERSION = '0.026';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

sub perl_version_introduced {
    my ( $self ) = @_;
    return '5.005';
}

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # The optional escapes are because any non-open-bracket character
    # may be the delimiter of the regular expression.
    if ( my $accept = $tokenizer->find_regexp(
	    qr{ \A \\? \? \\? > }smx ) ) {
	return $accept;
    }

    return;
}

1;

__END__

#line 85

# ex: set textwidth=72 :
