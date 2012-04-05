#line 1
#line 37

package PPIx::Regexp::Token::Code;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPI::Document;
use PPIx::Regexp::Util qw{ __instance };

our $VERSION = '0.026';

sub _new {
    my ( $class, $content ) = @_;
    ref $class and $class = ref $class;

    my $self = {};
    if ( __instance( $content, 'PPI::Document' ) ) {
	$self->{ppi} = $content;
    } elsif ( ref $content ) {
	return;
    } else {
	$self->{content} = $content;
    }
    bless $self, $class;
    return $self;
}

sub content {
    my ( $self ) = @_;
    if ( exists $self->{content} ) {
	return $self->{content};
    } elsif ( exists $self->{ppi} ) {
	return ( $self->{content} = $self->{ppi}->content() );
    } else {
	return;
    }
}

sub perl_version_introduced {
    my ( $self ) = @_;
    return $self->{perl_version_introduced};
}

#line 88

sub ppi {
    my ( $self ) = @_;
    if ( exists $self->{ppi} ) {
	return $self->{ppi};
    } elsif ( exists $self->{content} ) {
	return ( $self->{ppi} = PPI::Document->new(
		\($self->{content}), readonly => 1 ) );
    } else {
	return;
    }
}

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

{

    my %default = (
	perl_version_introduced	=> '5.005',	# When (?{...}) introduced.
    );

    sub __PPIX_TOKEN__post_make {
	my ( $self, $tokenizer, $arg ) = @_;

	if ( 'HASH' eq ref $arg ) {
	    foreach my $key ( qw{ perl_version_introduced } ) {
		exists $arg->{$key}
		    and $self->{$key} = $arg->{$key};
	    }
	}

	foreach my $key ( keys %default ) {
	    exists $self->{$key}
		or $self->{$key} = $default{$key};
	}

	return;
    }

}

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    $character eq '{' or return;

    my $offset = $tokenizer->find_matching_delimiter()
	or return;

    return $offset + 1;	# to include the closing delimiter.
}

1;

__END__

#line 167

# ex: set textwidth=72 :
