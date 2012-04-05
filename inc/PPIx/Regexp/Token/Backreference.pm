#line 1
#line 28

package PPIx::Regexp::Token::Backreference;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::Reference };

use Carp qw{ confess };
use PPIx::Regexp::Constant qw{ MINIMUM_PERL RE_CAPTURE_NAME };

our $VERSION = '0.026';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

{

    my %perl_version_introduced = (
	g => '5.009005',	# \g1 \g-1 \g{1} \g{-1}
	k => '5.009005',	# \k<name> \k'name'
	'?' => '5.009005',	# (?P=name)	(PCRE/Python)
    );

    sub perl_version_introduced {
	my ( $self ) = @_;
	return $perl_version_introduced{substr( $self->content(), 1, 1 )} ||
	    MINIMUM_PERL;
    }

}

my @external = (	# Recognition used externally
    [ qr{ \A \( \? P = ( @{[ RE_CAPTURE_NAME ]} ) \) }smxo,
	{ is_named => 1 },
	],
);

my @recognize = (	# recognition used internally
    [
	qr{ \A \\ (?:		# numbered (including relative)
	    ( \d+ )	|
	    g (?: ( -? \d+ ) | \{ ( -? \d+ ) \} )
	)
	}smx, { is_named => 0 }, ],
    [
	qr{ \A \\ (?:		# named
	    g \{ ( @{[ RE_CAPTURE_NAME ]} ) \} |
	    k (?: \< ( @{[ RE_CAPTURE_NAME ]} ) \> |	# named with angles
		' ( @{[ RE_CAPTURE_NAME ]} ) ' )	#   or quotes
	)
	}smxo, { is_named => 1 }, ],
);

# This must be implemented by tokens which do not recognize themselves.
# The return is a list of list references. Each list reference must
# contain a regular expression that recognizes the token, and optionally
# a reference to a hash to pass to make_token as the class-specific
# arguments. The regular expression MUST be anchored to the beginning of
# the string.
sub __PPIX_TOKEN__recognize {
    return __PACKAGE__->isa( scalar caller ) ?
	( @external, @recognize ) :
	( @external );
}

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # PCRE/Python back references are handled in
    # PPIx::Regexp::Token::Structure, because they are parenthesized.

    # All the other styles are escaped.
    $character eq '\\'
	or return;

    foreach ( @recognize ) {
	my ( $re, $arg ) = @{ $_ };
	my $accept = $tokenizer->find_regexp( $re ) or next;
	return $tokenizer->make_token( $accept, __PACKAGE__, $arg );
    }

    return;
}

sub __PPIX_TOKENIZER__repl {
    my ( $class, $tokenizer, $character ) = @_;

    $tokenizer->interpolates() and goto &__PPIX_TOKENIZER__regexp;

    return;
}

1;

__END__

#line 147

# ex: set textwidth=72 :
