#line 1
package PPI::Document::Normalized;

#line 39

# For convenience (and since this isn't really a public class), import
# the methods we will need from Scalar::Util.
use strict;
use Scalar::Util qw{refaddr reftype blessed};
use Params::Util qw{_INSTANCE _ARRAY};
use PPI::Util    ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.215';
}

use overload 'bool' => \&PPI::Util::TRUE;
use overload '=='   => 'equal';






#####################################################################
# Constructor and Accessors

#line 73

sub new {
	my $class = shift;
	my %args  = @_;

	# Check the required params
	my $Document  = _INSTANCE($args{Document}, 'PPI::Document') or return undef;
	my $version   = $args{version} or return undef;
	my $functions = _ARRAY($args{functions}) or return undef;

	# Create the object
	my $self = bless {
		Document  => $Document,
		version   => $version,
		functions => $functions,
		}, $class;

	$self;
}

sub _Document { $_[0]->{Document}  }

#line 103

sub version   { $_[0]->{version}   }

#line 115

sub functions { $_[0]->{functions} }





#####################################################################
# Comparison Methods

#line 146

sub equal {
	my $self  = shift;
	my $other = _INSTANCE(shift, 'PPI::Document::Normalized') or return undef;

	# Prevent multiple concurrent runs
	return undef if $self->{processing};

	# Check the version and function list first
	return '' unless $self->version eq $other->version;
	$self->_equal_ARRAY( $self->functions, $other->functions ) or return '';

	# Do the main comparison run
	$self->{seen} = {};
	my $rv = $self->_equal_blessed( $self->_Document, $other->_Document );
	delete $self->{seen};

	$rv;
}

# Check that two objects are matched
sub _equal_blessed {
	my ($self, $this, $that) = @_;
	my ($bthis, $bthat) = (blessed $this, blessed $that);
	$bthis and $bthat and $bthis eq $bthat or return '';

	# Check the object as a reference
	$self->_equal_reference( $this, $that );
}

# Check that two references match their types
sub _equal_reference {
	my ($self, $this, $that) = @_;
	my ($rthis, $rthat) = (refaddr $this, refaddr $that);
	$rthis and $rthat or return undef;

	# If we have seen this before, are the pointing
	# is it the same one we saw in both sides
	my $seen = $self->{seen}->{$rthis};
	if ( $seen and $seen ne $rthat ) {
		return '';
	}

	# Check the reference types
	my ($tthis, $tthat) = (reftype $this, reftype $that);
	$tthis and $tthat and $tthis eq $tthat or return undef;

	# Check the children of the reference type
	$self->{seen}->{$rthis} = $rthat;
	my $method = "_equal_$tthat";
	my $rv = $self->$method( $this, $that );
	delete $self->{seen}->{$rthis};
	$rv;
}

# Compare the children of two SCALAR references
sub _equal_SCALAR {
	my ($self, $this, $that) = @_;
	my ($cthis, $cthat) = ($$this, $$that);
	return $self->_equal_blessed( $cthis, $cthat )   if blessed $cthis;
	return $self->_equal_reference( $cthis, $cthat ) if ref $cthis;
	return (defined $cthat and $cthis eq $cthat)     if defined $cthis;
	! defined $cthat;
}

# For completeness sake, lets just treat REF as a specialist SCALAR case
sub _equal_REF { shift->_equal_SCALAR(@_) }

# Compare the children of two ARRAY references
sub _equal_ARRAY {
	my ($self, $this, $that) = @_;

	# Compare the number of elements
	scalar(@$this) == scalar(@$that) or return '';

	# Check each element in the array.
	# Descend depth-first.
	foreach my $i ( 0 .. scalar(@$this) ) {
		my ($cthis, $cthat) = ($this->[$i], $that->[$i]);
		if ( blessed $cthis ) {
			return '' unless $self->_equal_blessed( $cthis, $cthat );
		} elsif ( ref $cthis ) {
			return '' unless $self->_equal_reference( $cthis, $cthat );
		} elsif ( defined $cthis ) {
			return '' unless (defined $cthat and $cthis eq $cthat);
		} else {
			return '' if defined $cthat;
		}
	}

	1;
}

# Compare the children of a HASH reference
sub _equal_HASH {
	my ($self, $this, $that) = @_;

	# Compare the number of keys
	return '' unless scalar(keys %$this) == scalar(keys %$that);

	# Compare each key, descending depth-first.
	foreach my $k ( keys %$this ) {
		return '' unless exists $that->{$k};
		my ($cthis, $cthat) = ($this->{$k}, $that->{$k});
		if ( blessed $cthis ) {
			return '' unless $self->_equal_blessed( $cthis, $cthat );
		} elsif ( ref $cthis ) {
			return '' unless $self->_equal_reference( $cthis, $cthat );
		} elsif ( defined $cthis ) {
			return '' unless (defined $cthat and $cthis eq $cthat);
		} else {
			return '' if defined $cthat;
		}
	}

	1;
}		

# We do not support GLOB comparisons
sub _equal_GLOB {
	my ($self, $this, $that) = @_;
	warn('GLOB comparisons are not supported');
	'';
}

# We do not support CODE comparisons
sub _equal_CODE {
	my ($self, $this, $that) = @_;
	refaddr $this == refaddr $that;
}

# We don't support IO comparisons
sub _equal_IO {
	my ($self, $this, $that) = @_;
	warn('IO comparisons are not supported');
	'';
}

sub DESTROY {
	# Take the screw up Document with us
	if ( $_[0]->{Document} ) {
		$_[0]->{Document}->DESTROY;
		delete $_[0]->{Document};
	}
}

1;

#line 315
	
