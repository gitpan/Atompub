#line 1
#line 29

package PPIx::Regexp::Token::GroupType::Switch;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::GroupType };

our $VERSION = '0.026';

sub perl_version_introduced {
#   my ( $self ) = @_;
    return '5.005';
}

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # The optional escape is because any non-open-bracket character may
    # appear as the regular expression delimiter.
    if ( my $accept = $tokenizer->find_regexp(
	    qr{ \A \\? \? \( }smx ) ) {

	# Leave the left paren, since it belongs to the condition.
	--$accept;

	$tokenizer->expect( qw{
	    PPIx::Regexp::Token::Condition
	    } );

	return $accept;

    }

    return;

}

1;

__END__

#line 96

# ex: set textwidth=72 :
