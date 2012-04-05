#line 1
#line 33

package PPIx::Regexp::Token::GroupType::NamedCapture;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::GroupType };

use Carp qw{ confess };

use PPIx::Regexp::Constant qw{ RE_CAPTURE_NAME };

our $VERSION = '0.026';

use constant NAMED_CAPTURE =>
    qr{ \A \\? \? (?: P? < ( @{[ RE_CAPTURE_NAME ]} ) \\? > |
		\\? ' ( @{[ RE_CAPTURE_NAME ]} ) \\? ' ) }smxo;

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

#line 59

sub name {
    my ( $self ) = @_;
    return $self->{name};
}

sub perl_version_introduced {
    return '5.009005';
}

sub __PPIX_TOKEN__post_make {
    my ( $self, $tokenizer ) = @_;
    if ( $tokenizer ) {
	foreach my $name ( $tokenizer->capture() ) {
	    defined $name or next;
	    $self->{name} = $name;
	    return;
	}
    } else {
	foreach my $name (
	    $self->content() =~ m/ @{[ NAMED_CAPTURE ]} /smxo ) {
	    defined $name or next;
	    $self->{name} = $name;
	    return;
	}
    }

    confess 'Programming error - can not figure out capture name';
}

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # The optional escapes are because any of the non-open-bracket
    # punctuation characters may be the expression delimiter.
    if ( my $accept = $tokenizer->find_regexp( NAMED_CAPTURE ) ) {
	return $accept;
    }

    return;
}

1;

__END__

#line 127

# ex: set textwidth=72 :
