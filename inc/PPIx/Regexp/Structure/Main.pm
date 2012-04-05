#line 1
#line 34

package PPIx::Regexp::Structure::Main;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

our $VERSION = '0.026';

#line 52

sub delimiters {
    my ( $self ) = @_;
    my @delims;
    foreach my $method ( qw{ start finish } ) {
	push @delims, undef;
	defined ( my $obj = $self->$method() )
	    or next;
	defined ( my $str = $obj->content() )
	    or next;
	$delims[-1] = $str;
    }
    defined ( $delims[0] )
	or $delims[0] = $delims[1];
    return $delims[0] . $delims[1];
}

#line 76

sub interpolates {
    my ( $self ) = @_;
    my $finish = $self->finish( 0 ) or return 1;
    return q<'> ne $finish->content();
}

1;

__END__

#line 109

# ex: set textwidth=72 :
