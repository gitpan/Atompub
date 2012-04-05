#line 1
#line 29

package PPIx::Regexp::Element;

use strict;
use warnings;

use 5.006;

use List::MoreUtils qw{ firstidx };
use PPIx::Regexp::Util qw{ __instance };
use Scalar::Util qw{ refaddr weaken };

use PPIx::Regexp::Constant qw{ MINIMUM_PERL };

our $VERSION = '0.026';

#line 52

sub ancestor_of {
    my ( $self, $elem ) = @_;
    __instance( $elem, __PACKAGE__ ) or return;
    my $addr = refaddr( $self );
    while ( $addr != refaddr( $elem ) ) {
	$elem = $elem->_parent() or return;
    }
    return 1;
}

#line 71

sub can_be_quantified { return 1; }


#line 81

sub class {
    my ( $self ) = @_;
    return ref $self;
}

#line 93

sub comment {
    return;
}

#line 103

sub content {
    return;
}

#line 115

sub descendant_of {
    my ( $self, $node ) = @_;
    __instance( $node, __PACKAGE__ ) or return;
    return $node->ancestor_of( $self );
}


#line 134

sub is_quantifier { return; }

#line 143

sub next_sibling {
    my ( $self ) = @_;
    my ( $method, $inx ) = $self->_my_inx()
	or return;
    return $self->_parent()->$method( $inx + 1 );
}

#line 157

sub parent {
    my ( $self ) = @_;
    return $self->_parent();
}

#line 180

sub perl_version_introduced {
    return MINIMUM_PERL;
}

#line 196

sub perl_version_removed {
    return undef;	## no critic (ProhibitExplicitReturnUndef)
}

#line 207

sub previous_sibling {
    my ( $self ) = @_;
    my ( $method, $inx ) = $self->_my_inx()
	or return;
    $inx or return;
    return $self->_parent()->$method( $inx - 1 );
}

#line 222

sub significant {
    return 1;
}

#line 233

sub snext_sibling {
    my ( $self ) = @_;
    my $sib = $self;
    while ( defined ( $sib = $sib->next_sibling() ) ) {
	$sib->significant() and return $sib;
    }
    return;
}

#line 249

sub sprevious_sibling {
    my ( $self ) = @_;
    my $sib = $self;
    while ( defined ( $sib = $sib->previous_sibling() ) ) {
	$sib->significant() and return $sib;
    }
    return;
}

#line 264

sub tokens {
    my ( $self ) = @_;
    return $self;
}

#line 275

sub top {
    my ( $self ) = @_;
    my $kid = $self;
    while ( defined ( my $parent = $kid->_parent() ) ) {
	$kid = $parent;
    }
    return $kid;
}

#line 291

sub whitespace {
    return;
}

#line 314

sub nav {
    my ( $self ) = @_;
    __instance( $self, __PACKAGE__ ) or return;

    # We do not use $self->parent() here because PPIx::Regexp overrides
    # this to return the (possibly) PPI object that initiated us.
    my $parent = $self->_parent() or return;

    return ( $parent->nav(), $parent->_nav( $self ) );
}

# Find our location and index among the parent's children. If not found,
# just returns.

{
    my %method_map = (
	children => 'child',
    );
    sub _my_inx {
	my ( $self ) = @_;
	my $parent = $self->_parent() or return;
	my $addr = refaddr( $self );
	foreach my $method ( qw{ children start type finish } ) {
	    $parent->can( $method ) or next;
	    my $inx = firstidx { refaddr $_ == $addr } $parent->$method();
	    $inx < 0 and next;
	    return ( $method_map{$method} || $method, $inx );
	}
	return;
    }
}

{
    my %parent;

    # no-argument form returns the parent; one-argument sets it.
    sub _parent {
	my ( $self, @arg ) = @_;
	my $addr = refaddr( $self );
	if ( @arg ) {
	    my $parent = shift @arg;
	    if ( defined $parent ) {
		__instance( $parent, __PACKAGE__ ) or return;
		weaken(
		    $parent{$addr} = $parent );
	    } else {
		delete $parent{$addr};
	    }
	}
	return $parent{$addr};
    }

    sub _parent_keys {
	return scalar keys %parent;
    }

}

# Called by the lexer to record the capture number.
sub __PPIX_LEXER__record_capture_number {
    my ( $self, $number ) = @_;
    return $number;
}

sub DESTROY {
    $_[0]->_parent( undef );
    return;
}

1;

__END__

#line 410

# ex: set textwidth=72 :
