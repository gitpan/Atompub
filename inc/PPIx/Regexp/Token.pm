#line 1
#line 44

package PPIx::Regexp::Token;

use strict;
use warnings;

use base qw{PPIx::Regexp::Element};

our $VERSION = '0.026';

sub _new {
    my ( $class, $content ) = @_;
    ref $class and $class = ref $class;

    my $self = {
	content => $content,
    };

    bless $self, $class;
    return $self;
}

sub content {
    my ( $self ) = @_;
    return $self->{content};
}


# Called after the token is manufactured. The calling sequence is
# $token->__PPIX_TOKEN__post_make( $tokenizer );
sub __PPIX_TOKEN__post_make { return };

# Called by the lexer once it has done its worst to all the tokens.
# Called as a method with no arguments. The return is the number of
# parse failures discovered when finalizing.
sub __PPIX_LEXER__finalize {
    return 0;
}

1;

__END__

#line 109

# ex: set textwidth=72 :
