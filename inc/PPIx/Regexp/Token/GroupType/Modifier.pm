#line 1
#line 30

package PPIx::Regexp::Token::GroupType::Modifier;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::Modifier PPIx::Regexp::Token::GroupType };

use PPIx::Regexp::Constant qw{ MINIMUM_PERL };

our $VERSION = '0.026';

{

    my %perl_version_introduced = (
	'?:'	=> MINIMUM_PERL,
    );

    sub perl_version_introduced {
	my ( $self ) = @_;
	my $content = $self->content();
	exists $perl_version_introduced{$content}
	    and return $perl_version_introduced{$content};
	my $ver = $self->SUPER::perl_version_introduced();
	$ver > 5.005 and return $ver;
	return '5.005';
    }

}

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character, $char_type ) = @_;

    # Note that the optional escapes are because any of the
    # non-open-bracket punctuation characters might be our delimiter.
    my $accept;
    $accept = $tokenizer->find_regexp(
	qr{ \A \\? [?] [[:lower:]]* \\? -? [[:lower:]]* \\? : }smx )
	and return $accept;
    $accept = $tokenizer->find_regexp(
	qr{ \A \\? [?] \^ [[:lower:]]* \\? : }smx )
	and return $accept;

    return;
}

1;

__END__

#line 105

# ex: set textwidth=72 :
