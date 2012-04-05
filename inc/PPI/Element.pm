#line 1
package PPI::Element;

#line 22

use strict;
use Clone           ();
use Scalar::Util    qw{refaddr};
use Params::Util    qw{_INSTANCE _ARRAY};
use List::MoreUtils ();
use PPI::Util       ();
use PPI::Node       ();

use vars qw{$VERSION $errstr %_PARENT};
BEGIN {
	$VERSION = '1.215';
	$errstr  = '';

	# Master Child -> Parent index
	%_PARENT = ();
}

use overload 'bool' => \&PPI::Util::TRUE;
use overload '""'   => 'content';
use overload '=='   => '__equals';
use overload '!='   => '__nequals';
use overload 'eq'   => '__eq';
use overload 'ne'   => '__ne';





#####################################################################
# General Properties

#line 67

### XS -> PPI/XS.xs:_PPI_Element__significant 0.845+
sub significant { 1 }

#line 83

sub class { ref($_[0]) }

#line 98

sub tokens { $_[0] }

#line 122

### XS -> PPI/XS.xs:_PPI_Element__content 0.900+
sub content { '' }





#####################################################################
# Naigation Methods

#line 145

sub parent { $_PARENT{refaddr $_[0]} }

#line 196

sub descendant_of {
	my $cursor = shift;
	my $parent = shift or return undef;
	while ( refaddr $cursor != refaddr $parent ) {
		$cursor = $_PARENT{refaddr $cursor} or return '';
	}
	return 1;
}

#line 254

sub ancestor_of {
	my $self   = shift;
	my $cursor = shift or return undef;
	while ( refaddr $cursor != refaddr $self ) {
		$cursor = $_PARENT{refaddr $cursor} or return '';
	}
	return 1;
}

#line 279

sub statement {
	my $cursor = shift;
	while ( ! _INSTANCE($cursor, 'PPI::Statement') ) {
		$cursor = $_PARENT{refaddr $cursor} or return '';
	}
	$cursor;
}

#line 302

sub top {
	my $cursor = shift;
	while ( my $parent = $_PARENT{refaddr $cursor} ) {
		$cursor = $parent;
	}
	$cursor;
}

#line 322

sub document {
	my $top = shift->top;
	_INSTANCE($top, 'PPI::Document') and $top;
}

#line 337

sub next_sibling {
	my $self     = shift;
	my $parent   = $_PARENT{refaddr $self} or return '';
	my $key      = refaddr $self;
	my $elements = $parent->{children};
	my $position = List::MoreUtils::firstidx {
		refaddr $_ == $key
		} @$elements;
	$elements->[$position + 1] || '';
}

#line 360

sub snext_sibling {
	my $self     = shift;
	my $parent   = $_PARENT{refaddr $self} or return '';
	my $key      = refaddr $self;
	my $elements = $parent->{children};
	my $position = List::MoreUtils::firstidx {
		refaddr $_ == $key
		} @$elements;
	while ( defined(my $it = $elements->[++$position]) ) {
		return $it if $it->significant;
	}
	'';
}

#line 385

sub previous_sibling {
	my $self     = shift;
	my $parent   = $_PARENT{refaddr $self} or return '';
	my $key      = refaddr $self;
	my $elements = $parent->{children};
	my $position = List::MoreUtils::firstidx {
		refaddr $_ == $key
		} @$elements;
	$position and $elements->[$position - 1] or '';
}

#line 408

sub sprevious_sibling {
	my $self     = shift;
	my $parent   = $_PARENT{refaddr $self} or return '';
	my $key      = refaddr $self;
	my $elements = $parent->{children};
	my $position = List::MoreUtils::firstidx {
		refaddr $_ == $key
		} @$elements;
	while ( $position-- and defined(my $it = $elements->[$position]) ) {
		return $it if $it->significant;
	}
	'';
}

#line 440

sub first_token {
	my $cursor = shift;
	while ( $cursor->isa('PPI::Node') ) {
		$cursor = $cursor->first_element
		or die "Found empty PPI::Node while getting first token";
	}
	$cursor;
}


#line 468

sub last_token {
	my $cursor = shift;
	while ( $cursor->isa('PPI::Node') ) {
		$cursor = $cursor->last_element
		or die "Found empty PPI::Node while getting first token";
	}
	$cursor;
}

#line 497

sub next_token {
	my $cursor = shift;

	# Find the next element, going upwards as needed
	while ( 1 ) {
		my $element = $cursor->next_sibling;
		if ( $element ) {
			return $element if $element->isa('PPI::Token');
			return $element->first_token;
		}
		$cursor = $cursor->parent or return '';
		if ( $cursor->isa('PPI::Structure') and $cursor->finish ) {
			return $cursor->finish;
		}
	}
}

#line 533

