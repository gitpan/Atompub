#line 1
#line 33

package PPIx::Regexp::Token::Reference;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use Carp qw{ confess };
use List::Util qw{ first };

our $VERSION = '0.026';

#line 55

sub absolute {
    my ( $self ) = @_;
    return $self->{absolute};
}

#line 68

sub is_named {
    my ( $self ) = @_;
    return $self->{is_named};
}

#line 83

sub is_relative {
    my ( $self ) = @_;
    return $self->{is_relative};
}

#line 98

sub name {
    my ( $self ) = @_;
    return $self->{name};
}

#line 113

sub number {
    my ( $self ) = @_;
    return $self->{number};
}

# Called by the lexer to record the capture number.
sub __PPIX_LEXER__record_capture_number {
    my ( $self, $number ) = @_;
    if ( ! exists $self->{absolute} && exists $self->{number}
	&& $self->{number} =~ m/ \A [-+] /smx ) {

	my $delta = $self->{number};
	$delta > 0 and --$delta;	# no -0 or +0.
	$self->{absolute} = $number + $delta;

    }
    return $number;
}

# Called after the token is manufactured. The calling sequence is
# $token->__PPIX_TOKEN__post_make( $tokenizer, $arg );
# For the sake of reblessing into this class, we are expected to deal
# with the situation where the optional argument is missing.
sub __PPIX_TOKEN__post_make {
    my ( $self, $tokenizer, $arg ) = @_;

    my $capture;
    if ( defined $arg ) {
	$tokenizer
	    and $capture = first { defined $_ } $tokenizer->capture();
	defined $capture or $capture = $arg->{capture};
    } else {
	my $content = $self->content();
	foreach ( $self->__PPIX_TOKEN__recognize() ) {
	    my ( $re, $a ) = @{ $_ };
	    $content =~ $re or next;
	    $arg = $a;
	    if ( exists $arg->{capture} ) {
		$capture = $arg->{capture};
	    } else {
		foreach my $inx ( 1 .. $#- ) {
		    defined $-[$inx] or next;
		    $capture = substr $content, $-[$inx], $+[$inx] - $-[$inx];
		    last;
		}
	    }
	    last;
	}
    }

    defined $capture
	or confess q{Programming error - reference '},
	    $self->content(), q{' of unknown form};

    foreach my $key ( keys %{ $arg } ) {
	$key eq 'capture' and next;
	$self->{$key} = $arg->{$key};
    }

    if ( $arg->{is_named} ) {
	$self->{absolute} = undef;
	$self->{is_relative} = undef;
	$self->{name} = $capture;
    } elsif ( $capture !~ m/ \A [-+] /smx ) {
	$self->{absolute} = $self->{number} = $capture;
	$self->{is_relative} = undef;
    } else {
	$self->{number} = $capture;
	$self->{is_relative} = 1;
    }

    return;
};


1;

__END__

#line 215

# ex: set textwidth=72 :
