#line 1
#line 29

package PPIx::Regexp::Token::Quantifier;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

our $VERSION = '0.026';

# Return true if the token can be quantified, and false otherwise
sub can_be_quantified { return };

# Return true if the token is a quantifier.
sub is_quantifier { return 1 };

my %quantifier = map { $_ => 1 } qw{ * + ? };

#line 55

sub could_be_quantifier {
    my ( $class, $string ) = @_;
    return $quantifier{$string};
}

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    $tokenizer->prior( 'can_be_quantified' )
	or return;

    return $quantifier{$character};
}

1;

__END__

#line 96

# ex: set textwidth=72 :
