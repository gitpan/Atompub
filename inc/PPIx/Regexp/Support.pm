#line 1
#line 31

package PPIx::Regexp::Support;

use strict;
use warnings;

use PPIx::Regexp::Util qw{ __instance };

our $VERSION = '0.026';

#line 49

{
    my %bracket = (
	'(' => ')',
	'{' => '}',
	'<' => '>',
	'[' => ']',
    );

    sub close_bracket {
	my ( $self, $char ) = @_;
	defined $char or return;
	__instance( $char, 'PPIx::Regexp::Element' )
	    and $char = $char->content();
	return $bracket{$char};
    }

}

#line 75

sub decode {
    my ( $self, $data ) = @_;
    defined $self->{encoding} or return $data;
    encode_available() or return $data;
    return Encode::decode( $self->{encoding}, $data );
}

#line 90

sub encode {
    my ( $self, $data ) = @_;
    defined $self->{encoding} or return $data;
    encode_available() or return $data;
    return Encode::encode( $self->{encoding}, $data );
}

#line 105

{

    my $encode_available;

    sub encode_available {
	defined $encode_available and return $encode_available;
	return ( $encode_available = eval {
		require Encode;
		1;
	    } ? 1 : 0
	);
    }

}

# This method is to be used only by the PPIx::Regexp package. It returns
# the first of its arguments which is defined. It will go away when
# (or if!) these modules get 'use 5.010;' at the top.

sub _defined_or {
    my ( $self, @args ) = @_;
    foreach my $arg ( @args ) {
	defined $arg and return $arg;
    }
    return;
}

1;

__END__

#line 159

# ex: set textwidth=72 :
