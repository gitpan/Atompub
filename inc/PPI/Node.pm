#line 1
package PPI::Node;

#line 49

use strict;
use Carp            ();
use Scalar::Util    qw{refaddr};
use List::MoreUtils ();
use Params::Util    qw{_INSTANCE _CLASS _CODELIKE};
use PPI::Element    ();

use vars qw{$VERSION @ISA *_PARENT};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Element';
	*_PARENT = *PPI::Element::_PARENT;
}





#####################################################################
# The basic constructor

sub new {
	my $class = ref $_[0] || $_[0];
	bless { children => [] }, $class;
}





#####################################################################
# PDOM Methods

#line 91

### XS -> PPI/XS.xs:_PPI_Node__scope 0.903+
sub scope { '' }

#line 108

sub add_element {
	my $self = shift;

	# Check the element
	my $Element = _INSTANCE(shift, 'PPI::Element') or return undef;
	$_PARENT{refaddr $Element} and return undef;

	# Add the argument to the elements
	push @{$self->{children}}, $Element;
	Scalar::Util::weaken(
		$_PARENT{refaddr $Element} = $self
	);

	1;
}

# In a typical run profile, add_element is the number 1 resource drain.
# This is a highly optimised unsafe version, for internal use only.
sub __add_element {
	Scalar::Util::weaken(
		$_PARENT{refaddr $_[1]} = $_[0]
	);
	push @{$_[0]->{children}}, $_[1];
}

#line 149

sub elements {
	if ( wantarray ) {
		return @{$_[0]->{children}};
	} else {
		return scalar @{$_[0]->{children}};
	}
}

#line 170

# Normally the first element is also the first child
sub first_element {
	$_[0]->{children}->[0];
}

#line 188

# Normally the last element is also the last child
sub last_element {
	$_[0]->{children}->[-1];
}

#line 209

# In the default case, this is the same as for the elements method
sub children {
	wantarray ? @{$_[0]->{children}} : scalar @{$_[0]->{children}};
}

#line 226

sub schildren {
	return grep { $_->significant } @{$_[0]->{children}} if wantarray;
	my $count = 0;
	foreach ( @{$_[0]->{children}} ) {
		$count++ if $_->significant;
	}
	return $count;
}

#line 247

sub child {
	$_[0]->{children}->[$_[1]];
}

#line 268

sub schild {
	my $self = shift;
	my $idx  = 0 + shift;
	my $el   = $self->{children};
	if ( $idx < 0 ) {
		my $cursor = 0;
		while ( exists $el->[--$cursor] ) {
			return $el->[$cursor] if $el->[$cursor]->significant and ++$idx >= 0;
		}
	} else {
		my $cursor = -1;
		while ( exists $el->[++$cursor] ) {
			return $el->[$cursor] if $el->[$cursor]->significant and --$idx < 0;
		}
	}
	undef;
}

#line 301

sub contains {
	my $self    = shift;
	my $Element = _INSTANCE(shift, 'PPI::Element') or return undef;

	# Iterate up the Element's parent chain until we either run out
	# of parents, or get to ourself.
	while ( $Element = $Element->parent ) {
		return 1 if refaddr($self) == refaddr($Element);
	}

	'';
}

#line 369

sub find {
	my $self   = shift;
	my $wanted = $self->_wanted(shift) or return undef;

	# Use a queue based search, rather than a recursive one
	my @found = ();
	my @queue = @{$self->{children}};
	eval {
		while ( @queue ) {
			my $Element = shift @queue;
			my $rv      = &$wanted( $self, $Element );
			push @found, $Element if $rv;

			# Support "don't descend on undef return"
			next unless defined $rv;

			# Skip if the Element doesn't have any children
			next unless $Element->isa('PPI::Node');

			# Depth-first keeps the queue size down and provides a
			# better logical order.
			if ( $Element->isa('PPI::Structure') ) {
				unshift @queue, $Element->finish if $Element->finish;
				unshift @queue, @{$Element->{children}};
				unshift @queue, $Element->start if $Element->start;
			} else {
				unshift @queue, @{$Element->{children}};
			}
		}
	};
	if ( $@ ) {
		# Caught exception thrown from the wanted function
		return undef;
	}

	@found ? \@found : '';
}

