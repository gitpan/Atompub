#line 1
#line 28

package PPIx::Regexp::Token::GroupType::BranchReset;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::GroupType };

our $VERSION = '0.026';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

sub perl_version_introduced {
    return '5.009005';
}

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # The actual expression being matched it \A \? \|. The extra
    # optional escapes are because any of the non-open-bracket
    # punctuation characters may also be the delimiter.
    if ( my $accept = $tokenizer->find_regexp(
	    qr{ \A \\? \? \\? \| }smx ) ) {
	return $accept;
    }

    return;
}

1;

__END__

#line 85

# ex: set textwidth=72 :