sub previous_token {
	my $cursor = shift;

	# Find the previous element, going upwards as needed
	while ( 1 ) {
		my $element = $cursor->previous_sibling;
		if ( $element ) {
			return $element if $element->isa('PPI::Token');
			return $element->last_token;
		}
		$cursor = $cursor->parent or return '';
		if ( $cursor->isa('PPI::Structure') and $cursor->start ) {
			return $cursor->start;
		}
	}
}





#####################################################################
# Manipulation

#line 568

sub clone {
	Clone::clone(shift);
}

#line 625

sub __insert_before {
	my $self = shift;
	$self->parent->__insert_before_child( $self, @_ );
}

#line 682

sub __insert_after {
	my $self = shift;
	$self->parent->__insert_after_child( $self, @_ );
}

#line 699

sub remove {
	my $self   = shift;
	my $parent = $self->parent or return $self;
	$parent->remove_child( $self );
}

#line 718

sub delete {
	$_[0]->remove or return undef;
	$_[0]->DESTROY;
	1;
}

#line 738

sub replace {
	my $self    = ref $_[0] ? shift : return undef;
	my $Element = _INSTANCE(shift, ref $self) or return undef;
	die "The ->replace method has not yet been implemented";
}

#line 771

sub location {
	my $self = shift;

	$self->_ensure_location_present or return undef;

	# Return a copy, not the original
	return [ @{$self->{_location}} ];
}

#line 809

sub line_number {
	my $self = shift;

	my $location = $self->location() or return undef;
	return $location->[0];
}

#line 845

sub column_number {
	my $self = shift;

	my $location = $self->location() or return undef;
	return $location->[1];
}

#line 888

sub visual_column_number {
	my $self = shift;

	my $location = $self->location() or return undef;
	return $location->[2];
}

#line 927

sub logical_line_number {
	my $self = shift;

	return $self->location()->[3];
}

#line 969

sub logical_filename {
	my $self = shift;

	my $location = $self->location() or return undef;
	return $location->[4];
}

sub _ensure_location_present {
	my $self = shift;

	unless ( exists $self->{_location} ) {
		# Are we inside a normal document?
		my $Document = $self->document or return undef;
		if ( $Document->isa('PPI::Document::Fragment') ) {
			# Because they can't be serialized, document fragments
			# do not support the concept of location.
			return undef;
		}

		# Generate the locations. If they need one location, then
		# the chances are they'll want more, and it's better that
		# everything is already pre-generated.
		$Document->index_locations or return undef;
		unless ( exists $self->{_location} ) {
			# erm... something went very wrong here
			return undef;
		}
	}

	return 1;
}

# Although flush_locations is only publically a Document-level method,
# we are able to implement it at an Element level, allowing us to
# selectively flush only the part of the document that occurs after the
# element for which the flush is called.
sub _flush_locations {
	my $self  = shift;
	unless ( $self == $self->top ) {
		return $self->top->_flush_locations( $self );
	}

	# Get the full list of all Tokens
	my @Tokens = $self->tokens;

	# Optionally allow starting from an arbitrary element (or rather,
	# the first Token equal-to-or-within an arbitrary element)
	if ( _INSTANCE($_[0], 'PPI::Element') ) {
		my $start = shift->first_token;
		while ( my $Token = shift @Tokens ) {
			return 1 unless $Token->{_location};
			next unless refaddr($Token) == refaddr($start);

			# Found the start. Flush it's location
			delete $$Token->{_location};
			last;
		}
	}

	# Iterate over any remaining Tokens and flush their location
	foreach my $Token ( @Tokens ) {
		delete $Token->{_location};
	}

	1;
}





#####################################################################
# XML Compatibility Methods

sub _xml_name {
	my $class = ref $_[0] || $_[0];
	my $name  = lc join( '_', split /::/, $class );
	substr($name, 4);
}

sub _xml_attr {
	return {};
}

sub _xml_content {
	defined $_[0]->{content} ? $_[0]->{content} : '';
}





#####################################################################
# Internals

# Set the error string
sub _error {
	$errstr = $_[1];
	undef;
}

# Clear the error string
sub _clear {
	$errstr = '';
	$_[0];
}

# Being DESTROYed in this manner, rather than by an explicit
# ->delete means our reference count has probably fallen to zero.
# Therefore we don't need to remove ourselves from our parent,
# just the index ( just in case ).
### XS -> PPI/XS.xs:_PPI_Element__DESTROY 0.900+
sub DESTROY { delete $_PARENT{refaddr $_[0]} }

# Operator overloads
sub __equals  { ref $_[1] and refaddr($_[0]) == refaddr($_[1]) }
sub __nequals { !__equals(@_) }
sub __eq {
	my $self  = _INSTANCE($_[0], 'PPI::Element') ? $_[0]->content : $_[0];
	my $other = _INSTANCE($_[1], 'PPI::Element') ? $_[1]->content : $_[1];
	$self eq $other;
}
sub __ne { !__eq(@_) }

1;

#line 1126
