#line 1
#line 30

package PPIx::Regexp::Token::Assertion;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPIx::Regexp::Constant qw{ COOKIE_CLASS MINIMUM_PERL TOKEN_LITERAL };

our $VERSION = '0.026';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

{

    my %perl_version_introduced = (
	'\\K' => '5.009005',
	'\\z' => '5.005',
    );

    sub perl_version_introduced {
	my ( $self ) = @_;
	return $perl_version_introduced{$self->content()} || MINIMUM_PERL;
    }

}

# By logic we should handle '$' here. But
# PPIx::Regexp::Token::Interpolation needs to process it to see if it is
# a sigil. If it is not, that module is expected to make it into an
# assertion. This is to try to keep the order in which the tokenizers
# are called non-critical, and try to keep all processing for a
# character in one place. Except for the back slash, which gets in
# everywhere.
#
## my %assertion = map { $_ => 1 } qw{ ^ $ };
my %assertion = map { $_ => 1 } qw{ ^ };
my %escaped = map { $_ => 1 } qw{ b B A Z z G K };

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # Inside a character class, these are all literals.
    my $make = $tokenizer->cookie( COOKIE_CLASS ) ?
	TOKEN_LITERAL :
	__PACKAGE__;

    # '^' and '$'. Or at least '^'. See note above for '$'.
    $assertion{$character}
	and return $tokenizer->make_token( 1, $make );

    $character eq '\\' or return;

    defined ( my $next = $tokenizer->peek( 1 ) ) or return;

    $escaped{$next}
	and return $tokenizer->make_token( 2, $make );

    return;
}

1;

__END__

#line 119

# ex: set textwidth=72 :
