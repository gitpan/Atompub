#line 1
#line 28

package PPIx::Regexp::Token::GroupType::Assertion;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::GroupType };

use PPIx::Regexp::Constant qw{ MINIMUM_PERL };

our $VERSION = '0.026';

{
    my %perl_version_introduced = (
	'?<='	=> '5.005',
	'?<!'	=> '5.005',
    );

    sub perl_version_introduced {
	my ( $self ) = @_;
	return $perl_version_introduced{ $self->content() } || MINIMUM_PERL;
    }
}

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # The actual expression being matched is \A \? <? [=!]. All the
    # optional escapes are because any of the non-open-bracket
    # punctuation characters may itself be escaped if it is also used to
    # quote the entire expression.
    if ( my $assert = $tokenizer->find_regexp(
	    qr{ \A \\? \? <? \\? [=!] }smx ) ) {
	return $assert;
    }

    return;
}

1;

__END__

#line 96

# ex: set textwidth=72 :