#line 426

sub find_first {
	my $self   = shift;
	my $wanted = $self->_wanted(shift) or return undef;

	# Use the same queue-based search as for ->find
	my @queue = @{$self->{children}};
	my $rv    = eval {
		# The defined() here prevents a ton of calls to PPI::Util::TRUE
		while ( @queue ) {
			my $Element = shift @queue;
			my $rv      = &$wanted( $self, $Element );
			return $Element if $rv;

			# Support "don't descend on undef return"
			next unless defined $rv;

			# Skip if the Element doesn't have any children
			next unless $Element->isa('PPI::Node');

			# Depth-first keeps the queue size down and provides a
			# better logical order.
			if ( $Element->isa('PPI::Structure') ) {
				unshift @queue, $Element->finish if defined($Element->finish);
				unshift @queue, @{$Element->{children}};
				unshift @queue, $Element->start  if defined($Element->start);
			} else {
				unshift @queue, @{$Element->{children}};
			}
		}
	};
	if ( $@ ) {
		# Caught exception thrown from the wanted function
		return undef;
	}

	$rv or '';
}

#line 479

sub find_any {
	my $self = shift;
	my $rv   = $self->find_first(@_);
	$rv ? 1 : $rv; # false or undef
}

#line 498

sub remove_child {
	my $self  = shift;
	my $child = _INSTANCE(shift, 'PPI::Element') or return undef;

	# Find the position of the child
	my $key = refaddr $child;
	my $p   = List::MoreUtils::firstidx {
		refaddr $_ == $key
	} @{$self->{children}};
	return undef unless defined $p;

	# Splice it out, and remove the child's parent entry
	splice( @{$self->{children}}, $p, 1 );
	delete $_PARENT{refaddr $child};

	$child;
}

#line 561

sub prune {
	my $self   = shift;
	my $wanted = $self->_wanted(shift) or return undef;

	# Use a depth-first queue search
	my $pruned = 0;
	my @queue  = $self->children;
	eval {
		while ( my $element = shift @queue ) {
			my $rv = &$wanted( $self, $element );
			if ( $rv ) {
				# Delete the child
				$element->delete or return undef;
				$pruned++;
				next;
			}

			# Support the undef == "don't descend"
			next unless defined $rv;

			if ( _INSTANCE($element, 'PPI::Node') ) {
				# Depth-first keeps the queue size down
				unshift @queue, $element->children;
			}
		}
	};
	if ( $@ ) {
		# Caught exception thrown from the wanted function
		return undef;		
	}

	$pruned;
}

# This method is likely to be very heavily used, to take
# it slowly and carefuly.
### NOTE: Renaming this function or changing either to self will probably
###       break File::Find::Rule::PPI
sub _wanted {
	my $either = shift;
	my $it     = defined($_[0]) ? shift : do {
		Carp::carp('Undefined value passed as search condition') if $^W;
		return undef;
	};

	# Has the caller provided a wanted function directly
	return $it if _CODELIKE($it);
	if ( ref $it ) {
		# No other ref types are supported
		Carp::carp('Illegal non-CODE reference passed as search condition') if $^W;
		return undef;
	}

	# The first argument should be an Element class, possibly in shorthand
	$it = "PPI::$it" unless substr($it, 0, 5) eq 'PPI::';
	unless ( _CLASS($it) and $it->isa('PPI::Element') ) {
		# We got something, but it isn't an element
		Carp::carp("Cannot create search condition for '$it': Not a PPI::Element") if $^W;
		return undef;
	}

	# Create the class part of the wanted function
	my $wanted_class = "\n\treturn '' unless \$_[1]->isa('$it');";

	# Have we been given a second argument to check the content
	my $wanted_content = '';
	if ( defined $_[0] ) {
		my $content = shift;
		if ( ref $content eq 'Regexp' ) {
			$content = "$content";
		} elsif ( ref $content ) {
			# No other ref types are supported
			Carp::carp("Cannot create search condition for '$it': Not a PPI::Element") if $^W;
			return undef;
		} else {
			$content = quotemeta $content;
		}

		# Complete the content part of the wanted function
		$wanted_content .= "\n\treturn '' unless defined \$_[1]->{content};";
		$wanted_content .= "\n\treturn '' unless \$_[1]->{content} =~ /$content/;";
	}

	# Create the complete wanted function
	my $code = "sub {"
		. $wanted_class
		. $wanted_content
		. "\n\t1;"
		. "\n}";

	# Compile the wanted function
	$code = eval $code;
	(ref $code eq 'CODE') ? $code : undef;
}





