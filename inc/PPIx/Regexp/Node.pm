#line 1
#line 30

package PPIx::Regexp::Node;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Element };

use List::Util qw{ max };
use PPIx::Regexp::Constant qw{ MINIMUM_PERL };
use PPIx::Regexp::Util qw{ __instance };
use Scalar::Util qw{ refaddr };

our $VERSION = '0.026';

sub _new {
    my ( $class, @children ) = @_;
    ref $class and $class = ref $class;
    foreach my $elem ( @children ) {
	__instance( $elem, 'PPIx::Regexp::Element' ) or return;
    }
    my $self = {
	children => \@children,
    };
    bless $self, $class;
    foreach my $elem ( @children ) {
	$elem->_parent( $self );
    }
    return $self;
}

#line 70

sub child {
    my ( $self, $inx ) = @_;
    defined $inx or $inx = 0;
    return $self->{children}[$inx];
}

#line 83

sub children {
    my ( $self ) = @_;
    return @{ $self->{children} };
}

#line 97

sub contains {
    my ( $self, $elem ) = @_;
    __instance( $elem, 'PPIx::Regexp::Element' ) or return;

    my $addr = refaddr( $self );

    while ( $elem = $elem->parent() ) {
	$addr == refaddr( $elem ) and return 1;
    }

    return;
}

sub content {
    my ( $self ) = @_;
    return join( '', map{ $_->content() } $self->elements() );
}

#line 122

{
    no warnings qw{ once };
    *elements = \&children;
}

#line 154

sub _find_routine {
    my ( $want ) = @_;
    ref $want eq 'CODE' and return $want;
    ref $want and return;
    $want =~ m/ \A PPIx::Regexp:: /smx
	or $want = 'PPIx::Regexp::' . $want;
    return sub {
	return __instance( $_[1], $want ) ? 1 : 0;
    };
}

sub find {
    my ( $self, $want ) = @_;

    $want = _find_routine( $want ) or return;

    my @found;

    # We use a recursion to find what we want. PPI::Node uses an
    # iteration.
    foreach my $elem ( $self->elements() ) {
	my $rslt = eval { $want->( $self, $elem ) }
	    and push @found, $elem;
	$@ and return;

	__instance( $elem, 'PPIx::Regexp::Node' ) or next;
	defined $rslt or next;
	$rslt = $elem->find( $want )
	    and push @found, @{ $rslt };
    }

    return @found ? \@found : 0;

}

#line 206

sub find_parents {
    my ( $self, $want ) = @_;

    my $found;
    $found = $self->find( $want ) or return $found;

    my %parents;
    my @rslt;
    foreach my $elem ( @{ $found } ) {
	my $dad = $elem->parent() or next;
	$parents{ refaddr( $dad ) }++
	    or push @rslt, $dad;
    }

    return \@rslt;
}

#line 231

sub find_first {
    my ( $self, $want ) = @_;

    $want = _find_routine( $want ) or return;

    # We use a recursion to find what we want. PPI::Node uses an
    # iteration.
    foreach my $elem ( $self->elements() ) {
	my $rslt = eval { $want->( $self, $elem ) }
	    and return $elem;
	$@ and return;

	__instance( $elem, 'PPIx::Regexp::Node' ) or next;
	defined $rslt or next;

	defined( $rslt = $elem->find_first( $want ) )
	    or return;
	$rslt and return $rslt;
    }

    return 0;

}

#line 261

sub first_element {
    my ( $self ) = @_;
    return $self->{children}[0];
}

#line 272

sub last_element {
    my ( $self ) = @_;
    return $self->{children}[-1];
}

#line 287

sub perl_version_introduced {
    my ( $self ) = @_;
    return max( MINIMUM_PERL,
	map { $_->perl_version_introduced() } $self->elements() );
}

#line 303

sub perl_version_removed {
    my ( $self ) = @_;
    my $max;
    foreach my $elem ( $self->elements() ) {
	if ( defined ( my $ver = $elem->perl_version_removed() ) ) {
	    if ( defined $max ) {
		$ver < $max and $max = $ver;
	    } else {
		$max = $ver;
	    }
	}
    }
    return $max;
}

#line 327

sub schild {
    my ( $self, $inx ) = @_;
    defined $inx or $inx = 0;

    my $kids = $self->{children};

    if ( $inx >= 0 ) {

	my $loc = 0;

	while ( exists $kids->[$loc] ) {
	    $kids->[$loc]->significant() or next;
	    --$inx >= 0 and next;
	    return $kids->[$loc];
	} continue {
	    $loc++;
	}

    } else {

	my $loc = -1;
	
	while ( exists $kids->[$loc] ) {
	    $kids->[$loc]->significant() or next;
	    $inx++ < -1 and next;
	    return $kids->[$loc];
	} continue {
	    --$loc;
	}

    }

    return;
}

#line 368

sub schildren {
    my ( $self ) = @_;
    if ( wantarray ) {
	return ( grep { $_->significant() } @{ $self->{children} } );
    } elsif ( defined wantarray ) {
	my $kids = 0;
	foreach ( @{ $self->{children} } ) {
	    $_->significant() and $kids++;
	}
	return $kids;
    } else {
	return;
    }
}

sub tokens {
    my ( $self ) = @_;
    return ( map { $_->tokens() } $self->elements() );
}

# Help for nav();
sub _nav {
    my ( $self, $child ) = @_;
    refaddr( $child->parent() ) == refaddr( $self )
	or return;
    my ( $method, $inx ) = $child->_my_inx()
	or return;

    return ( $method => [ $inx ] );
}

# Called by the lexer once it has done its worst to all the tokens.
# Called as a method with no arguments. The return is the number of
# parse failures discovered when finalizing.
sub __PPIX_LEXER__finalize {
    my ( $self ) = @_;
    my $rslt = 0;
    foreach my $elem ( $self->elements() ) {
	$rslt += $elem->__PPIX_LEXER__finalize();
    }
    return $rslt;
}

# Called by the lexer to record the capture number.
sub __PPIX_LEXER__record_capture_number {
    my ( $self, $number ) = @_;
    foreach my $kid ( $self->children() ) {
	$number = $kid->__PPIX_LEXER__record_capture_number( $number );
    }
    return $number;
}

1;

__END__

#line 447

# ex: set textwidth=72 :
