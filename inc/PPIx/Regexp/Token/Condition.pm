#line 1
#line 29

package PPIx::Regexp::Token::Condition;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::Reference };

use PPIx::Regexp::Constant qw{ RE_CAPTURE_NAME };

our $VERSION = '0.026';

sub perl_version_introduced {
    my ( $self ) = @_;
    $self->content() =~ m/ \A [(] \d+ [)] \z /smx
	and return '5.005';
    return '5.009005';
}

my @recognize = (
    [ qr{ \A \( (?: ( \d+ ) | R (\d+) ) \) }smx,
	{ is_named => 0 } ],
    [ qr{ \A \( R \) }smx,
	{ is_named => 0, capture => '0' } ],
    [ qr{ \A \( (?: < ( @{[ RE_CAPTURE_NAME ]} ) > |
	    ' ( @{[ RE_CAPTURE_NAME ]} ) ' |
	    R & ( @{[ RE_CAPTURE_NAME ]} ) ) \) }smxo,
	{ is_named => 1} ],
    [ qr{ \A \( DEFINE \) }smx,
	{ is_named => 0, capture => '0' } ],
);

# This must be implemented by tokens which do not recognize themselves.
# The return is a list of list references. Each list reference must
# contain a regular expression that recognizes the token, and optionally
# a reference to a hash to pass to make_token as the class-specific
# arguments. The regular expression MUST be anchored to the beginning of
# the string.
sub __PPIX_TOKEN__recognize {
    return @recognize;
}


# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    foreach ( @recognize ) {
	my ( $re, $arg ) = @{ $_ };
	my $accept = $tokenizer->find_regexp( $re ) or next;
	return $tokenizer->make_token( $accept, __PACKAGE__, $arg );
    }

    return;
}

1;

__END__

#line 113

# ex: set textwidth=72 :