####################################################################
# PPI::Element overloaded methods

sub tokens {
	map { $_->tokens } @{$_[0]->{children}};
}

### XS -> PPI/XS.xs:_PPI_Element__content 0.900+
sub content {
	join '', map { $_->content } @{$_[0]->{children}};
}

# Clone as normal, but then go down and relink all the _PARENT entries
sub clone {
	my $self  = shift;
	my $clone = $self->SUPER::clone;
	$clone->__link_children;
	$clone;
}

sub location {
	my $self  = shift;
	my $first = $self->{children}->[0] or return undef;
	$first->location;
}





#####################################################################
# Internal Methods

sub DESTROY {
	local $_;
	if ( $_[0]->{children} ) {
		my @queue = $_[0];
		while ( defined($_ = shift @queue) ) {
			unshift @queue, @{delete $_->{children}} if $_->{children};

			# Remove all internal/private weird crosslinking so that
			# the cascading DESTROY calls will get called properly.
			%$_ = ();
		}
	}

	# Remove us from our parent node as normal
	delete $_PARENT{refaddr $_[0]};
}

# Find the position of a child
sub __position {
	my $key = refaddr $_[1];
	List::MoreUtils::firstidx { refaddr $_ == $key } @{$_[0]->{children}};
}

# Insert one or more elements before a child
sub __insert_before_child {
	my $self = shift;
	my $key  = refaddr shift;
	my $p    = List::MoreUtils::firstidx {
	         refaddr $_ == $key
	         } @{$self->{children}};
	foreach ( @_ ) {
		Scalar::Util::weaken(
			$_PARENT{refaddr $_} = $self
			);
	}
	splice( @{$self->{children}}, $p, 0, @_ );
	1;
}

# Insert one or more elements after a child
sub __insert_after_child {
	my $self = shift;
	my $key  = refaddr shift;
	my $p    = List::MoreUtils::firstidx {
	         refaddr $_ == $key
	         } @{$self->{children}};
	foreach ( @_ ) {
		Scalar::Util::weaken(
			$_PARENT{refaddr $_} = $self
			);
	}
	splice( @{$self->{children}}, $p + 1, 0, @_ );
	1;
}

# Replace a child
sub __replace_child {
	my $self = shift;
	my $key  = refaddr shift;
	my $p    = List::MoreUtils::firstidx {
	         refaddr $_ == $key
	         } @{$self->{children}};
	foreach ( @_ ) {
		Scalar::Util::weaken(
			$_PARENT{refaddr $_} = $self
			);
	}
	splice( @{$self->{children}}, $p, 1, @_ );
	1;
}

# Create PARENT links for an entire tree.
# Used when cloning or thawing.
sub __link_children {
	my $self = shift;

	# Relink all our children ( depth first )
	my @queue = ( $self );
	while ( my $Node = shift @queue ) {
		# Link our immediate children
		foreach my $Element ( @{$Node->{children}} ) {
			Scalar::Util::weaken(
				$_PARENT{refaddr($Element)} = $Node
				);
			unshift @queue, $Element if $Element->isa('PPI::Node');
		}

		# If it's a structure, relink the open/close braces
		next unless $Node->isa('PPI::Structure');
		Scalar::Util::weaken(
			$_PARENT{refaddr($Node->start)}  = $Node
			) if $Node->start;
		Scalar::Util::weaken(
			$_PARENT{refaddr($Node->finish)} = $Node
			) if $Node->finish;
	}

	1;
}

1;

#line 821
